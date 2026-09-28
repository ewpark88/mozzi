import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/run/star_rules.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §4 별 3개·스테이지별 ★★★ 미션·미션 타입 정의.
void main() {
  final world = loadDefaultBalance().world;
  const rules = StarRules(star2Ratio: 1.3);

  MissionSpec m(String type, [Map<String, Object?> p = const {}]) =>
      MissionSpec(type: type, params: {'type': type, ...p});

  test('시트의 26개 스테이지(1-1~5-5 + 6-1 달) 미션이 모두 아는 타입이고 판정된다', () {
    expect(world.stages, hasLength(26));
    for (final s in world.stages) {
      expect(s.star3, isNotEmpty, reason: s.id);
      for (final mission in s.star3) {
        expect(StarRules.knownTypes, contains(mission.type), reason: s.id);
        expect(
          () => rules.mission(mission, RunStats()),
          returnsNormally,
          reason: s.id,
        );
      }
    }
    expect(world.stage(3, 3).star3, hasLength(2), reason: '3-3 은 광고판 + 씨앗 40개');
  });

  test('별 최대치 26 × 3 = 78, 월드 해금 별 8/20/32/45/60 (GDD)', () {
    expect(world.stages.length * 3, 78);
    expect(world.unlockStars, {2: 8, 3: 20, 4: 32, 5: 45, 6: 60});
  });

  group('★ ★★ ★★★', () {
    final stage = world.stage(1, 3); // 150m, 트램폴린 2회
    RunStats stats({required double maxM, bool goal = true, int tramps = 0}) {
      final s = RunStats()..maxDistanceM = maxM;
      if (goal) s.goalTimeSec = 1;
      for (var i = 0; i < tramps; i++) {
        s.recordHit('tramp', obstacle: false);
      }
      return s;
    }

    test('목표 도달 = ★, 130% = ★★', () {
      expect(rules.evaluate(stage, stats(maxM: 160)).count, 1);
      expect(rules.evaluate(stage, stats(maxM: 195)).star2, isTrue);
      expect(rules.evaluate(stage, stats(maxM: 194)).star2, isFalse);
    });

    test('★★★ 은 미션 + 같은 판 ★ 이 모두 필요하다', () {
      expect(rules.evaluate(stage, stats(maxM: 160, tramps: 2)).star3, isTrue);
      expect(
        rules.evaluate(stage, stats(maxM: 100, goal: false, tramps: 2)).star3,
        isFalse,
      );
      expect(rules.evaluate(stage, stats(maxM: 160, tramps: 1)).star3, isFalse);
    });

    test('6-1 달: ★ 달 도달 / ★★ 씨앗 100개 (목표 거리 없음)', () {
      final moon = world.stage(6, 1);
      expect(moon.targetM, isNull);
      final s = RunStats()..seedsPicked = 100;
      final r = rules.evaluate(moon, s, moonReached: true);
      expect(r.cleared, isTrue);
      expect(r.star2, isTrue);
      expect(rules.evaluate(moon, s).cleared, isFalse);
    });
  });

  group('미션 타입', () {
    test('grade_min: PERFECT 이상', () {
      final mission = m('grade_min', {'grade': 'perfect'});
      expect(
        rules.mission(mission, RunStats()..grade = GaugeGrade.perfect),
        isTrue,
      );
      expect(
        rules.mission(mission, RunStats()..grade = GaugeGrade.great),
        isFalse,
      );
      expect(rules.mission(mission, RunStats()), isFalse);
    });

    test('seeds_min / combo_min / dive_perfect / glide_sec', () {
      final s = RunStats()..addSeeds(5);
      expect(rules.mission(m('seeds_min', {'n': 5}), s), isTrue);
      expect(rules.mission(m('seeds_min', {'n': 6}), s), isFalse);
      for (var i = 0; i < 6; i++) {
        s.recordHit('balloon', obstacle: false);
      }
      expect(rules.mission(m('combo_min', {'n': 6}), s), isTrue);
      s
        ..divePerfects = 1
        ..glideSec = 3.0;
      expect(rules.mission(m('dive_perfect', {'n': 1}), s), isTrue);
      expect(rules.mission(m('glide_sec', {'sec': 3}), s), isTrue);
    });

    test('hit / no_hit (아직 없는 오브젝트도 문자열 키로)', () {
      final s = RunStats()..recordHit('crow', obstacle: true);
      expect(rules.mission(m('no_hit', {'obj': 'crow'}), s), isFalse);
      expect(rules.mission(m('no_hit', {'obj': 'meteor'}), s), isTrue);
      expect(rules.mission(m('hit', {'obj': 'crow', 'n': 1}), s), isTrue);
    });

    test('no_boost / fuel_left_min / overcharge_perfect', () {
      final s = RunStats();
      expect(rules.mission(m('no_boost'), s), isTrue);
      s
        ..boostTaps = 1
        ..fuelAtGoal = 0.5
        ..grade = GaugeGrade.perfect
        ..power = 1.05;
      expect(rules.mission(m('no_boost'), s), isFalse);
      expect(rules.mission(m('fuel_left_min', {'ratio': 0.5}), s), isTrue);
      expect(
        rules.mission(m('overcharge_perfect', {'power': 1.05}), s),
        isTrue,
      );
      s.power = 1.04;
      expect(
        rules.mission(m('overcharge_perfect', {'power': 1.05}), s),
        isFalse,
      );
    });

    test('보스·달 미션 (P6·P11 기록이 없으면 실패)', () {
      final s = RunStats();
      expect(rules.mission(m('boss_margin_sec', {'sec': 3}), s), isFalse);
      expect(rules.mission(m('boss_meter_max', {'ratio': 0.5}), s), isFalse);
      expect(rules.mission(m('land_in_zone', {'radius_m': 50}), s), isFalse);
      s
        ..bossMarginSec = 3.2
        ..bossMeterMax = 0.49
        ..landingOffsetM = -40;
      expect(rules.mission(m('boss_margin_sec', {'sec': 3}), s), isTrue);
      expect(rules.mission(m('boss_meter_max', {'ratio': 0.5}), s), isTrue);
      expect(rules.mission(m('land_in_zone', {'radius_m': 50}), s), isTrue);
    });

    test('모르는 타입은 설정 오류', () {
      expect(
        () => rules.mission(m('fly_to_mars'), RunStats()),
        throwsArgumentError,
      );
    });
  });
}
