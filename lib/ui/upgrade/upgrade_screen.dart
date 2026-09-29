import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/economy/upgrade_service.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/strings.dart';

/// 업그레이드 화면 (GDD §5 업그레이드 5종): 레벨·효과(지금 → 다음)·비용·구매.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({
    required this.formulas,
    required this.progress,
    required this.onBuy,
    required this.onBack,
    super.key,
  });

  final BalanceFormulas formulas;
  final PlayerProgress progress;
  final ValueChanged<UpgradeType> onBuy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final service = UpgradeService(formulas);
    return Scaffold(
      backgroundColor: BackyardPalette.skyBottom,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = hudScaleOf(constraints.biggest);
          final text = TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: MochiPalette.outline,
          );
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Column(
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(Strings.back, style: text),
                      ),
                      const Spacer(),
                      Text(Strings.upgrades, style: text),
                      const Spacer(),
                      Text(
                        Strings.seedsWallet(progress.wallet.seeds),
                        style: text,
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final t in UpgradeType.values)
                          _UpgradeRow(
                            quote: service.quote(progress, t),
                            now: _value(t, progress.levels),
                            next: _value(t, progress.levels.increment(t)),
                            onBuy: () => onBuy(t),
                            scale: scale,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 효과 값: 시트 공식 그대로 (GDD §5 공식).
  double _value(UpgradeType t, UpgradeLevels lv) => switch (t) {
    UpgradeType.launch => formulas.launchSpeedMps(lv),
    UpgradeType.aero => formulas.aeroMultiplier(lv),
    UpgradeType.boost => formulas.boostDistanceM(lv),
    UpgradeType.bounce => formulas.bounceMultiplier(lv),
    UpgradeType.coin => formulas.seedMultiplier(lv),
  };
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({
    required this.quote,
    required this.now,
    required this.next,
    required this.onBuy,
    required this.scale,
  });

  final UpgradeQuote quote;
  final double now;
  final double next;
  final VoidCallback onBuy;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final key = quote.type.configKey;
    final text = TextStyle(
      fontSize: 15 * scale,
      fontWeight: FontWeight.bold,
      color: MochiPalette.outline,
    );
    return Card(
      color: Colors.white.withValues(alpha: 0.85),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 6 * scale,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 150 * scale,
              child: Text(
                '${Strings.upgradeName(key)}  '
                '${Strings.upgradeLevel(quote.currentLevel)}',
                style: text,
              ),
            ),
            Expanded(
              child: Text(
                '${Strings.upgradeValue(key, now)}  →  '
                '${Strings.upgradeValue(key, next)}',
                style: text.copyWith(fontWeight: FontWeight.normal),
              ),
            ),
            FilledButton(
              onPressed: quote.affordable ? onBuy : null,
              style: FilledButton.styleFrom(
                backgroundColor: MochiPalette.backPatch,
              ),
              child: Text(
                Strings.upgradeCost(quote.cost),
                style: TextStyle(fontSize: 14 * scale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
