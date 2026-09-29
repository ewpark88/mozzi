import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/run_hud_info.dart';
import 'package:mozzi/ui/strings.dart';

/// 스테이지 HUD (GDD §4): 오른쪽 위 스테이지·목표·★★★ 미션·씨앗·콤보,
/// 판이 끝나면 결과 화면(ResultPanel)이 별·보상을 보여준다.
class StageHud extends StatelessWidget {
  const StageHud({
    required this.info,
    required this.distanceM,
    required this.scale,
    super.key,
  });

  final RunHudInfo info;
  final double distanceM;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(
      fontSize: 13 * scale,
      color: MochiPalette.outline,
      fontWeight: FontWeight.bold,
    );
    final goal = info.goalM;
    return Padding(
      padding: EdgeInsets.all(8 * scale),
      child: Stack(
        children: [
          // 모찌는 화면 가로 30% 에 머물며 높이 날면 왼쪽 위로 가므로 카드는 오른쪽 위에 둔다
          Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (info.stageId != null)
                  _Card(
                    scale: scale,
                    maxWidth: 230,
                    children: [
                      Text(
                        goal == null
                            ? Strings.stageMoon(info.stageId!)
                            : Strings.stageGoal(info.stageId!, goal),
                        style: text.copyWith(fontSize: 15 * scale),
                      ),
                      if (info.missionText != null)
                        Text(
                          Strings.star3Mission(info.missionText!),
                          style: text,
                        ),
                      if (goal != null && !info.goalReached)
                        Text(
                          Strings.toGoal(math.max(0, goal - distanceM)),
                          style: text,
                        ),
                    ],
                  ),
                SizedBox(height: 4 * scale),
                _Card(
                  scale: scale,
                  maxWidth: 160,
                  children: [
                    Text(Strings.seedsPicked(info.seedsPicked), style: text),
                    if (info.combo > 1)
                      Text(
                        Strings.combo(info.combo),
                        style: text.copyWith(color: ObjectPalette.goalFlag),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.scale,
    required this.maxWidth,
    required this.children,
  });

  final double scale;
  final double maxWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth * scale),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 6 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}
