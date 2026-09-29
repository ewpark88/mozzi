import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §2 결과 화면: 거리·최고 기록 대비·씨앗(거리 + 먹은 씨앗)·별 (ADR-017).
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);
  final lv = UpgradeLevels.all(5);

  RunSession flown() =>
      RunSession(
          formulas: formulas,
          levels: lv,
          stage: config.world.stage(1, 2),
          runSeed: 3,
          field: ObjectField.fixed(const []),
        )
        ..launch(
          const LaunchDecision(
            angleRad: 0.7853981633974483,
            power: 1,
            judgement: GaugeJudgement(
              grade: GaugeGrade.good,
              multiplier: 1,
              off: 0.5,
            ),
            speedMultiplier: 1,
          ),
        )
        ..runToStop();

  test('정지한 판에서 결과를 만든다 — 거리 씨앗은 시트 공식 그대로', () {
    final s = flown();
    final r = RunResult.fromSession(s, lv, previousBestM: 0);
    expect(r.stageId, '1-2');
    expect(r.distanceM, s.state.distanceM);
    expect(r.distanceSeeds, formulas.seedsForDistance(r.distanceM, lv));
    expect(r.pickupSeeds, 0, reason: '오브젝트 없음');
    expect(r.seeds, r.distanceSeeds);
    expect(r.stars, isNotNull);
    expect(r.isNewRecord, isTrue);
    expect(r.bossLost, isFalse);
  });

  test('직전 최고 기록보다 짧으면 신기록 아님, 차이는 음수', () {
    final s = flown();
    final r = RunResult.fromSession(
      s,
      lv,
      previousBestM: s.state.distanceM + 10,
    );
    expect(r.isNewRecord, isFalse);
    expect(r.bestDeltaM, closeTo(-10, 1e-9));
  });
}
