import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/core/result.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/economy/upgrade_service.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';

import '../../helpers/balance_fixture.dart';

void main() {
  group('Wallet', () {
    test('더하고 쓴다', () {
      final w = Wallet.empty.add(Currency.seed, 30).add(Currency.candy, 5);
      expect(w, const Wallet(seeds: 30, candy: 5));
      final spent = w.spend(Currency.seed, 12);
      expect(spent, isA<Ok<Wallet, SpendError>>());
      expect((spent as Ok<Wallet, SpendError>).value.seeds, 18);
    });

    test('잔액보다 많이 쓰면 실패하고 잔액은 그대로다', () {
      const w = Wallet(seeds: 10);
      final r = w.spend(Currency.seed, 11);
      expect(r, isA<Err<Wallet, SpendError>>());
      expect(
        (r as Err<Wallet, SpendError>).error,
        SpendError.insufficientFunds,
      );
      expect(w.seeds, 10);
    });

    test('음수 금액은 거부한다', () {
      expect(() => Wallet.empty.add(Currency.seed, -1), throwsArgumentError);
      expect(
        (Wallet.empty.spend(Currency.seed, -1) as Err<Wallet, SpendError>)
            .error,
        SpendError.invalidAmount,
      );
    });

    test('세이브의 음수 잔액은 손상 데이터로 거부한다', () {
      expect(
        () => Wallet.fromJson(JsonReader({'seeds': -5, 'candy': 0})),
        throwsA(isA<JsonFormatError>()),
      );
    });
  });

  group('UpgradeService (GDD §5)', () {
    final service = UpgradeService(BalanceFormulas(loadDefaultBalance()));

    test('견적: Lv0 고무줄은 10씨앗', () {
      const progress = PlayerProgress(wallet: Wallet(seeds: 9));
      final q = service.quote(progress, UpgradeType.launch);
      expect(q.currentLevel, 0);
      expect(q.cost, 10);
      expect(q.affordable, isFalse);
    });

    test('구매하면 씨앗이 줄고 레벨이 오른다', () {
      const progress = PlayerProgress(wallet: Wallet(seeds: 100));
      final r = service.purchase(progress, UpgradeType.boost);
      final next = (r as Ok<PlayerProgress, PurchaseError>).value;
      expect(next.wallet.seeds, 75); // 부스터 Lv0 비용 25
      expect(next.levels[UpgradeType.boost], 1);
      expect(next.levels[UpgradeType.launch], 0);
    });

    test('연속 구매는 레벨별 비용을 따른다 (바운스 40 → 50 → 63)', () {
      var progress = const PlayerProgress(wallet: Wallet(seeds: 153));
      for (var i = 0; i < 3; i++) {
        progress =
            (service.purchase(progress, UpgradeType.bounce)
                    as Ok<PlayerProgress, PurchaseError>)
                .value;
      }
      expect(progress.levels[UpgradeType.bounce], 3);
      expect(progress.wallet.seeds, 0);
    });

    test('씨앗이 부족하면 실패하고 진행 상태는 그대로다', () {
      final progress = PlayerProgress(
        levels: UpgradeLevels.of(const {UpgradeType.coin: 1}),
        wallet: const Wallet(seeds: 77),
      );
      final r = service.purchase(progress, UpgradeType.coin); // 비용 78
      expect(
        (r as Err<PlayerProgress, PurchaseError>).error,
        PurchaseError.insufficientSeeds,
      );
    });
  });
}
