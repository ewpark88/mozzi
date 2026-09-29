import 'package:meta/meta.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/stage_record.dart';

/// 세이브 데이터가 현재 앱보다 새 버전이라 읽을 수 없음.
class UnsupportedSaveVersion implements Exception {
  const UnsupportedSaveVersion(this.version);

  final int version;

  @override
  String toString() =>
      'UnsupportedSaveVersion($version > ${PlayerProgress.schemaVersion})';
}

/// 플레이어 진행 상태 = 세이브 데이터 (불변).
///
/// 필드를 추가·변경하면 [schemaVersion] 을 올리고 [PlayerProgress.fromJson] 에
/// 이전 버전 변환을 추가한다.
/// - v1 → v2: 스테이지별 기록([stages])·해금([unlocks]) 추가. 없던 값은 빈 기록.
@immutable
class PlayerProgress {
  PlayerProgress({
    this.levels = const UpgradeLevels.zero(),
    this.wallet = Wallet.empty,
    this.bestDistanceM = 0,
    this.totalRuns = 0,
    this.onboardingStep = 0,
    Map<String, StageRecord> stages = const {},
    Set<String> unlocks = const {},
  }) : stages = Map.unmodifiable(stages),
       unlocks = Set.unmodifiable(unlocks);

  factory PlayerProgress.fromJson(Object? json) {
    final r = JsonReader(json);
    final version = r.integer('schema');
    if (version > schemaVersion) throw UnsupportedSaveVersion(version);
    final v2 = version >= 2;
    return PlayerProgress(
      levels: UpgradeLevels.fromJson(r.object('levels')),
      wallet: Wallet.fromJson(r.object('wallet')),
      bestDistanceM: r.number('best_distance_m'),
      totalRuns: r.integer('total_runs'),
      onboardingStep: r.integer('onboarding_step'),
      stages: v2 ? _stagesFromJson(r.object('stages')) : const {},
      unlocks: v2 ? r.stringList('unlocks').toSet() : const {},
    );
  }

  /// 현재 세이브 스키마 버전.
  static const int schemaVersion = 2;

  /// 새 게임.
  static final PlayerProgress initial = PlayerProgress();

  final UpgradeLevels levels;
  final Wallet wallet;

  /// 전체 최고 기록 (m).
  final double bestDistanceM;

  /// 지금까지 완료한 판 수 (온보딩·전면 광고 유예 판단).
  final int totalRuns;

  /// 온보딩 진행 단계 (GDD §9, P8 에서 의미 확정).
  final int onboardingStep;

  /// 스테이지 ID("1-1") → 기록. 한 번도 안 한 스테이지는 없음.
  final Map<String, StageRecord> stages;

  /// 해금된 것 (보스 보상 등, `Unlock` 키).
  final Set<String> unlocks;

  /// 스테이지 기록 (없으면 빈 기록).
  StageRecord stage(String id) => stages[id] ?? StageRecord.empty;

  /// 모은 별 합계 (GDD §4 월드 해금 조건).
  int get totalStars => stages.values.fold(0, (sum, s) => sum + s.stars);

  PlayerProgress copyWith({
    UpgradeLevels? levels,
    Wallet? wallet,
    double? bestDistanceM,
    int? totalRuns,
    int? onboardingStep,
    Map<String, StageRecord>? stages,
    Set<String>? unlocks,
  }) => PlayerProgress(
    levels: levels ?? this.levels,
    wallet: wallet ?? this.wallet,
    bestDistanceM: bestDistanceM ?? this.bestDistanceM,
    totalRuns: totalRuns ?? this.totalRuns,
    onboardingStep: onboardingStep ?? this.onboardingStep,
    stages: stages ?? this.stages,
    unlocks: unlocks ?? this.unlocks,
  );

  Map<String, Object> toJson() => {
    'schema': schemaVersion,
    'levels': levels.toJson(),
    'wallet': wallet.toJson(),
    'best_distance_m': bestDistanceM,
    'total_runs': totalRuns,
    'onboarding_step': onboardingStep,
    'stages': {for (final e in stages.entries) e.key: e.value.toJson()},
    'unlocks': unlocks.toList()..sort(),
  };

  static Map<String, StageRecord> _stagesFromJson(JsonReader r) => {
    for (final id in r.keys) id: StageRecord.fromJson(r.object(id)),
  };

  @override
  bool operator ==(Object other) =>
      other is PlayerProgress &&
      other.levels == levels &&
      other.wallet == wallet &&
      other.bestDistanceM == bestDistanceM &&
      other.totalRuns == totalRuns &&
      other.onboardingStep == onboardingStep &&
      _mapEquals(other.stages, stages) &&
      other.unlocks.length == unlocks.length &&
      other.unlocks.containsAll(unlocks);

  @override
  int get hashCode => Object.hash(
    levels,
    wallet,
    bestDistanceM,
    totalRuns,
    onboardingStep,
    Object.hashAllUnordered(
      stages.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(unlocks),
  );

  static bool _mapEquals(
    Map<String, StageRecord> a,
    Map<String, StageRecord> b,
  ) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
