import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/mozzi_game.dart';
import 'package:mozzi/ui/play/dev_panel.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/play/play_hud.dart';

/// 한 판 플레이 화면 (P2: 탭 발사 → 비행 → 정지 → 재도전).
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
  /// 개발용 기준 발사 각 45°.
  static const double _devLaunchAngle = math.pi / 4;

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

  void _launch() => _game.launch(angleRad: _devLaunchAngle);

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
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) => _launch(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: _game),
                SafeArea(
                  child: ValueListenableBuilder<FlightState>(
                    valueListenable: _game.flightState,
                    builder: (context, state, _) => Stack(
                      children: [
                        PlayHud(state: state, scale: scale, onRetry: _retry),
                        if (widget.isDev)
                          // 모찌는 화면 가로 30% 에 머무르므로 오른쪽 아래가 비어 있다
                          Positioned(
                            right: 8 * scale,
                            bottom: 8 * scale,
                            child: DevPanel(
                              state: state,
                              level: _devLevel,
                              formulaDistanceM: widget.formulas
                                  .expectedDistanceM(
                                    _game.levels,
                                  ),
                              onLevel: _setDevLevel,
                              scale: scale,
                            ),
                          ),
                      ],
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
}
