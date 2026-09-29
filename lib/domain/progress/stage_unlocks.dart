import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/progress/player_progress.dart';

/// 스테이지·월드 해금 규칙 (GDD §4 스테이지 구조 — 월드 해금).
///
/// - 월드 1 은 처음부터 열림. 월드 N 은 월드 N−1 의 5번(보스) 클리어 + 별 합계 ≥
///   시트 「스테이지」 해금 별(8/20/32/45/60).
/// - 월드 안에서는 앞 스테이지를 클리어하면 다음 스테이지가 열린다.
class StageUnlocks {
  const StageUnlocks(this.world);

  final WorldConfig world;

  /// 지금 플레이할 수 있는 월드 수 (MVP = 월드 1~3, 월드 4~6 은 P11).
  static const int playableWorlds = 3;

  /// 월드 하나의 스테이지 수.
  static const int stagesPerWorld = 5;

  /// 월드 [w] 해금에 필요한 별 (월드 1 은 0).
  int starsNeeded(int w) => world.unlockStars[w] ?? 0;

  bool isWorldUnlocked(int w, PlayerProgress p) {
    if (w <= 1) return true;
    if (w > playableWorlds) return false;
    return p.stage('${w - 1}-$stagesPerWorld').cleared &&
        p.totalStars >= starsNeeded(w);
  }

  bool isStageUnlocked(StageSpec s, PlayerProgress p) =>
      isWorldUnlocked(s.world, p) &&
      (s.stage == 1 || p.stage('${s.world}-${s.stage - 1}').cleared);

  /// 월드맵에 보여줄 스테이지 (플레이 가능한 월드만, 순서대로).
  List<StageSpec> mapStages() => [
    for (final s in world.stages)
      if (s.world <= playableWorlds) s,
  ];

  /// 이어서 할 스테이지: 열린 스테이지 중 아직 클리어 안 한 첫 스테이지, 없으면 마지막 열린 것.
  StageSpec nextStage(PlayerProgress p) {
    final open = mapStages().where((s) => isStageUnlocked(s, p)).toList();
    return open.firstWhere(
      (s) => !p.stage(s.id).cleared,
      orElse: () => open.last,
    );
  }
}
