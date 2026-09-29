import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/unlock.dart';
import 'package:mozzi/domain/run/boss/boss_ease.dart';
import 'package:mozzi/domain/run/run_result.dart';

/// 한 판 결과를 진행 상태에 반영한다 (GDD §2 결과 화면, §4 별·보스).
///
/// 씨앗 지급(실패해도), 판 수, 최고 기록, 스테이지 별·기록·보스 연속 실패, 보스 보상 해금.
class RunRecorder {
  const RunRecorder(this.config);

  final BalanceConfig config;

  /// [result] 를 반영한 새 진행 상태. [watchedAd] 면 씨앗 × 광고 배율.
  PlayerProgress record(
    PlayerProgress p,
    RunResult result, {
    bool watchedAd = false,
  }) {
    final seeds = watchedAd
        ? result.seedsWithAd(config.adRewardMultiplier)
        : result.seeds;
    var next = p.copyWith(
      wallet: p.wallet.add(Currency.seed, seeds),
      totalRuns: p.totalRuns + 1,
      bestDistanceM: result.distanceM > p.bestDistanceM
          ? result.distanceM
          : p.bestDistanceM,
    );
    final id = result.stageId;
    final stars = result.stars;
    if (id == null || stars == null) return next;
    final spec = _stage(id);
    next = next.copyWith(
      stages: {
        ...next.stages,
        id: next
            .stage(id)
            .withRun(
              stars: stars,
              distanceM: result.distanceM,
              boss: spec.boss,
            ),
      },
    );
    if (spec.boss && stars.cleared) {
      next = next.copyWith(
        unlocks: {...next.unlocks, ...?Unlock.bossRewards[id]},
      );
    }
    return next;
  }

  /// 이미 기록한 판에 결과 화면 광고 보너스를 더한다 (광고 배율 − 1 배 만큼).
  PlayerProgress adBonus(PlayerProgress p, RunResult result) => p.copyWith(
    wallet: p.wallet.add(
      Currency.seed,
      result.seedsWithAd(config.adRewardMultiplier) - result.seeds,
    ),
  );

  /// 스테이지 [id] 의 보스 완화 비율 (보스가 아니면 0).
  double bossEase(PlayerProgress p, String id) => _stage(id).boss
      ? BossEase.ratio(p.stage(id).bossFails, config.world.boss)
      : 0;

  StageSpec _stage(String id) =>
      config.world.stages.firstWhere((s) => s.id == id);
}
