import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

import '../../helpers/balance_fixture.dart';

/// 정답: 밸런스 시트 「업그레이드표」 (GDD §5 공식).
void main() {
  final formulas = BalanceFormulas(loadDefaultBalance());
  final table = SheetFixture.load().upgradeTable;

  test('시트 업그레이드표는 Lv0~80 전체를 담고 있다', () {
    expect(table.first.level, 0);
    expect(table.length, greaterThanOrEqualTo(41));
  });

  group('업그레이드표 레벨별 값이 시트와 같다', () {
    for (final row in table) {
      test('Lv${row.level}', () {
        final lv = UpgradeLevels.all(row.level);
        expect(
          [
            for (final t in UpgradeType.values)
              formulas.upgradeCost(t, row.level),
          ],
          row.costs,
          reason: '비용 ROUND(base × growth^Lv)',
        );
        expect(formulas.launchSpeedMps(lv), closeTo(row.launchSpeed, 1e-9));
        expect(formulas.aeroMultiplier(lv), closeTo(row.aeroMult, 1e-9));
        expect(formulas.boostDistanceM(lv), closeTo(row.boostM, 1e-6));
        expect(formulas.bounceMultiplier(lv), closeTo(row.bounceMult, 1e-9));
        expect(formulas.seedMultiplier(lv), closeTo(row.coinMult, 1e-9));
        expect(
          formulas.expectedDistanceM(lv),
          closeTo(row.distanceAllSameLv, 1e-6),
        );
      });
    }
  });

  group('비용 반올림은 Excel ROUND(사사오입)와 같다', () {
    test('고무줄 Lv1: 10 × 1.15 = 11.5 → 12', () {
      expect(formulas.upgradeCost(UpgradeType.launch, 1), 12);
    });
    test('바운스 Lv2: 40 × 1.25² = 62.5 → 63', () {
      expect(formulas.upgradeCost(UpgradeType.bounce, 2), 63);
    });
  });

  group('씨앗', () {
    test('Lv0 한 판(22.96m)은 씨앗 11개 (시트 진행 시뮬 1판)', () {
      const lv = UpgradeLevels.zero();
      expect(formulas.seedsForDistance(formulas.expectedDistanceM(lv), lv), 11);
    });

    test('볼주머니 Lv 와 광고 배율이 곱해진다', () {
      final lv = UpgradeLevels.of(const {UpgradeType.coin: 2});
      // 100m × 0.5 × 1.2 × 2 = 120
      expect(formulas.seedsForDistance(100, lv, adMultiplier: 2), 120);
    });
  });
}
