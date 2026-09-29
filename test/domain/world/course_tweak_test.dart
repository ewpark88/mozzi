import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/course_tweak.dart';
import 'package:mozzi/domain/world/object_kind.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §4 2-5 비둘기 대장 레이스 코스: 비둘기 ×1.5, 분수 2~3개.
void main() {
  final config = loadDefaultBalance();
  final spec = config.world.boss;
  final race = config.world.stage(2, 5);

  test('2-5 는 분수 2~3개를 코스 안에 고정 배치하고 비둘기 비중 ×1.5', () {
    final park = config.world.spawnFor(2);
    for (var seed = 1; seed <= 20; seed++) {
      final t = CourseTweak.forStage(race, config, runSeed: seed);
      expect(
        t.fixed.length,
        inInclusiveRange(spec.rival25FountainMin, spec.rival25FountainMax),
      );
      for (final o in t.fixed) {
        expect(o.kind, ObjectKind.fountain);
        expect(o.xM, inExclusiveRange(0, race.targetM!));
      }
      expect(
        t.apply(park).weights[ObjectKind.pigeon],
        closeTo(
          park.weights[ObjectKind.pigeon]! * spec.rival25PigeonMult,
          1e-9,
        ),
      );
    }
  });

  test('다른 스테이지는 조정 없음', () {
    expect(
      CourseTweak.forStage(config.world.stage(2, 4), config, runSeed: 1),
      same(CourseTweak.none),
    );
  });

  test('고정 분수는 해당 청크에 들어간다', () {
    final t = CourseTweak.forStage(race, config, runSeed: 7);
    final gen = ChunkGenerator(config, runSeed: 7, tweak: t);
    for (final f in t.fixed) {
      final chunk = gen.chunk((f.xM / config.world.spawn.chunkM).floor());
      expect(chunk.where((o) => o.id == f.id), hasLength(1));
    }
  });
}
