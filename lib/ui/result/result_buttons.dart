import 'package:flutter/material.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/strings.dart';

/// 결과 화면 버튼 동작. null 인 동작은 버튼을 숨긴다.
class ResultActions {
  const ResultActions({
    required this.onRetry,
    required this.onMap,
    required this.onUpgrades,
    this.onAdDouble,
    this.adMultiplier = 2,
    this.adClaimed = false,
    this.onNextStage,
  });

  final VoidCallback onRetry;
  final VoidCallback onMap;
  final VoidCallback onUpgrades;

  /// 씨앗 2배 광고 (광고를 보여줄 수 없으면 null).
  final VoidCallback? onAdDouble;
  final double adMultiplier;
  final bool adClaimed;

  /// 클리어했고 다음 스테이지가 열려 있으면.
  final VoidCallback? onNextStage;
}

/// 결과 화면 버튼 줄: 광고 2배(강조) → 다음 스테이지 / 재도전 → 업그레이드 · 월드맵.
class ResultButtons extends StatelessWidget {
  const ResultButtons({required this.actions, required this.scale, super.key});

  final ResultActions actions;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final a = actions;
    final pad = EdgeInsets.symmetric(
      horizontal: 16 * scale,
      vertical: 10 * scale,
    );
    final text = TextStyle(fontSize: 15 * scale);
    Widget filled(String label, VoidCallback? onTap, Color color) =>
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: color, padding: pad),
          child: Text(label, style: text),
        );
    Widget outlined(String label, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: pad),
      child: Text(label, style: text),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: [
        if (a.adClaimed)
          filled(Strings.adDone, null, GaugePalette.perfect)
        else if (a.onAdDouble case final onAd?)
          filled(Strings.adDouble(a.adMultiplier), onAd, GaugePalette.perfect),
        if (a.onNextStage case final next?)
          filled(Strings.nextStage, next, MochiPalette.backPatch),
        filled(Strings.retry, a.onRetry, MochiPalette.backPatch),
        outlined(Strings.upgrades, a.onUpgrades),
        outlined(Strings.worldMap, a.onMap),
      ],
    );
  }
}
