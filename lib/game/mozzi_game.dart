import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/services/sound_service.dart';
import 'package:mozzi/domain/sim/fixed_stepper.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/game/camera/camera_rig.dart';
import 'package:mozzi/game/components/boss_rival.dart';
import 'package:mozzi/game/components/distance_markers.dart';
import 'package:mozzi/game/components/gauge_component.dart';
import 'package:mozzi/game/components/ghost_flag.dart';
import 'package:mozzi/game/components/goal_flag.dart';
import 'package:mozzi/game/components/ground_component.dart';
import 'package:mozzi/game/components/mochi_component.dart';
import 'package:mozzi/game/components/object_layer.dart';
import 'package:mozzi/game/components/parallax_backdrop.dart';
import 'package:mozzi/game/effects/run_fx.dart';
import 'package:mozzi/game/input/flight_gesture.dart';
import 'package:mozzi/game/input/play_input.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/run_hud_bus.dart';
import 'package:mozzi/game/run_presenter.dart';
import 'package:mozzi/game/run_setup.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 한 판을 화면에 보여주는 Flame 게임. 규칙은 전부 [RunSession](domain)에 있고,
/// 여기서는 시간을 고정 스텝으로 나눠 진행하고 결과를 그리기만 한다. (ARCHITECTURE §4)
///
/// 월드 좌표 = 미터 (x 오른쪽, y 아래가 +, 지표면 y = 0).
class MozziGame extends FlameGame
    implements ParallaxSource, GaugeSource, ObjectSource, BossSource {
  MozziGame({required this.formulas, required this._setup, this.sound});

  final BalanceFormulas formulas;

  /// 효과음 (없으면 무음).
  final SoundService? sound;
  RunSetup _setup;

  /// HUD 알림 (비행 상태·스테이지·보스·판 결과).
  final RunHudBus hud = RunHudBus();

  late RunSession _session;
  late final FixedStepper _stepper;
  late final CameraRig _rig;
  late final MochiComponent _mochi;
  late final PlayInput _input;
  final GoalFlag _goal = GoalFlag();
  final GhostFlag _ghost = GhostFlag();
  late final RunPresenter _presenter;
  int _runSeed = 0;
  double _clock = 0;
  VirtualViewport _viewport = const VirtualViewport(
    screenWidth: 960,
    screenHeight: 540,
  );

  RunSetup get setup => _setup;

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
  WorldPalette get backdropPalette => WorldPalette.atDistance(
    [for (final z in formulas.config.zones) z.startM],
    _rig.focusX,
  );

  @override
  bool get lowSpec => formulas.config.renderLowSpec;

  @override
  Color get rimColor => backdropPalette.rim;

  @override
  ObjectField get objectField => _session.field;

  @override
  WorldConfig get worldConfig => formulas.config.world;

  @override
  BossRule? get boss => _session.boss;

  @override
  FlightState get runState => _session.state;

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
      phaseOf: () => _session.state.phase,
      onLaunch: _launchWith,
      onGesture: _applyGesture,
    );
    _rig = CameraRig(
      basePxPerM: cfg.cameraBasePxPerM,
      timeScale: cfg.simTimeScale,
    );
    _mochi = MochiComponent(
      radiusM: cfg.mochiRadiusM,
      pxPerM: cfg.cameraBasePxPerM,
      timeScale: cfg.simTimeScale,
    )..lowSpec = cfg.renderLowSpec;
    camera.viewfinder.anchor = const Anchor(
      VirtualViewport.focusXRatio,
      VirtualViewport.groundLineRatio,
    );
    camera.backdrop = ParallaxBackdrop(this);
    await camera.viewport.addAll([ForegroundGrass(this), GaugeComponent(this)]);
    await world.addAll([
      GroundComponent.sample(basePxPerM: cfg.cameraBasePxPerM),
      DistanceMarkers(),
      ObjectLayer(this),
      _ghost,
      _goal,
      BossRival(this),
      _mochi,
    ]);
    _presenter = RunPresenter(
      fx: RunFx(world),
      mochi: _mochi,
      world: cfg.world,
      samplePxPerMps: cfg.cameraBasePxPerM * cfg.simTimeScale,
      sound: sound,
    );
    resetRun(_setup);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      _viewport = VirtualViewport(screenWidth: size.x, screenHeight: size.y);
    }
  }

  /// 새 판 준비. 판마다 다른 배치 시드 (GDD §4 청크 시드 배치).
  void resetRun(RunSetup setup) {
    _setup = setup;
    final stage = setup.stage;
    _session = RunSession(
      formulas: formulas,
      levels: setup.levels,
      stage: stage,
      runSeed: ++_runSeed,
      bossEase: setup.bossEase,
      tutorialTrampM: setup.tutorialTrampM,
    );
    _goal
      ..goalM = stage?.targetM
      ..broken = false;
    _ghost.xM = setup.ghostM;
    _presenter.reset();
    _input
      ..reset()
      ..unlocks = setup.controls;
    _stepper.reset();
    _rig.reset();
    hud.reset();
    _publish(0, force: true);
  }

  // ---- 입력 (화면 논리 px → 가상 px). 발사 전 = 당기기, 비행 중 = 조작 3종 ----

  void pointerDown(double screenX, double screenY) {
    _input.down(screenX / _viewport.scale, screenY / _viewport.scale, _clock);
    hud.pulling.value = _input.pulling;
  }

  void pointerMove(double screenX, double screenY) =>
      _input.move(screenX / _viewport.scale, screenY / _viewport.scale, _clock);

  void pointerUp() {
    _input.up(_clock);
    hud.pulling.value = false;
  }

  void _launchWith(LaunchDecision decision) {
    if (_session.state.phase != FlightPhase.ready) return;
    _session.launch(decision);
    hud.lastLaunch.value = decision;
    _presenter.launched(decision, _mochi.position, _mochi.radiusM);
    _publish(0, force: true);
  }

  void _applyGesture(FlightGesture g) {
    switch (g) {
      case FlightGesture.boostTap:
        if (_session.boostTap()) unawaited(HapticFeedback.lightImpact());
      case FlightGesture.inflateStart:
        _session.setInflate(on: true);
      case FlightGesture.inflateEnd:
        _session.setInflate(on: false);
      case FlightGesture.dive:
        if (_session.dive()) unawaited(HapticFeedback.mediumImpact());
    }
    _publish(0, force: true);
  }

  @override
  void update(double dt) {
    _clock += dt;
    _input.tick(dt, _clock);
    final before = _session.state.phase;
    final steps = _stepper.advance(dt);
    var goalNow = false;
    for (var i = 0; i < steps; i++) {
      _presenter.hits(_session.step(), _session.stats, _mochi.radiusM);
      goalNow |= _session.goalJustCrossed;
    }
    if (goalNow) {
      _goal.broken = true;
      _presenter.fx.goal(_goal.goalM!, camera.visibleWorldRect.height);
    }
    final s = _session.state;
    _presenter
      ..frame(
        s,
        _session.stats,
        dt: dt,
        stepped: steps > 0,
        rim: backdropPalette.rim,
        newRecord: hud.result.value?.isNewRecord,
      )
      ..pull(
        _input.launch,
        pulling: _input.pulling,
        pxPerM: _rig.pxPerM,
        stillReady: s.phase == FlightPhase.ready,
      );
    _rig.update(s, _viewport, dt);
    camera.viewfinder
      ..zoom = _viewport.scale * _rig.pxPerM
      ..position = Vector2(_rig.focusX, 0);
    _publish(dt, force: s.phase != before || goalNow);
    super.update(dt);
  }

  void _publish(double dt, {required bool force}) {
    final view = camera.visibleWorldRect;
    hud.publish(
      _session,
      _setup,
      dt: dt,
      force: force,
      viewLeftM: view.left,
      viewRightM: view.right,
    );
  }

  @override
  void onRemove() {
    hud.dispose();
    super.onRemove();
  }
}
