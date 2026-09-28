import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mozzi/core/random/seeded_rng.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/world_spec.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 월드에 놓인 오브젝트 하나 (불변). 좌표는 미터, y 위가 +, 땅 오브젝트는 y = 0.
@immutable
class WorldObject {
  const WorldObject({
    required this.id,
    required this.kind,
    required this.xM,
    required this.yM,
    required this.scale,
  });

  /// 한 판 안에서 고유 (청크 번호 × 1000 + 순번).
  final int id;
  final ObjectKind kind;
  final double xM;
  final double yM;

  /// 거리 배율 (크기·영역 높이에 곱함).
  final double scale;
}

/// 100m 청크 결정론 배치 (GDD §4 배치 규칙). 같은 (런 시드, 청크 번호) = 같은 배치.
///
/// - 간격은 거리에 비례해 넓어지고(성기게), 크기·높이도 거리 배율만큼 커진다.
/// - 장애물 비율은 월드별 (0 → 30%).
/// - 월드는 거리 기준 (시트 「설정」 구역 시작 거리).
class ChunkGenerator {
  ChunkGenerator(this.config, {required this.runSeed});

  final BalanceConfig config;
  final int runSeed;

  /// 첫 오브젝트는 발사 지점에서 이만큼 떨어진 곳부터 (샘플 260px ≈ 5m).
  static const double firstObjectM = 5;

  static const int _idStride = 1000;

  SpawnSpec get _spawn => config.world.spawn;

  /// 거리 [xM] 의 월드 번호 (1부터).
  int worldAt(double xM) {
    var world = 1;
    for (var i = 0; i < config.zones.length; i++) {
      if (xM >= config.zones[i].startM) world = i + 1;
    }
    return world;
  }

  /// 청크 [index] 의 오브젝트.
  List<WorldObject> chunk(int index) {
    final rng = SeededRng(_mix(runSeed, index));
    final start = index * _spawn.chunkM;
    final end = start + _spawn.chunkM;
    final out = <WorldObject>[];
    var id = index * _idStride;
    var x =
        math.max(start, firstObjectM) +
        _spawn.spacingAt(start) * rng.nextDouble() * 0.5;
    while (x < end) {
      final spawn = config.world.spawnFor(worldAt(x));
      final kind = _pickKind(spawn, rng);
      if (kind != null) {
        for (final o in _place(kind, x, rng, id)) {
          out.add(o);
          id++;
        }
      }
      x += _spawn.spacingAt(x) * (0.7 + 0.6 * rng.nextDouble());
    }
    return out;
  }

  ObjectKind? _pickKind(WorldSpawn spawn, SeededRng rng) {
    final obstacle = rng.nextBool(spawn.obstacleRatio);
    final pool = {
      for (final e in spawn.weights.entries)
        if ((config.world.object(e.key).category == ObjectCategory.obstacle) ==
            obstacle)
          e.key: e.value,
    };
    final total = pool.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return null;
    var r = rng.nextDouble() * total;
    for (final e in pool.entries) {
      r -= e.value;
      if (r < 0) return e.key;
    }
    return pool.keys.last;
  }

  List<WorldObject> _place(ObjectKind kind, double x, SeededRng rng, int id) {
    final s = _spawn.scaleAt(x);
    if (kind.onGround) {
      return [WorldObject(id: id, kind: kind, xM: x, yM: 0, scale: s)];
    }
    final low = _spawn.minHeightM * s;
    final y = low + rng.nextDouble() * math.max(0, _spawn.maxHeightAt(x) - low);
    if (kind != ObjectKind.seed) {
      return [WorldObject(id: id, kind: kind, xM: x, yM: y, scale: s)];
    }
    // 씨앗은 호 모양 줄 (샘플: 36px 간격, 가운데가 40px 높음)
    final n = _spawn.seedRowCount;
    final gap = 0.7 * s;
    return [
      for (var i = 0; i < n; i++)
        WorldObject(
          id: id + i,
          kind: kind,
          xM: x + i * gap,
          yM: y + math.sin(i / math.max(1, n - 1) * math.pi) * 0.76 * s,
          scale: s,
        ),
    ];
  }

  static int _mix(int seed, int chunk) =>
      ((seed * 0x9E3779B1) ^ (chunk * 0x85EBCA77) ^ 0x27D4EB2F) & 0xFFFFFFFF;
}

/// 비행 중 주변 오브젝트 제공 + 먹은/부딪힌 오브젝트 기록 (한 판).
class ObjectField {
  ObjectField({required this.chunkM, required this.chunkOf});

  /// 생성기로 청크를 만드는 기본 필드.
  factory ObjectField.generated(ChunkGenerator generator) => ObjectField(
    chunkM: generator.config.world.spawn.chunkM,
    chunkOf: generator.chunk,
  );

  /// 정해진 오브젝트만 놓인 필드 (테스트·온보딩 고정 배치).
  factory ObjectField.fixed(List<WorldObject> objects, {double chunkM = 100}) =>
      ObjectField(
        chunkM: chunkM,
        chunkOf: (c) => [
          for (final o in objects)
            if ((o.xM / chunkM).floor() == c) o,
        ],
      );

  final double chunkM;
  final List<WorldObject> Function(int chunk) chunkOf;
  final Map<int, List<WorldObject>> _chunks = {};
  final Set<int> _used = {};

  double get _chunkM => chunkM;

  /// [xM] ± [rangeM] 안의, 아직 쓰지 않은 오브젝트.
  Iterable<WorldObject> near(double xM, double rangeM) sync* {
    final first = ((xM - rangeM) / _chunkM).floor();
    final last = ((xM + rangeM) / _chunkM).floor();
    for (var c = math.max(0, first); c <= last; c++) {
      for (final o in _chunks.putIfAbsent(c, () => chunkOf(c))) {
        if (!_used.contains(o.id) && (o.xM - xM).abs() <= rangeM) yield o;
      }
    }
  }

  /// 화면 표시용: [x0]~[x1] 의 모든 오브젝트 (쓴 것 포함).
  Iterable<WorldObject> between(double x0, double x1) sync* {
    for (
      var c = math.max(0, (x0 / _chunkM).floor());
      c <= (x1 / _chunkM).floor();
      c++
    ) {
      yield* _chunks.putIfAbsent(c, () => chunkOf(c));
    }
  }

  bool isUsed(int id) => _used.contains(id);

  void markUsed(int id) => _used.add(id);

  /// 지나간 청크 정리 (메모리).
  void pruneBehind(double xM) =>
      _chunks.removeWhere((c, _) => (c + 2) * _chunkM < xM);
}
