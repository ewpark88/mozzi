import 'package:meta/meta.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';

/// 한 판의 별 결과 (GDD §4 별 3개).
@immutable
class StarResult {
  const StarResult({
    required this.cleared,
    required this.star2,
    required this.missions,
  });

  /// ★ 목표 거리 도달 (= 스테이지 클리어).
  final bool cleared;

  /// ★★ 목표 × 1.3 도달.
  final bool star2;

  /// ★★★ 미션별 달성 여부 (시트 순서).
  final List<bool> missions;

  /// ★★★: 모든 미션 달성 + 같은 판에서 ★.
  bool get star3 => cleared && missions.every((m) => m);

  int get count => [cleared, star2, star3].where((s) => s).length;

  @override
  bool operator ==(Object other) =>
      other is StarResult &&
      other.cleared == cleared &&
      other.star2 == star2 &&
      other.missions.length == missions.length &&
      Iterable<int>.generate(
        missions.length,
      ).every((i) => other.missions[i] == missions[i]);

  @override
  int get hashCode => Object.hash(cleared, star2, Object.hashAll(missions));
}

/// ★·★★·★★★ 판정 (GDD §4 별 3개·스테이지별 ★★★ 미션·미션 타입 정의).
class StarRules {
  const StarRules({required this.star2Ratio});

  final double star2Ratio;

  /// 6-1 달 ★★ 기준 씨앗 수 (GDD: “★★ 씨앗 100개”).
  static const int moonSeedsForStar2 = 100;

  /// 미션 타입 전체 (GDD 미션 타입 정의 15종). 모르는 타입은 설정 오류.
  static const Set<String> knownTypes = {
    'grade_min',
    'seeds_min',
    'hit',
    'no_hit',
    'no_boost',
    'fuel_left_min',
    'glide_sec',
    'dive_perfect',
    'combo_min',
    'ride_full',
    'overcharge_perfect',
    'boss_margin_sec',
    'boss_meter_max',
    'boss_perfect_all',
    'land_in_zone',
  };

  /// 목표 거리가 없는 6-1 달은 [moonReached] 로 ★ 를 판정한다.
  StarResult evaluate(
    StageSpec stage,
    RunStats stats, {
    bool moonReached = false,
  }) {
    final target = stage.targetM;
    final cleared = target == null ? moonReached : stats.goalTimeSec != null;
    final star2 = target == null
        ? cleared && stats.seedsPicked >= moonSeedsForStar2
        : stats.maxDistanceM >= target * star2Ratio;
    return StarResult(
      cleared: cleared,
      star2: star2,
      missions: [for (final m in stage.star3) mission(m, stats)],
    );
  }

  /// 미션 하나 판정.
  bool mission(MissionSpec m, RunStats s) => switch (m.type) {
    'grade_min' =>
      s.grade != null && s.grade!.index <= _grade(m.stringParam('grade')).index,
    'seeds_min' => s.seedsPicked >= m.intParam('n'),
    'hit' => s.hits(m.stringParam('obj')) >= m.intParam('n'),
    'no_hit' => s.hits(m.stringParam('obj')) == 0,
    'no_boost' => s.boostTaps == 0,
    'fuel_left_min' => (s.fuelAtGoal ?? -1) >= m.numParam('ratio'),
    'glide_sec' => s.glideSec >= m.numParam('sec'),
    'dive_perfect' => s.divePerfects >= m.intParam('n'),
    'combo_min' => s.comboMax >= m.intParam('n'),
    'ride_full' => (s.rideFull[m.stringParam('obj')] ?? 0) >= m.intParam('n'),
    'overcharge_perfect' =>
      s.grade == GaugeGrade.perfect && s.power >= m.numParam('power') - 1e-9,
    'boss_margin_sec' =>
      (s.bossMarginSec ?? double.negativeInfinity) >= m.numParam('sec'),
    'boss_meter_max' =>
      s.bossMeterMax != null && s.bossMeterMax! < m.numParam('ratio'),
    'boss_perfect_all' => s.bossPerfects >= m.intParam('n'),
    'land_in_zone' =>
      s.landingOffsetM != null &&
          s.landingOffsetM!.abs() <= m.numParam('radius_m'),
    _ => throw ArgumentError('알 수 없는 미션 타입: ${m.type}'),
  };

  static GaugeGrade _grade(String name) => GaugeGrade.values.firstWhere(
    (g) => g.name == name,
    orElse: () => throw ArgumentError('알 수 없는 판정: $name'),
  );
}
