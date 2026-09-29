import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/world_spec.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 보스 값 (GDD §4 보스 스테이지 상세, 시트 「스테이지」 보스 표). 시간은 실제 초.
class BossSpec {
  const BossSpec({
    required this.rival25TimeSec,
    required this.rival25PigeonMult,
    required this.failEaseStep,
    required this.failEaseMax,
    required this.cat15DelaySec,
    required this.cat15TimeSec,
    required this.rival25FountainMin,
    required this.rival25FountainMax,
    required this.crow35StealPerSec,
    required this.crow35HitMeter,
  });

  factory BossSpec.fromJson(JsonReader r) => BossSpec(
    rival25TimeSec: r.number('boss_2_5_rival_time_sec'),
    rival25PigeonMult: r.number('boss_2_5_pigeon_mult'),
    failEaseStep: r.number('boss_fail_ease_step'),
    failEaseMax: r.number('boss_fail_ease_max'),
    cat15DelaySec: r.number('boss_1_5_cat_delay_sec'),
    cat15TimeSec: r.number('boss_1_5_cat_time_sec'),
    rival25FountainMin: r.integer('boss_2_5_fountain_min'),
    rival25FountainMax: r.integer('boss_2_5_fountain_max'),
    crow35StealPerSec: r.number('boss_3_5_steal_per_sec'),
    crow35HitMeter: r.number('boss_3_5_crow_hit_meter'),
  );

  /// 2-5 대장이 골까지 걸리는 시간.
  final double rival25TimeSec;

  /// 2-5 코스 비둘기 비중 배율.
  final double rival25PigeonMult;

  /// 3판 연속 실패마다 완화 단계, 최대 완화.
  final double failEaseStep;
  final double failEaseMax;

  /// 1-5 고양이: 발사 후 출발 지연, 발사부터 골 도달까지 시간.
  final double cat15DelaySec;
  final double cat15TimeSec;

  /// 2-5 코스에 고정 배치하는 분수 수 (최소~최대).
  final int rival25FountainMin;
  final int rival25FountainMax;

  /// 3-5 까마귀 대장 게이지: 초당 상승, 까마귀 충돌 시 추가.
  final double crow35StealPerSec;
  final double crow35HitMeter;
}

/// 월드·스테이지·오브젝트 밸런스 (GDD §4). 시트 「스테이지」·「오브젝트」.
class WorldConfig {
  WorldConfig({
    required Map<ObjectKind, ObjectSpec> objects,
    required this.spawn,
    required List<WorldSpawn> spawnWeights,
    required List<StageSpec> stages,
    required this.star2Ratio,
    required Map<int, int> unlockStars,
    required this.boss,
  }) : objects = Map.unmodifiable(objects),
       spawnWeights = List.unmodifiable(spawnWeights),
       stages = List.unmodifiable(stages),
       unlockStars = Map.unmodifiable(unlockStars);

  factory WorldConfig.fromJson(JsonReader r) {
    final objs = r.object('objects');
    return WorldConfig(
      objects: {
        for (final k in ObjectKind.values)
          if (objs.has(k.key)) k: ObjectSpec.fromJson(k, objs.object(k.key)),
      },
      spawn: SpawnSpec.fromJson(r.object('spawn')),
      spawnWeights: r
          .objectList('spawn_weights')
          .map(WorldSpawn.fromJson)
          .toList(),
      stages: r
          .object('stage_table')
          .objectList('stages')
          .map(StageSpec.fromJson)
          .toList(),
      star2Ratio: r.number('stage_star2_ratio'),
      unlockStars: {
        for (final u in r.objectList('world_unlock_stars'))
          u.integer('world'): u.integer('stars'),
      },
      boss: BossSpec.fromJson(r),
    );
  }

  final Map<ObjectKind, ObjectSpec> objects;
  final SpawnSpec spawn;
  final List<WorldSpawn> spawnWeights;
  final List<StageSpec> stages;

  /// ★★ = 목표 × 이 값 (1.3).
  final double star2Ratio;

  /// 월드 → 해금에 필요한 별 개수.
  final Map<int, int> unlockStars;
  final BossSpec boss;

  ObjectSpec object(ObjectKind kind) =>
      objects[kind] ?? (throw StateError('오브젝트 값 없음: ${kind.key}'));

  StageSpec stage(int world, int stage) => stages.firstWhere(
    (s) => s.world == world && s.stage == stage,
    orElse: () => throw StateError('스테이지 없음: $world-$stage'),
  );

  /// 해당 월드의 배치 비중. 정의가 없으면 가장 가까운 아래 월드 것.
  WorldSpawn spawnFor(int world) {
    WorldSpawn? best;
    for (final w in spawnWeights) {
      if (w.world <= world && (best == null || w.world > best.world)) best = w;
    }
    return best ?? spawnWeights.first;
  }
}
