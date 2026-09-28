import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/game/mozzi_game.dart';
import 'package:mozzi/ui/play/dev_panel.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/play/play_hud.dart';

/// 한 판 플레이 화면: 당기기(게이지) → 발사 → 비행 → 정지 → 재도전 (GDD §2).
///
/// [formulas] 와 [isDev] 는 app 레이어가 Provider 에서 꺼내 넘긴다 (ui → data 의존 금지).
class PlayScreen extends StatefulWidget {
  const PlayScreen({required this.formulas, required this.isDev, super.key});

  final BalanceFormulas formulas;
  final bool isDev;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final MozziGame _game;
  int _devLevel = 0;

  @override
  void initState() {
    super.initState();
    _game = MozziGame(formulas: widget.formulas, levels: _levelsFor(0));
  }

  /// P2 에서는 부스터(P4)·볼주머니(씨앗)를 뺀 비행 레벨만 올린다.
  UpgradeLevels _levelsFor(int lv) => UpgradeLevels.of({
    UpgradeType.launch: lv,
    UpgradeType.aero: lv,
    UpgradeType.bounce: lv,
  });

  void _retry() => _game.resetRun(_game.levels);

  void _setDevLevel(int lv) {
    setState(() => _devLevel = lv);
    _game.resetRun(_levelsFor(lv));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = hudScaleOf(constraints.biggest);
          // 누르는 즉시 당기기 시작 (샘플 pointerdown 과 같음). 좌표는 화면 논리 px.
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) =>
                _game.pullStart(e.localPosition.dx, e.localPosition.dy),
            onPointerMove: (e) =>
                _game.pullMove(e.localPosition.dx, e.localPosition.dy),
            onPointerUp: (_) => _game.pullEnd(),
            onPointerCancel: (_) => _game.pullEnd(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: _game),
                SafeArea(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _game.flightState,
                      _game.pulling,
                      _game.lastLaunch,
                    ]),
                    builder: (context, _) {
                      final state = _game.flightState.value;
                      final last = _game.lastLaunch.value;
                      return Stack(
                        children: [
                          PlayHud(
                            state: state,
                            pulling: _game.pulling.value,
                            lastLaunch: last,
                            scale: scale,
                            onRetry: _retry,
                          ),
                          if (widget.isDev)
                            // 모찌는 화면 가로 30% 에 머무르므로 오른쪽 아래가 비어 있다
                            Positioned(
                              right: 8 * scale,
                              bottom: 8 * scale,
                              child: DevPanel(
                                state: state,
                                lastLaunch: last,
                                level: _devLevel,
                                formulaDistanceM: widget.formulas
                                    .expectedDistanceM(_game.levels),
                                onLevel: _setDevLevel,
                                scale: scale,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
