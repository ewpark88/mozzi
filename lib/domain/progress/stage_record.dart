import 'package:meta/meta.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/run/star_rules.dart';

/// 스테이지 하나의 기록 (세이브 v2, GDD §4 스테이지 구조). 불변.
///
/// 별은 판마다 따로 모은다: ★·★★·★★★ 각각 한 번이라도 달성하면 유지된다
/// (★★★ 자체는 한 판 안에서 ★ 와 함께 달성해야 함 — StarRules).
@immutable
class StageRecord {
  const StageRecord({
    this.star1 = false,
    this.star2 = false,
    this.star3 = false,
    this.bestDistanceM = 0,
    this.bossFails = 0,
  });

  factory StageRecord.fromJson(JsonReader r) => StageRecord(
    star1: r.boolean('star1'),
    star2: r.boolean('star2'),
    star3: r.boolean('star3'),
    bestDistanceM: r.number('best_distance_m'),
    bossFails: r.integer('boss_fails'),
  );

  static const StageRecord empty = StageRecord();

  /// ★ = 클리어.
  final bool star1;
  final bool star2;
  final bool star3;

  /// 이 스테이지 최고 기록 (m). 고스트 깃발 위치.
  final double bestDistanceM;

  /// 보스 연속 실패 수 (클리어하면 0). 완화 계산용.
  final int bossFails;

  bool get cleared => star1;

  int get stars => [star1, star2, star3].where((s) => s).length;

  /// 한 판 결과를 더한다. [boss] 면 연속 실패를 센다.
  StageRecord withRun({
    required StarResult stars,
    required double distanceM,
    required bool boss,
  }) => StageRecord(
    star1: star1 || stars.cleared,
    star2: star2 || stars.star2,
    star3: star3 || stars.star3,
    bestDistanceM: distanceM > bestDistanceM ? distanceM : bestDistanceM,
    bossFails: !boss || stars.cleared ? 0 : bossFails + 1,
  );

  Map<String, Object> toJson() => {
    'star1': star1,
    'star2': star2,
    'star3': star3,
    'best_distance_m': bestDistanceM,
    'boss_fails': bossFails,
  };

  @override
  bool operator ==(Object other) =>
      other is StageRecord &&
      other.star1 == star1 &&
      other.star2 == star2 &&
      other.star3 == star3 &&
      other.bestDistanceM == bestDistanceM &&
      other.bossFails == bossFails;

  @override
  int get hashCode =>
      Object.hash(star1, star2, star3, bestDistanceM, bossFails);
}
