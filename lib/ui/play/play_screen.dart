import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/game/mozzi_game.dart';
import 'package:mozzi/ui/play/dev_panel.dart';
import 'package:mozzi/ui/play/flight_hud.dart';
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

  /// 개발용: 비행에 영향 주는 4종(볼주머니 제외)을 같은 레벨로. Lv0 은 부스터 연료 없음 →
  /// 조작 확인용으로 최소 부스터 1 을 준다.
  UpgradeLevels _levelsFor(int lv) => UpgradeLevels.of({
    UpgradeType.launch: lv,
    UpgradeType.aero: lv,
    UpgradeType.boost: lv == 0 ? 1 : lv,
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
                      _game.flightState,
                      _game.pulling,
                      _game.lastLaunch,
                    ]),
                    builder: (context, _) {
                      final state = _game.flightState.value;
                      final last = _game.lastLaunch.value;
                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: FlightHud(
                              state: state,
                              scale: scale,
                              showInflate: true,
                              showDive: true,
                            ),
                          ),
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
