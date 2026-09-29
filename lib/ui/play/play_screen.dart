import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/mozzi_game.dart';
import 'package:mozzi/game/run_setup.dart';
import 'package:mozzi/ui/play/boss_hud.dart';
import 'package:mozzi/ui/play/dev_panel.dart';
import 'package:mozzi/ui/play/flight_hud.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/play/play_hooks.dart';
import 'package:mozzi/ui/play/play_hud.dart';
import 'package:mozzi/ui/play/stage_hud.dart';
import 'package:mozzi/ui/result/result_buttons.dart';
import 'package:mozzi/ui/result/result_panel.dart';
import 'package:mozzi/ui/strings.dart';

/// 한 판 플레이 화면: 당기기(게이지) → 발사 → 비행 → 정지 → 결과 화면 (GDD §2, §4).
///
/// 서비스는 app 레이어가 [hooks] 로 넘긴다 (ui → data 의존 금지).
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    required this.formulas,
    required this.isDev,
    required this.stage,
    required this.hooks,
    this.devStages = const [],
    super.key,
  });

  final BalanceFormulas formulas;
  final bool isDev;
  final StageSpec? stage;
  final PlayHooks hooks;

  /// 개발용 스테이지 선택 목록 (잠금 무시).
  final List<StageSpec> devStages;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final MozziGame _game;
  late StageSpec? _stage = widget.stage;

  /// 개발용 레벨 덮어쓰기 (null = 진행 상태 레벨).
  int? _devLevel;
  RunResult? _result;
  bool _adClaimed = false;

  @override
  void initState() {
    super.initState();
    _game = MozziGame(
      formulas: widget.formulas,
      setup: _setupFor(_stage),
      sound: widget.hooks.sound,
    );
    _game.hud.result.addListener(_onResult);
  }

  @override
  void dispose() {
    _game.hud.result.removeListener(_onResult);
    super.dispose();
  }

  RunSetup _setupFor(StageSpec? stage) {
    final s = widget.hooks.setupFor(stage);
    final lv = _devLevel;
    if (lv == null) return s;
    return RunSetup(
      stage: s.stage,
      levels: UpgradeLevels.all(lv),
      bossEase: s.bossEase,
      ghostM: s.ghostM,
      controls: s.controls,
    );
  }

  void _onResult() {
    final r = _game.hud.result.value;
    if (r == null || identical(r, _result)) return;
    widget.hooks.onRunEnd(r);
    setState(() {
      _result = r;
      _adClaimed = false;
    });
  }

  void _start(StageSpec? stage) {
    setState(() {
      _stage = stage;
      _result = null;
    });
    _game.resetRun(_setupFor(stage));
  }

  Future<void> _adDouble(RunResult r) async {
    final ad = widget.hooks.onAdDouble;
    if (ad == null || !await ad(r) || !mounted) return;
    setState(() => _adClaimed = true);
  }

  void _claimFree() {
    widget.hooks.onClaimFreeUpgrade?.call();
    _start(_stage);
  }

  Future<void> _upgrades() async {
    await widget.hooks.onUpgrades();
    if (mounted) _start(_stage);
  }

  ResultActions _actions(RunResult r) {
    final stage = _stage;
    final next = r.cleared && stage != null
        ? widget.hooks.nextStageOf(stage)
        : null;
    final free = widget.hooks.freeUpgrade?.call();
    return ResultActions(
      freeUpgrade: free == null
          ? null
          : Strings.freeUpgrade(Strings.upgradeName(free.configKey)),
      onFreeUpgrade: free == null ? null : _claimFree,
      adHighlight: widget.hooks.highlightAdOffer?.call() ?? false,
      onRetry: () => _start(_stage),
      onMap: widget.hooks.onMap,
      onUpgrades: () => unawaited(_upgrades()),
      onAdDouble: widget.hooks.onAdDouble == null
          ? null
          : () => unawaited(_adDouble(r)),
      adMultiplier: widget.hooks.adMultiplier,
      adClaimed: _adClaimed,
      onNextStage: next == null ? null : () => _start(next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hud = _game.hud;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = hudScaleOf(constraints.biggest);
          final result = _result;
          // 누르는 즉시 당기기 시작 (샘플 pointerdown 과 같음). 좌표는 화면 논리 px.
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) =>
                _game.pointerDown(e.localPosition.dx, e.localPosition.dy),
            onPointerMove: (e) =>
                _game.pointerMove(e.localPosition.dx, e.localPosition.dy),
            onPointerUp: (_) => _game.pointerUp(),
            onPointerCancel: (_) => _game.pointerUp(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: _game),
                SafeArea(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      hud.flightState,
                      hud.runHud,
                      hud.pulling,
                      hud.lastLaunch,
                      hud.bossHud,
                    ]),
                    builder: (context, _) => _hudLayer(scale),
                  ),
                ),
                if (result != null)
                  Center(
                    child: SingleChildScrollView(
                      child: ResultPanel(
                        result: result,
                        missionText: _stage?.star3Text,
                        actions: _actions(result),
                        scale: scale,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hudLayer(double scale) {
    final hud = _game.hud;
    final state = hud.flightState.value;
    final last = hud.lastLaunch.value;
    final controls = _game.setup.controls;
    return Stack(
      children: [
        StageHud(
          info: hud.runHud.value,
          distanceM: state.distanceM,
          scale: scale,
        ),
        BossHud(info: hud.bossHud.value, scale: scale),
        Positioned(
          left: 0,
          bottom: 0,
          child: FlightHud(
            state: state,
            scale: scale,
            showInflate: controls.inflate,
            showDive: controls.dive,
          ),
        ),
        PlayHud(
          state: state,
          pulling: hud.pulling.value,
          lastLaunch: last,
          scale: scale,
          hint: _game.setup.hint,
        ),
        if (state.phase == FlightPhase.ready)
          Positioned(
            left: 4 * scale,
            top: 4 * scale,
            child: IconButton.filledTonal(
              tooltip: Strings.worldMap,
              iconSize: 26 * scale,
              onPressed: widget.hooks.onMap,
              icon: const Icon(Icons.map_rounded),
            ),
          ),
        if (widget.isDev && _result == null)
          // 모찌는 화면 가로 30% 에 머무르므로 오른쪽 아래가 비어 있다
          Positioned(
            right: 8 * scale,
            bottom: 8 * scale,
            child: DevPanel(
              stages: widget.devStages,
              stage: _stage,
              onStage: _start,
              state: state,
              lastLaunch: last,
              level: _devLevel,
              formulaDistanceM: widget.formulas.expectedDistanceM(
                _game.setup.levels,
              ),
              onLevel: (lv) {
                _devLevel = lv;
                _start(_stage);
              },
              scale: scale,
            ),
          ),
      ],
    );
  }
}
