import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/run/boss/boss_ease.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/boss/cat_chase.dart';
import 'package:mozzi/domain/run/boss/crow_thief.dart';
import 'package:mozzi/domain/run/boss/pigeon_race.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';

import '../../../helpers/balance_fixture.dart';

/// GDD §4 보스 스테이지 상세: 1-5 고양이, 2-5 비둘기 대장, 3-5 까마귀 대장, 연속 실패 완화.
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);
  final spec = config.world.boss;
  final scale = config.simTimeScale;

  /// 발사 후 실제 [realSec] 초, 위치 [xM] 인 비행 상태.
  FlightState at(double realSec, double xM) => FlightState.initial.copyWith(
    phase: FlightPhase.flying,
    xM: xM,
    simTimeSec: realSec * scale,
  );

  const perfect = LaunchDecision(
    angleRad: 0.7853981633974483,
    power: 1.1,
    judgement: GaugeJudgement(
      grade: GaugeGrade.perfect,
      multiplier: 1.15,
      off: 0,
    ),
    speedMultiplier: 1.1247221879201993, // √(1.1 × 1.15)
  );

  RunSession bossRun(String id, UpgradeLevels lv, {double ease = 0}) {
    final (w, s) = (int.parse(id[0]), int.parse(id[2]));
    return RunSession(
      formulas: formulas,
      levels: lv,
      stage: config.world.stage(w, s),
      runSeed: 1,
      field: ObjectField.fixed(const []),
      bossEase: ease,
    )..launch(perfect);
  }

  group('연속 실패 완화', () {
    test('3판 연속 실패마다 5%, 최대 15%', () {
      expect(
        [0, 2, 3, 5, 6, 9, 30].map((n) => BossEase.ratio(n, spec)),
        [0, 0, 0.05, 0.05, 0.1, closeTo(0.15, 1e-9), 0.15],
      );
    });
  });

  group('보스 규칙은 보스 스테이지에만', () {
    test('1-5·2-5·3-5 는 각자의 규칙, 1-1·4-5 는 없음', () {
      BossRule? rule(int w, int s) =>
          BossRule.forStage(config.world.stage(w, s), config, ease: 0);
      expect(rule(1, 5), isA<CatChase>());
      expect(rule(2, 5), isA<PigeonRace>());
      expect(rule(3, 5), isA<CrowThief>());
      expect(rule(1, 1), isNull);
      expect(rule(4, 5), isNull, reason: '4-5·5-5 는 P11');
    });
  });

  group('1-5 고양이 추격', () {
    test('출발 전에는 잡히지 않고, 모찌 위치에 닿으면 실패', () {
      final cat = CatChase(goalM: 500, timeScale: scale, spec: spec, ease: 0);
      final stats = RunStats();
      cat.step(at(spec.cat15DelaySec - 0.1, 0), stats, goalReached: false);
      expect(cat.lost, isFalse);
      // 고양이 속도 = 500 / (6 − 2) = 125 m/s → 출발 1초 뒤 125m
      cat.step(at(spec.cat15DelaySec + 1, 200), stats, goalReached: false);
      expect(cat.lost, isFalse);
      expect(cat.rivalXM, closeTo(125, 1e-6));
      cat.step(at(spec.cat15DelaySec + 1, 120), stats, goalReached: false);
      expect(cat.lost, isTrue);
    });

    test('완화하면 고양이가 느려진다', () {
      final base = CatChase(goalM: 500, timeScale: scale, spec: spec, ease: 0);
      final eased = CatChase(
        goalM: 500,
        timeScale: scale,
        spec: spec,
        ease: 0.15,
      );
      expect(eased.speedMps, lessThan(base.speedMps));
    });

    test('부스터 없이 느리게 날면 고양이에게 잡혀 그 자리에서 판이 끝난다', () {
      final run = bossRun('1-5', UpgradeLevels.all(10))..runToStop();
      expect(run.bossLost, isTrue);
      expect(run.state.phase, FlightPhase.stopped);
      expect(run.stars()!.cleared, isFalse);
    });

    test('충분히 강하면 골을 먼저 지나 클리어 (골 뒤로는 추격 없음)', () {
      final run = bossRun('1-5', UpgradeLevels.all(30))..runToStop();
      expect(run.bossLost, isFalse);
      expect(run.stars()!.cleared, isTrue);
    });
  });

  group('2-5 비둘기 대장 레이스', () {
    test('대장은 T초에 골인 — 모찌가 그 전에 못 오면 실패', () {
      final race = PigeonRace(
        goalM: 2000,
        timeScale: scale,
        spec: spec,
        ease: 0,
      );
      final stats = RunStats();
      race.step(at(8, 900), stats, goalReached: false);
      expect(race.rivalXM, closeTo(1000, 1e-6));
      expect(race.lost, isFalse);
      race.step(at(spec.rival25TimeSec, 1900), stats, goalReached: false);
      expect(race.lost, isTrue);
    });

    test('먼저 골인하면 차이(초)를 ★★★ 판정에 기록', () {
      final race = PigeonRace(
        goalM: 2000,
        timeScale: scale,
        spec: spec,
        ease: 0,
      );
      final stats = RunStats();
      race.onGoal(at(12, 2000), stats);
      expect(stats.bossMarginSec, closeTo(spec.rival25TimeSec - 12, 1e-9));
    });

    test('완화하면 T 가 늘어난다 (최대 +15%)', () {
      final eased = PigeonRace(
        goalM: 2000,
        timeScale: scale,
        spec: spec,
        ease: 0.15,
      );
      expect(eased.timeSec, closeTo(spec.rival25TimeSec * 1.15, 1e-9));
    });

    test('강하게 날리면 대장보다 먼저 골인해 클리어하고 차이가 기록된다', () {
      final run = bossRun('2-5', UpgradeLevels.all(40))..runToStop();
      expect(run.bossLost, isFalse);
      expect(run.stars()!.cleared, isTrue);
      expect(run.stats.bossMarginSec, greaterThan(0));
    });
  });

  group('3-5 까마귀 대장', () {
    test('비행 중 게이지가 차고, 까마귀에 부딪히면 더 찬다', () {
      final crow = CrowThief(
        goalM: 6000,
        timeScale: scale,
        spec: spec,
        ease: 0,
      );
      final stats = RunStats();
      crow.step(at(10, 1000), stats, goalReached: false);
      expect(crow.meter, closeTo(spec.crow35StealPerSec * 10, 1e-9));
      stats.recordHit(ObjectKind.crow.key, obstacle: true);
      crow.step(at(10, 1000), stats, goalReached: false);
      expect(
        crow.meter,
        closeTo(spec.crow35StealPerSec * 10 + spec.crow35HitMeter, 1e-9),
      );
    });

    test('게이지 100% 면 실패', () {
      final crow = CrowThief(goalM: 6000, timeScale: scale, spec: spec, ease: 0)
        ..step(
          at(1 / spec.crow35StealPerSec + 0.1, 3000),
          RunStats(),
          goalReached: false,
        );
      expect(crow.lost, isTrue);
      expect(crow.meter, 1);
    });

    test('골 통과 시 게이지를 기록 (★★★ 50% 미만)', () {
      final crow = CrowThief(
        goalM: 6000,
        timeScale: scale,
        spec: spec,
        ease: 0,
      );
      final stats = RunStats();
      crow
        ..step(at(20, 5990), stats, goalReached: false)
        ..onGoal(at(20, 6000), stats);
      expect(stats.bossMeterMax, closeTo(spec.crow35StealPerSec * 20, 1e-9));
    });

    test('완화하면 게이지가 덜 찬다', () {
      final eased = CrowThief(
        goalM: 6000,
        timeScale: scale,
        spec: spec,
        ease: 0.1,
      );
      expect(eased.stealPerSec, closeTo(spec.crow35StealPerSec * 0.9, 1e-12));
    });

    test('강하게 날리면 게이지 100% 전에 골인', () {
      final run = bossRun('3-5', UpgradeLevels.all(40))..runToStop();
      expect(run.bossLost, isFalse);
      expect(run.stars()!.cleared, isTrue);
      expect(run.stats.bossMeterMax, inInclusiveRange(0, 1));
    });
  });
}
