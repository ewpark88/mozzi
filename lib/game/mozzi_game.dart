import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/sim/fixed_stepper.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/camera/camera_rig.dart';
import 'package:mozzi/game/components/distance_markers.dart';
import 'package:mozzi/game/components/ground_component.dart';
import 'package:mozzi/game/components/mochi_component.dart';
import 'package:mozzi/game/components/parallax_backdrop.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 한 판을 화면에 보여주는 Flame 게임. 규칙은 전부 [FlightSimulator](domain)에 있고,
/// 여기서는 시간을 고정 스텝으로 나눠 시뮬을 돌리고 결과를 그리기만 한다. (ARCHITECTURE §4)
///
/// 월드 좌표 = 미터 (x 오른쪽, y 아래가 +, 지표면 y = 0).
class MozziGame extends FlameGame implements ParallaxSource {
  MozziGame({required this.formulas, required this._levels});

  final BalanceFormulas formulas;
  UpgradeLevels _levels;

  /// HUD 용 비행 상태. 매 프레임이 아니라 [_hudInterval] 마다 / 단계가 바뀔 때 갱신.
  final ValueNotifier<FlightState> flightState = ValueNotifier(
    FlightState.initial,
  );

  static const double _hudInterval = 0.1;

  /// 2.5D 샘플의 모찌 반지름 (가상 px). 기본 카메라 배율로 미터 환산.
  static const double _sampleRadiusPx = 38;
  static const double _sampleGrassPx = 30;
  static const double _sampleBladeSpacingPx = 46;

  late FlightSimulator _sim;
  late final FixedStepper _stepper;
  late final CameraRig _rig;
  late final MochiComponent _mochi;
  VirtualViewport _viewport = const VirtualViewport(
    screenWidth: 960,
    screenHeight: 540,
  );
  double _hudTimer = 0;

  UpgradeLevels get levels => _levels;
  VirtualViewport get viewport => _viewport;

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
    await camera.viewport.add(ForegroundGrass(this));
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
    _publish(force: true);
  }

  /// 발사 (P2: 개발용 고정 각도 발사, P3 에서 당기기 입력으로 대체).
  void launch({required double angleRad, double speedMultiplier = 1}) {
    if (_sim.state.phase != FlightPhase.ready) return;
    _sim.launch(angleRad: angleRad, speedMultiplier: speedMultiplier);
    _publish(force: true);
  }

  @override
  void update(double dt) {
    final before = _sim.state.phase;
    final steps = _stepper.advance(dt);
    for (var i = 0; i < steps; i++) {
      _sim.step();
    }
    final s = _sim.state;
    _mochi.syncFrom(s);
    _rig.update(s, _viewport, dt);
    camera.viewfinder
      ..zoom = _viewport.scale * _rig.pxPerM
      ..position = Vector2(_rig.focusX, 0);
    _hudTimer += dt;
    _publish(force: s.phase != before);
    super.update(dt);
  }

  void _publish({required bool force}) {
    if (!force && _hudTimer < _hudInterval) return;
    _hudTimer = 0;
    flightState.value = _sim.state;
  }

  @override
  void onRemove() {
    flightState.dispose();
    super.onRemove();
  }
}
