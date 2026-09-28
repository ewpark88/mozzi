import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §4 배치 규칙: 100m 청크 시드 배치, 장애물 비율 월드별 0% → 30%.
void main() {
  final config = loadDefaultBalance();
  final spawn = config.world.spawn;

  List<WorldObject> chunks(int seed, int from, int to) => [
    for (var c = from; c < to; c++)
      ...ChunkGenerator(config, runSeed: seed).chunk(c),
  ];

  test('같은 시드·청크는 같은 배치, 다른 시드는 다른 배치', () {
    String sig(List<WorldObject> os) => os
        .map(
          (o) =>
              '${o.kind.key}@${o.xM.toStringAsFixed(3)},${o.yM.toStringAsFixed(3)}',
        )
        .join('|');
    expect(sig(chunks(42, 0, 30)), sig(chunks(42, 0, 30)));
    expect(sig(chunks(42, 0, 30)), isNot(sig(chunks(43, 0, 30))));
  });

  test('청크를 따로 만들어도 결과가 같다 (순서 무관)', () {
    final g = ChunkGenerator(config, runSeed: 7);
    final late = g.chunk(12);
    g.chunk(3);
    expect(ChunkGenerator(config, runSeed: 7).chunk(12).length, late.length);
  });

  test('월드는 거리로 정해진다 (시트 구역 시작 거리)', () {
    final g = ChunkGenerator(config, runSeed: 1);
    expect(g.worldAt(0), 1);
    expect(g.worldAt(499.9), 1);
    expect(g.worldAt(500), 2);
    expect(g.worldAt(2000), 3);
    expect(g.worldAt(40000), 6);
  });

  test('첫 오브젝트는 5m 이후, 모든 오브젝트는 자기 청크 안', () {
    for (var c = 0; c < 20; c++) {
      for (final o in ChunkGenerator(config, runSeed: 9).chunk(c)) {
        expect(o.xM, greaterThanOrEqualTo(ChunkGenerator.firstObjectM));
        expect(
          o.xM,
          lessThan(
            (c + 1) * spawn.chunkM +
                (spawn.seedRowCount - 1) * 0.7 * o.scale +
                1e-9,
          ),
          reason: '씨앗 줄은 줄 길이만큼 다음 청크로 넘칠 수 있음',
        );
      }
    }
  });

  test('월드 1 에는 씨앗·트램폴린·빨랫줄만, 장애물 없음', () {
    final kinds = chunks(5, 0, 5).map((o) => o.kind).toSet();
    expect(
      kinds.difference({
        ObjectKind.seed,
        ObjectKind.tramp,
        ObjectKind.clothesline,
      }),
      isEmpty,
    );
  });

  double obstacleRatio(double from, double to) {
    var obstacles = 0;
    var picks = 0;
    for (var seed = 0; seed < 40; seed++) {
      final g = ChunkGenerator(config, runSeed: seed);
      for (var c = (from / 100).ceil(); c < (to / 100).floor(); c++) {
        // 씨앗 줄(5개)은 한 번의 선택이므로 줄 첫 개만 센다
        final os = g.chunk(c).where((o) => o.xM >= from && o.xM < to).toList();
        for (var i = 0; i < os.length; i++) {
          if (os[i].kind == ObjectKind.seed &&
              i > 0 &&
              os[i - 1].kind == ObjectKind.seed &&
              os[i].id == os[i - 1].id + 1 &&
              (os[i].xM - os[i - 1].xM) < 2 * os[i].scale) {
            continue;
          }
          picks++;
          if (config.world.object(os[i].kind).category.name == 'obstacle') {
            obstacles++;
          }
        }
      }
    }
    return obstacles / picks;
  }

  test('장애물 비율: 공원 약 10%, 도시 옥상 약 20% (GDD 0% → 30%)', () {
    expect(obstacleRatio(500, 2000), closeTo(0.1, 0.04));
    expect(obstacleRatio(2000, 6000), closeTo(0.2, 0.05));
  });

  test('멀리 갈수록 간격·크기·높이가 커진다 (궤적 크기에 맞춤)', () {
    expect(spawn.spacingAt(10), spawn.minSpacingM);
    expect(spawn.spacingAt(2000), 2000 * spawn.spacingRatio);
    expect(spawn.scaleAt(10), 1);
    expect(spawn.scaleAt(2000), greaterThan(20));
    for (final o in chunks(3, 0, 60)) {
      if (o.kind.onGround) {
        expect(o.yM, 0);
      } else if (o.kind != ObjectKind.seed) {
        expect(o.yM, lessThanOrEqualTo(spawn.maxHeightAt(o.xM) + 1e-9));
        expect(o.yM, greaterThanOrEqualTo(spawn.minHeightM * o.scale - 1e-9));
      }
    }
  });

  test('ObjectField 는 가까운 것만 주고, 쓴 것은 다시 주지 않는다', () {
    final field = ObjectField.fixed(const [
      WorldObject(id: 1, kind: ObjectKind.seed, xM: 10, yM: 2, scale: 1),
      WorldObject(id: 2, kind: ObjectKind.seed, xM: 250, yM: 2, scale: 1),
    ]);
    expect(field.near(12, 5).map((o) => o.id), [1]);
    field.markUsed(1);
    expect(field.near(12, 5), isEmpty);
    expect(field.near(250, 1).map((o) => o.id), [2]);
  });
}
