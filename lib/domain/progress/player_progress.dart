import 'package:meta/meta.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/economy/wallet.dart';

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
/// 이전 버전 변환을 추가한다. 저장소 구현은 P6 (Hive).
@immutable
class PlayerProgress {
  const PlayerProgress({
    this.levels = const UpgradeLevels.zero(),
    this.wallet = Wallet.empty,
    this.bestDistanceM = 0,
    this.totalRuns = 0,
    this.onboardingStep = 0,
  });

  factory PlayerProgress.fromJson(Object? json) {
    final r = JsonReader(json);
    final version = r.integer('schema');
    if (version > schemaVersion) throw UnsupportedSaveVersion(version);
    return PlayerProgress(
      levels: UpgradeLevels.fromJson(r.object('levels')),
      wallet: Wallet.fromJson(r.object('wallet')),
      bestDistanceM: r.number('best_distance_m'),
      totalRuns: r.integer('total_runs'),
      onboardingStep: r.integer('onboarding_step'),
    );
  }

  /// 현재 세이브 스키마 버전.
  static const int schemaVersion = 1;

  /// 새 게임.
  static const PlayerProgress initial = PlayerProgress();

  final UpgradeLevels levels;
  final Wallet wallet;

  /// 최고 기록 (m). 고스트 깃발 위치 (GDD §2 콤보와 착지).
  final double bestDistanceM;

  /// 지금까지 완료한 판 수 (온보딩·전면 광고 유예 판단).
  final int totalRuns;

  /// 온보딩 진행 단계 (GDD §9, P8 에서 의미 확정).
  final int onboardingStep;

  PlayerProgress copyWith({
    UpgradeLevels? levels,
    Wallet? wallet,
    double? bestDistanceM,
    int? totalRuns,
    int? onboardingStep,
  }) => PlayerProgress(
    levels: levels ?? this.levels,
    wallet: wallet ?? this.wallet,
    bestDistanceM: bestDistanceM ?? this.bestDistanceM,
    totalRuns: totalRuns ?? this.totalRuns,
    onboardingStep: onboardingStep ?? this.onboardingStep,
  );

  Map<String, Object> toJson() => {
    'schema': schemaVersion,
    'levels': levels.toJson(),
    'wallet': wallet.toJson(),
    'best_distance_m': bestDistanceM,
    'total_runs': totalRuns,
    'onboarding_step': onboardingStep,
  };

  @override
  bool operator ==(Object other) =>
      other is PlayerProgress &&
      other.levels == levels &&
      other.wallet == wallet &&
      other.bestDistanceM == bestDistanceM &&
      other.totalRuns == totalRuns &&
      other.onboardingStep == onboardingStep;

  @override
  int get hashCode =>
      Object.hash(levels, wallet, bestDistanceM, totalRuns, onboardingStep);
}
