import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
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
import 'package:mozzi/game/effects/particle_effects.dart';
import 'package:mozzi/game/input/flight_gesture.dart';
import 'package:mozzi/game/input/play_input.dart';
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
  late final PlayInput _input;
  final math.Random _fxRandom = math.Random(7);
  double _clock = 0;
  bool _wasOvercharged = false;
  VirtualViewport _viewport = const VirtualViewport(
    screenWidth: 960,
    screenHeight: 540,
  );
  double _hudTimer = 0;

  UpgradeLevels get levels => _levels;

  /// 볼 부풀리기·급강하 해금 (온보딩 P8 에서 설정).
  ControlUnlocks get controlUnlocks => _input.unlocks;
  set controlUnlocks(ControlUnlocks value) => _input.unlocks = value;

  @override
  VirtualViewport get viewport => _viewport;

  @override
  LaunchController get launchController => _input.launch;

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
    _input = PlayInput(
      launchSpec: cfg.launch,
      controlSpec: cfg.controls,
      phaseOf: () => _sim.state.phase,
      onLaunch: _launchWith,
      onGesture: _applyGesture,
    );
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
    _input.reset();
    pulling.value = false;
    lastLaunch.value = null;
    _publish(force: true);
  }

  // ---- 입력 (화면 논리 px → 가상 px). 발사 전 = 당기기, 비행 중 = 조작 3종 ----

  void pointerDown(double screenX, double screenY) {
    _input.down(screenX / _viewport.scale, screenY / _viewport.scale, _clock);
    pulling.value = _input.pulling;
  }

  void pointerMove(double screenX, double screenY) =>
      _input.move(screenX / _viewport.scale, screenY / _viewport.scale, _clock);

  void pointerUp() {
    _input.up(_clock);
    pulling.value = false;
    _wasOvercharged = false;
  }

  void _launchWith(LaunchDecision decision) {
    if (_sim.state.phase != FlightPhase.ready) return;
    _sim.launch(
      angleRad: decision.angleRad,
      speedMultiplier: decision.speedMultiplier,
    );
    lastLaunch.value = decision;
    if (decision.judgement.grade == GaugeGrade.perfect) {
      _addFx(
        ParticleEffects.perfectBurst(
          _mochi.position,
          _mochi.radiusM,
          _fxRandom,
        ),
      );
    }
    unawaited(HapticFeedback.heavyImpact());
    _publish(force: true);
  }

  void _applyGesture(FlightGesture g) {
    switch (g) {
      case FlightGesture.boostTap:
        if (_sim.boostTap()) unawaited(HapticFeedback.lightImpact());
      case FlightGesture.inflateStart:
        _sim.setInflate(on: true);
      case FlightGesture.inflateEnd:
        _sim.setInflate(on: false);
      case FlightGesture.dive:
        if (_sim.dive()) unawaited(HapticFeedback.mediumImpact());
    }
    _publish(force: true);
  }

  void _addFx(Component fx) {
    final added = world.add(fx);
    if (added is Future<void>) unawaited(added);
  }

  @override
  void update(double dt) {
    _clock += dt;
    _input.tick(dt, _clock);
    final over = _input.pulling && _input.launch.isOvercharged;
    if (over && !_wasOvercharged) unawaited(HapticFeedback.selectionClick());
    _wasOvercharged = over;
    final before = _sim.state.phase;
    final steps = _stepper.advance(dt);
    for (var i = 0; i < steps; i++) {
      _sim.step();
    }
    final s = _sim.state;
    _mochi
      ..syncFrom(s)
      ..setControls(inflating: s.inflating, diving: s.diving);
    _applyPull();
    if (s.boosting && steps > 0) {
      _addFx(
        ParticleEffects.boostFlame(
          _mochi.position,
          _mochi.radiusM,
          math.atan2(-s.vyMps, s.vxMps),
          _fxRandom,
        ),
      );
    }
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
    final launch = _input.launch;
    final pullingNow = _input.pulling;
    final (px, py) = launch.pull;
    final toM = _pullFollow / _rig.pxPerM;
    _mochi.setPull(
      offsetXM: pullingNow ? px * toM : 0,
      offsetYM: pullingNow ? py * toM : 0,
      stretch: pullingNow ? launch.stretch : 0,
      trembling: pullingNow && launch.isOvercharged,
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
