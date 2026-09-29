import 'package:meta/meta.dart';
import 'package:mozzi/core/random/seeded_rng.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/world_spec.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 스테이지별 코스 조정: 오브젝트 비중 배율 + 고정 배치 (GDD §4 2-5 비둘기 대장 레이스 코스).
@immutable
class CourseTweak {
  const CourseTweak({this.weightMult = const {}, this.fixed = const []});

  /// 스테이지에 맞는 조정. 보스 2-5 외에는 [none].
  factory CourseTweak.forStage(
    StageSpec? stage,
    BalanceConfig config, {
    required int runSeed,
    double? tutorialTrampM,
  }) {
    if (tutorialTrampM != null) {
      return CourseTweak.tutorial(tutorialTrampM, config);
    }
    final goal = stage?.targetM;
    if (stage == null || stage.id != pigeonRaceId || goal == null) return none;
    final boss = config.world.boss;
    final rng = SeededRng(runSeed ^ _fountainSalt);
    final count =
        boss.rival25FountainMin +
        rng.nextInt(boss.rival25FountainMax - boss.rival25FountainMin + 1);
    final spawn = config.world.spawn;
    return CourseTweak(
      weightMult: {ObjectKind.pigeon: boss.rival25PigeonMult},
      fixed: [
        for (var i = 0; i < count; i++)
          _fountain(i, count, goal, rng.nextDouble(), spawn),
      ],
    );
  }

  /// 온보딩 1판: 트램폴린 하나를 [xM] 에 고정 배치 (GDD §9).
  factory CourseTweak.tutorial(double xM, BalanceConfig config) => CourseTweak(
    fixed: [
      WorldObject(
        id: _fixedIdBase,
        kind: ObjectKind.tramp,
        xM: xM,
        yM: 0,
        scale: config.world.spawn.scaleAt(xM),
      ),
    ],
  );

  static const CourseTweak none = CourseTweak();

  /// 비둘기 대장 레이스 스테이지.
  static const String pigeonRaceId = '2-5';

  /// 분수는 코스 [_courseFrom]~[_courseTo] 구간에 고르게 (끝부분은 골 직전이라 제외).
  static const double _courseFrom = 0.15;
  static const double _courseTo = 0.85;

  /// 고정 배치 오브젝트 id (청크 id 와 겹치지 않게 큰 값).
  static const int _fixedIdBase = 1 << 30;
  static const int _fountainSalt = 0x5A17;

  final Map<ObjectKind, double> weightMult;
  final List<WorldObject> fixed;

  /// 월드 배치 비중에 배율을 곱한다.
  WorldSpawn apply(WorldSpawn spawn) => weightMult.isEmpty
      ? spawn
      : WorldSpawn(
          world: spawn.world,
          obstacleRatio: spawn.obstacleRatio,
          weights: {
            for (final e in spawn.weights.entries)
              e.key: e.value * (weightMult[e.key] ?? 1),
          },
        );

  static WorldObject _fountain(
    int i,
    int count,
    double goalM,
    double jitter,
    SpawnSpec spawn,
  ) {
    final slot = (_courseTo - _courseFrom) / count;
    final x = goalM * (_courseFrom + slot * (i + 0.25 + 0.5 * jitter));
    return WorldObject(
      id: _fixedIdBase + i,
      kind: ObjectKind.fountain,
      xM: x,
      yM: 0,
      scale: spawn.scaleAt(x),
    );
  }
}
