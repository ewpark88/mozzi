import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/math/round_half_up.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/pacing_simulator.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

import '../../helpers/balance_fixture.dart';

/// 정답: 밸런스 시트 「진행 시뮬」 (GDD §5 구역 도달 페이싱, ADR-008).
void main() {
  final config = loadDefaultBalance();
  final simulator = PacingSimulator(BalanceFormulas(config));
  final fixture = SheetFixture.load();
  final sheetRuns = fixture.pacingRuns;
  final runCount = sheetRuns.length;
  final zoneStarts = [for (final z in config.zones) z.startM];

  final sims = {
    for (final s in AdScenario.values)
      s: simulator.simulate(runs: runCount, scenario: s),
  };

  /// 시트와 다른 판을 모아서 한 번에 보여준다 (첫 10개).
  void expectNoMismatch(List<String> mismatches) {
    expect(
      mismatches.take(10).toList(),
      isEmpty,
      reason: '불일치 ${mismatches.length}판',
    );
  }

  test('광고X: 300판의 거리·씨앗·업그레이드 레벨이 시트와 같다', () {
    final sim = sims[AdScenario.none]!;
    final mismatches = <String>[];
    for (var i = 0; i < runCount; i++) {
      final s = sheetRuns[i];
      final r = sim[i];
      final levels = [for (final t in UpgradeType.values) r.levelsAfter[t]];
      if (roundHalfUp(r.distanceM) != s.distance('none') ||
          roundHalfUp(r.seedsEarned) != s.seeds('none') ||
          levels.join(',') != s.levelsNone.join(',')) {
        mismatches.add(
          '${s.run}판: 시트 ${s.distance('none')}m/${s.seeds('none')}/${s.levelsNone} '
          '≠ 시뮬 ${roundHalfUp(r.distanceM)}m/${roundHalfUp(r.seedsEarned)}/$levels',
        );
      }
    }
    expectNoMismatch(mismatches);
  });

  test('광고 30%(×1.3 기대값): 300판 거리가 시트와 같다', () {
    final sim = sims[AdScenario.ad30]!;
    expectNoMismatch([
      for (var i = 0; i < runCount; i++)
        if (roundHalfUp(sim[i].distanceM) != sheetRuns[i].distance('ad30'))
          '${i + 1}판: 시트 ${sheetRuns[i].distance('ad30')} ≠ ${roundHalfUp(sim[i].distanceM)}',
    ]);
  });

  test('광고 100%: 300판 거리·씨앗이 시트와 같다', () {
    final sim = sims[AdScenario.ad100]!;
    expectNoMismatch([
      for (var i = 0; i < runCount; i++)
        if (roundHalfUp(sim[i].distanceM) != sheetRuns[i].distance('ad100') ||
            roundHalfUp(sim[i].seedsEarned) != sheetRuns[i].seeds('ad100'))
          '${i + 1}판',
    ]);
  });

  group('구역 도달 판수가 시트 요약표와 같다', () {
    const keys = {
      AdScenario.none: 'none',
      AdScenario.ad30: 'ad30',
      AdScenario.ad100: 'ad100',
    };
    for (final entry in keys.entries) {
      test(entry.value, () {
        expect(
          PacingSimulator.zoneReachRuns(sims[entry.key]!, zoneStarts),
          fixture.zoneReach(entry.value),
        );
      });
    }
  });

  test('광고X 구역 도달 판수 = 설정 시트의 목표 도달 판수 (GDD §5 설계 의도)', () {
    expect(
      PacingSimulator.zoneReachRuns(sims[AdScenario.none]!, zoneStarts),
      [for (final z in config.zones) z.targetRunsNoAd],
    );
  });

  group('스테이지 목표 거리 도달 판수가 시트 「스테이지」와 같다 (GDD §4)', () {
    for (final entry in const {
      AdScenario.none: 'none',
      AdScenario.ad100: 'ad100',
    }.entries) {
      test(entry.value, () {
        expect(
          PacingSimulator.zoneReachRuns(
            sims[entry.key]!,
            fixture.stageTargetsM,
          ),
          fixture.stageReach(entry.value),
        );
      });
    }
  });

  test('같은 설정이면 결과가 항상 같다 (결정론)', () {
    final again = simulator.simulate(runs: 50);
    for (var i = 0; i < 50; i++) {
      expect(again[i].distanceM, sims[AdScenario.none]![i].distanceM);
      expect(again[i].levelsAfter, sims[AdScenario.none]![i].levelsAfter);
    }
  });
}
