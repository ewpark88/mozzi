import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/fixed_stepper.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/camera/camera_rig.dart';
import 'package:mozzi/game/components/distance_markers.dart';
import 'package:mozzi/game/components/gauge_component.dart';
import 'package:mozzi/game/components/ground_component.dart';
import 'package:mozzi/game/components/mochi_component.dart';
import 'package:mozzi/game/components/parallax_backdrop.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 한 판을 화면에 보여주는 Flame 게임. 규칙은 전부 [FlightSimulator](domain)에 있고,
/// 여기서는 시간을 고정 스텝으로 나눠 시뮬을 돌리고 결과를 그리기만 한다. (ARCHITECTURE §4)
///
/// 월드 좌표 = 미터 (x 오른쪽, y 아래가 +, 지표면 y = 0).
class MozziGame extends FlameGame implements ParallaxSource, GaugeSource {
  MozziGame({required this.formulas, required this._levels});

  final BalanceFormulas formulas;
  UpgradeLevels _levels;

  /// HUD 용 비행 상태. 매 프레임이 아니라 [_hudInterval] 마다 / 단계가 바뀔 때 갱신.
  final ValueNotifier<FlightState> flightState = ValueNotifier(
    FlightState.initial,
  );

  /// 마지막 발사 결정 (판정 팝업용). 새 판이면 null.
  final ValueNotifier<LaunchDecision?> lastLaunch = ValueNotifier(null);

  /// 당기는 중인지 (안내 문구 숨김용).
  final ValueNotifier<bool> pulling = ValueNotifier(false);

  static const double _hudInterval = 0.1;

  /// 모찌가 당긴 벡터를 따라가는 비율 (샘플: 절반).
  static const double _pullFollow = 0.5;

  /// 2.5D 샘플의 모찌 반지름 (가상 px). 기본 카메라 배율로 미터 환산.
  static const double _sampleRadiusPx = 38;
  static const double _sampleGrassPx = 30;
  static const double _sampleBladeSpacingPx = 46;

  late FlightSimulator _sim;
  late final FixedStepper _stepper;
  late final CameraRig _rig;
  late final MochiComponent _mochi;
  late final LaunchController _launch;
  double _clock = 0;
  bool _wasOvercharged = false;
  VirtualViewport _viewport = const VirtualViewport(
    screenWidth: 960,
    screenHeight: 540,
  );
  double _hudTimer = 0;

  UpgradeLevels get levels => _levels;

  @override
  VirtualViewport get viewport => _viewport;

  @override
  LaunchController get launchController => _launch;

  @override
  double get clockSec => _clock;

  @override
  double get cameraFocusXM => _rig.focusX;

  @override
  double get cameraZoom => camera.viewfinder.zoom;

  @override
  Future<void> onLoad() async {
    final cfg = formulas.config;
    _stepper = FixedStepper(
      stepDt: FlightSimulator.fixedDt,
      timeScale: cfg.simTimeScale,
    );
    _launch = LaunchController(cfg.launch);
    _rig = CameraRig(
      basePxPerM: cfg.cameraBasePxPerM,
      timeScale: cfg.simTimeScale,
    );
    final m = 1 / cfg.cameraBasePxPerM;
    _mochi = MochiComponent(radiusM: _sampleRadiusPx * m);
    camera.viewfinder.anchor = const Anchor(
      VirtualViewport.focusXRatio,
      VirtualViewport.groundLineRatio,
    );
    camera.backdrop = ParallaxBackdrop(this);
    await camera.viewport.addAll([ForegroundGrass(this), GaugeComponent(this)]);
    await world.addAll([
      GroundComponent(
        grassDepthM: _sampleGrassPx * m,
        bladeSpacingM: _sampleBladeSpacingPx * m,
      ),
      DistanceMarkers(),
      _mochi,
    ]);
    resetRun(_levels);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      _viewport = VirtualViewport(screenWidth: size.x, screenHeight: size.y);
    }
  }

  /// 새 판 준비. [levels] 로 비행 물리를 다시 만든다.
  void resetRun(UpgradeLevels levels) {
    _levels = levels;
    _sim = FlightSimulator(FlightParams.fromLevels(formulas, levels));
    _stepper.reset();
    _rig.reset();
    _launch.cancel();
    pulling.value = false;
    lastLaunch.value = null;
    _publish(force: true);
  }

  /// 누르기 시작 (화면 논리 px). 발사 전에만 받는다. (GDD §2 당기기)
  void pullStart(double screenX, double screenY) {
    if (_sim.state.phase != FlightPhase.ready) return;
    _launch.start(screenX / _viewport.scale, screenY / _viewport.scale);
    pulling.value = true;
  }

  void pullMove(double screenX, double screenY) =>
      _launch.move(screenX / _viewport.scale, screenY / _viewport.scale);

  /// 놓기: 판정 후 발사. 너무 약하면 취소.
  void pullEnd() {
    if (_launch.phase != PullPhase.pulling) return;
    pulling.value = false;
    _wasOvercharged = false;
    final decision = _launch.release();
    if (decision == null) return;
    launchWith(decision.angleRad, decision.speedMultiplier);
    lastLaunch.value = decision;
    final perfect = decision.judgement.grade == GaugeGrade.perfect;
    if (perfect) _burst();
    unawaited(HapticFeedback.heavyImpact());
  }

  /// 발사 (당기기 결과 또는 테스트).
  void launchWith(double angleRad, double speedMultiplier) {
    if (_sim.state.phase != FlightPhase.ready) return;
    _sim.launch(angleRad: angleRad, speedMultiplier: speedMultiplier);
    _publish(force: true);
  }

  /// PERFECT 이펙트: 노랑·흰 반짝이 (GDD §2 “이펙트와 진동”).
  void _burst() {
    final rnd = math.Random(7);
    const colors = GaugePalette.perfectBurst;
    final r = _mochi.radiusM;
    final added = world.add(
      ParticleSystemComponent(
        position: _mochi.position.clone(),
        particle: Particle.generate(
          count: 18,
          lifespan: 0.6,
          generator: (i) {
            final a = rnd.nextDouble() * math.pi * 2;
            final v = r * (5 + rnd.nextDouble() * 5);
            return AcceleratedParticle(
              speed: Vector2(math.cos(a) * v, math.sin(a) * v),
              acceleration: Vector2(0, r * 8),
              child: CircleParticle(
                radius: r * 0.12,
                paint: Paint()..color = colors[i % colors.length],
              ),
            );
          },
        ),
      ),
    );
    if (added is Future<void>) unawaited(added);
  }

  @override
  void update(double dt) {
    _clock += dt;
    _launch.update(dt);
    final over = _launch.phase == PullPhase.pulling && _launch.isOvercharged;
    if (over && !_wasOvercharged) unawaited(HapticFeedback.selectionClick());
    _wasOvercharged = over;
    final before = _sim.state.phase;
    final steps = _stepper.advance(dt);
    for (var i = 0; i < steps; i++) {
      _sim.step();
    }
    final s = _sim.state;
    _mochi.syncFrom(s);
    _applyPull();
    _rig.update(s, _viewport, dt);
    camera.viewfinder
      ..zoom = _viewport.scale * _rig.pxPerM
      ..position = Vector2(_rig.focusX, 0);
    _hudTimer += dt;
    _publish(force: s.phase != before);
    super.update(dt);
  }

  /// 당기는 동안 모찌를 당긴 쪽으로 끌고 늘인다 (가상 px → m: 발사 전 배율 = 기본 배율).
  void _applyPull() {
    final pullingNow = _launch.phase == PullPhase.pulling;
    final (px, py) = _launch.pull;
    final toM = _pullFollow / _rig.pxPerM;
    _mochi.setPull(
      offsetXM: pullingNow ? px * toM : 0,
      offsetYM: pullingNow ? py * toM : 0,
      stretch: pullingNow ? _launch.stretch : 0,
      trembling: pullingNow && _launch.isOvercharged,
    );
  }

  void _publish({required bool force}) {
    if (!force && _hudTimer < _hudInterval) return;
    _hudTimer = 0;
    flightState.value = _sim.state;
  }

  @override
  void onRemove() {
    flightState.dispose();
    lastLaunch.dispose();
    pulling.dispose();
    super.onRemove();
  }
}
