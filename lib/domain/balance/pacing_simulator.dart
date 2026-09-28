import 'package:mozzi/core/math/round_half_up.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

/// 페이싱 시뮬 광고 시나리오 (시트 「진행 시뮬」 3열).
enum AdScenario {
  /// 광고를 보지 않음.
  none(1),

  /// 결과화면 2배 광고를 30% 시청 — 기대값 모델 ×1.3 (ADR-008).
  ad30(1.3),

  /// 매판 2배 광고 시청.
  ad100(2);

  const AdScenario(this.seedMultiplier);

  final double seedMultiplier;
}

/// 페이싱 시뮬 한 판의 결과.
class PacingRun {
  const PacingRun({
    required this.runNumber,
    required this.distanceM,
    required this.seedsEarned,
    required this.levelsAfter,
  });

  /// 1부터 시작하는 판 번호.
  final int runNumber;

  /// 이번 판 거리 (m, 반올림 전).
  final double distanceM;

  /// 이번 판에 번 씨앗 (반올림 전, 광고 배율 포함).
  final double seedsEarned;

  /// 이번 판 종료 후 구매까지 마친 레벨.
  final UpgradeLevels levelsAfter;
}

/// 헤드리스 페이싱 시뮬레이터 (GDD §5 구역 도달 페이싱, ADR-008).
///
/// 매판 조작 없이 기대 거리만큼 날고, 판이 끝나면 “씨앗 1개당 판당 씨앗 증가량”이
/// 가장 큰 업그레이드를 반복 구매한다. 최선 항목을 살 수 없으면 그 판의 구매를 끝낸다.
/// 지갑은 소수로 누적한다 (시트 재현용 — 실제 게임 지갑은 정수).
/// 기준 구현 `tool/balance/pacing_sim.py` 와 결과가 같아야 한다.
class PacingSimulator {
  const PacingSimulator(this.formulas);

  final BalanceFormulas formulas;

  List<PacingRun> simulate({
    required int runs,
    AdScenario scenario = AdScenario.none,
  }) {
    var levels = const UpgradeLevels.zero();
    var wallet = 0.0;
    final result = <PacingRun>[];
    for (var run = 1; run <= runs; run++) {
      final distance = formulas.expectedDistanceM(levels);
      final earned =
          formulas.expectedSeedsPerRun(levels) * scenario.seedMultiplier;
      wallet += earned;
      while (true) {
        final best = _bestUpgrade(levels);
        final price = formulas.upgradeCost(best, levels[best]);
        if (price > wallet) break;
        wallet -= price;
        levels = levels.increment(best);
      }
      result.add(
        PacingRun(
          runNumber: run,
          distanceM: distance,
          seedsEarned: earned,
          levelsAfter: levels,
        ),
      );
    }
    return result;
  }

  /// 씨앗 1개당 판당 기대 씨앗 증가량이 가장 큰 업그레이드. 동점이면 선언 순서가 앞선 것.
  UpgradeType _bestUpgrade(UpgradeLevels levels) {
    final base = formulas.expectedSeedsPerRun(levels);
    UpgradeType? best;
    var bestRatio = double.negativeInfinity;
    for (final type in UpgradeType.values) {
      final gain = formulas.expectedSeedsPerRun(levels.increment(type)) - base;
      final ratio = gain / formulas.upgradeCost(type, levels[type]);
      if (ratio > bestRatio) {
        best = type;
        bestRatio = ratio;
      }
    }
    return best!;
  }

  /// 각 구역 시작 거리에 처음 도달한 판 번호. 도달하지 못하면 null.
  /// 거리는 시트와 같이 반올림한 값으로 비교한다.
  static List<int?> zoneReachRuns(
    List<PacingRun> runs,
    List<double> zoneStartsM,
  ) => [
    for (final start in zoneStartsM)
      runs
          .where((r) => roundHalfUp(r.distanceM) >= start)
          .map((r) => r.runNumber)
          .firstOrNull,
  ];
}
