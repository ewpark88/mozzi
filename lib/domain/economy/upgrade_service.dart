import 'package:mozzi/core/result.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';

/// 업그레이드 구매 실패 사유.
enum PurchaseError { insufficientSeeds }

/// 업그레이드 화면에 보여줄 한 항목의 정보.
class UpgradeQuote {
  const UpgradeQuote({
    required this.type,
    required this.currentLevel,
    required this.cost,
    required this.affordable,
  });

  final UpgradeType type;
  final int currentLevel;

  /// 다음 레벨 비용 (씨앗).
  final int cost;
  final bool affordable;
}

/// 업그레이드 조회·구매 (GDD §5). 씨앗으로만 산다.
class UpgradeService {
  const UpgradeService(this.formulas);

  final BalanceFormulas formulas;

  UpgradeQuote quote(PlayerProgress progress, UpgradeType type) {
    final level = progress.levels[type];
    final cost = formulas.upgradeCost(type, level);
    return UpgradeQuote(
      type: type,
      currentLevel: level,
      cost: cost,
      affordable: progress.wallet.canAfford(Currency.seed, cost),
    );
  }

  /// [type] 을 1레벨 올린 진행 상태. 씨앗이 부족하면 실패.
  Result<PlayerProgress, PurchaseError> purchase(
    PlayerProgress progress,
    UpgradeType type,
  ) {
    final cost = formulas.upgradeCost(type, progress.levels[type]);
    return switch (progress.wallet.spend(Currency.seed, cost)) {
      Ok(value: final wallet) => Ok(
        progress.copyWith(
          wallet: wallet,
          levels: progress.levels.increment(type),
        ),
      ),
      Err() => const Err(PurchaseError.insufficientSeeds),
    };
  }
}
