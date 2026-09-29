import 'package:flutter/material.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/app_theme.dart';
import 'package:mozzi/ui/result/result_buttons.dart';
import 'package:mozzi/ui/strings.dart';

/// 결과 화면 (GDD §2 콤보와 착지, §4 별): 거리·최고 기록 대비·씨앗·별 3개·미션,
/// 씨앗 2배 광고, 재도전·다음 스테이지·업그레이드·월드맵. 실패해도 씨앗은 받는다.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    required this.result,
    required this.missionText,
    required this.actions,
    required this.scale,
    super.key,
  });

  final RunResult result;

  /// ★★★ 미션 설명 (자유 비행이면 null).
  final String? missionText;
  final ResultActions actions;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final title = TextStyle(
      fontSize: 24 * scale,
      fontWeight: FontWeight.bold,
      fontFamily: AppFonts.title,
      color: r.bossLost ? BossPalette.lost : MochiPalette.outline,
    );
    final body = TextStyle(fontSize: 15 * scale, color: MochiPalette.outline);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 420 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GaugePalette.panel,
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(color: MochiPalette.outline, width: 2 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(14 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_headline(r), style: title, textAlign: TextAlign.center),
              if (r.stars case final stars?) ...[
                SizedBox(height: 4 * scale),
                _Stars(count: r.starCount, scale: scale),
                if (missionText != null)
                  Text(
                    '${stars.star3 ? '✓' : '·'} '
                    '${Strings.star3Mission(missionText!)}',
                    style: body,
                    textAlign: TextAlign.center,
                  ),
              ],
              SizedBox(height: 6 * scale),
              Text(
                '${Strings.distance(r.distanceM)} · ${_best(r)}',
                style: body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${Strings.seedsEarned(r.seeds)}  '
                '(${Strings.seedsBreakdown(r.distanceSeeds, r.pickupSeeds)})',
                style: body,
              ),
              if (r.comboMax > 0)
                Text(Strings.comboMax(r.comboMax), style: body),
              SizedBox(height: 10 * scale),
              ResultButtons(actions: actions, scale: scale),
            ],
          ),
        ),
      ),
    );
  }

  static String _headline(RunResult r) {
    if (r.bossLost) {
      return switch (r.stageId) {
        '1-5' => Strings.bossCaught,
        '2-5' => Strings.bossRivalWon,
        _ => Strings.bossMeterFull,
      };
    }
    return r.cleared ? Strings.cleared : Strings.notCleared;
  }

  static String _best(RunResult r) => r.isNewRecord
      ? Strings.newRecord(r.bestDeltaM)
      : Strings.toBest(-r.bestDeltaM);
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Icon(
          i < count ? Icons.star_rounded : Icons.star_outline_rounded,
          color: BossPalette.star,
          size: 34 * scale,
        ),
    ],
  );
}
