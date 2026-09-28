import 'dart:math' as math;

import 'package:mozzi/core/math/round_half_up.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

/// GDD §5 공식. 결과는 밸런스 시트 「업그레이드표」·「진행 시뮬」과 일치해야 한다
/// (test/domain/balance/balance_formulas_test.dart 가 시트 fixture 로 검증).
class BalanceFormulas {
  const BalanceFormulas(this.config);

  final BalanceConfig config;

  double _effect(UpgradeType type) => config.upgrade(type).effect;

  /// 현재 레벨 [level] 에서 다음 레벨로 올리는 비용. `ROUND(base × growth^Lv)`.
  int upgradeCost(UpgradeType type, int level) {
    final spec = config.upgrade(type);
    return roundHalfUp(spec.baseCost * math.pow(spec.costGrowth, level));
  }

  /// 발사 속도 `v = phys_v0 + launch × Lv` (m/s).
  double launchSpeedMps(UpgradeLevels lv) =>
      config.baseLaunchSpeedMps +
      _effect(UpgradeType.launch) * lv[UpgradeType.launch];

  /// 공기역학 비행거리 배율 `1 + aero × Lv`.
  double aeroMultiplier(UpgradeLevels lv) =>
      1 + _effect(UpgradeType.aero) * lv[UpgradeType.aero];

  /// 부스터 추가 거리 `phys_boost_k × Lv^지수` (m).
  double boostDistanceM(UpgradeLevels lv) =>
      config.boostDistanceK *
      math.pow(lv[UpgradeType.boost], _effect(UpgradeType.boost)).toDouble();

  /// 바운스 거리 배율 `1 + bounce × Lv`.
  double bounceMultiplier(UpgradeLevels lv) =>
      1 + _effect(UpgradeType.bounce) * lv[UpgradeType.bounce];

  /// 볼주머니 씨앗 배율 `1 + coin × Lv`.
  double seedMultiplier(UpgradeLevels lv) =>
      1 + _effect(UpgradeType.coin) * lv[UpgradeType.coin];

  /// 조작 없이 날렸을 때의 기대 거리 (m).
  /// `d = (v²/g × 공기역학 배율 + 부스터 거리) × 바운스 배율`
  double expectedDistanceM(UpgradeLevels lv) {
    final v = launchSpeedMps(lv);
    final flight = v * v / config.gravityMps2 * aeroMultiplier(lv);
    return (flight + boostDistanceM(lv)) * bounceMultiplier(lv);
  }

  /// 거리 [distanceM] 로 얻는 씨앗 (반올림 전). `d × coin_per_m × 볼주머니 배율 × 광고 배율`
  double rawSeedsForDistance(
    double distanceM,
    UpgradeLevels lv, {
    double adMultiplier = 1,
  }) => distanceM * config.seedsPerM * seedMultiplier(lv) * adMultiplier;

  /// 한 판 보상으로 지갑에 넣는 씨앗 (정수, 사사오입). (ADR-008)
  int seedsForDistance(
    double distanceM,
    UpgradeLevels lv, {
    double adMultiplier = 1,
  }) => roundHalfUp(
    rawSeedsForDistance(distanceM, lv, adMultiplier: adMultiplier),
  );

  /// 조작 없이 한 판을 했을 때 기대 씨앗 (반올림 전). 페이싱 시뮬의 구매 판단 기준.
  double expectedSeedsPerRun(UpgradeLevels lv) =>
      rawSeedsForDistance(expectedDistanceM(lv), lv);
}
