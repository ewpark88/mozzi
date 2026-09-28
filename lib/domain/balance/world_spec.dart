import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 오브젝트 한 종류의 효과 값 (시트 「오브젝트」 한 행). 값1~3 의 뜻은 분류마다 다르다.
class ObjectSpec {
  const ObjectSpec({
    required this.kind,
    required this.world,
    required this.category,
    required this.radiusM,
    required this.p1,
    required this.p2,
    required this.p3,
  });

  factory ObjectSpec.fromJson(ObjectKind kind, JsonReader r) {
    final p = r.numberList('p');
    if (p.length != 3) {
      throw JsonFormatError('${r.path}.p', '값 3개 필요 (${p.length}개)');
    }
    return ObjectSpec(
      kind: kind,
      world: r.integer('world'),
      category: ObjectCategory.parse(r.string('category')),
      radiusM: r.number('radius_m'),
      p1: p[0],
      p2: p[1],
      p3: p[2],
    );
  }

  final ObjectKind kind;

  /// 처음 등장하는 월드.
  final int world;
  final ObjectCategory category;

  /// 거리 배율 1 일 때 충돌 반지름 (땅 오브젝트는 반폭).
  final double radiusM;
  final double p1;
  final double p2;
  final double p3;
}

/// 배치 설정 (시트 「오브젝트」 배치 표, GDD §4 배치 규칙).
class SpawnSpec {
  const SpawnSpec({
    required this.chunkM,
    required this.minSpacingM,
    required this.spacingRatio,
    required this.scaleRefM,
    required this.minHeightM,
    required this.heightBaseM,
    required this.heightRatio,
    required this.seedRowCount,
  });

  factory SpawnSpec.fromJson(JsonReader r) => SpawnSpec(
    chunkM: r.number('spawn_chunk_m'),
    minSpacingM: r.number('spawn_min_spacing_m'),
    spacingRatio: r.number('spawn_spacing_ratio'),
    scaleRefM: r.number('spawn_scale_ref_m'),
    minHeightM: r.number('spawn_min_h_m'),
    heightBaseM: r.number('spawn_h_base_m'),
    heightRatio: r.number('spawn_h_ratio'),
    seedRowCount: r.integer('seed_row_count'),
  );

  final double chunkM;
  final double minSpacingM;
  final double spacingRatio;
  final double scaleRefM;
  final double minHeightM;
  final double heightBaseM;
  final double heightRatio;
  final int seedRowCount;

  /// 거리 [xM] 에서 오브젝트 간격 (m).
  double spacingAt(double xM) =>
      xM * spacingRatio > minSpacingM ? xM * spacingRatio : minSpacingM;

  /// 거리 배율: 멀수록 오브젝트가 커지고 성기다 (궤적 크기에 맞춤).
  double scaleAt(double xM) {
    final s = spacingAt(xM) / scaleRefM;
    return s > 1 ? s : 1;
  }

  /// 거리 [xM] 에서 공중 오브젝트 최고 높이.
  double maxHeightAt(double xM) => heightBaseM + xM * heightRatio;
}

/// 월드별 배치 비중.
class WorldSpawn {
  const WorldSpawn({
    required this.world,
    required this.obstacleRatio,
    required this.weights,
  });

  factory WorldSpawn.fromJson(JsonReader r) {
    final w = r.object('weights');
    return WorldSpawn(
      world: r.integer('world'),
      obstacleRatio: r.number('obstacle_ratio'),
      weights: {
        for (final k in ObjectKind.values)
          if (w.has(k.key)) k: w.number(k.key),
      },
    );
  }

  final int world;

  /// 오브젝트 중 장애물 비율 (0 → 0.3).
  final double obstacleRatio;
  final Map<ObjectKind, double> weights;
}
