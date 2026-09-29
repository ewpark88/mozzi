import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/run/boss/cat_chase.dart';
import 'package:mozzi/domain/run/boss/crow_thief.dart';
import 'package:mozzi/domain/run/boss/pigeon_race.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

/// 보스 스테이지의 추가 규칙 하나 (GDD §4 보스 스테이지 상세).
///
/// 매 시뮬 스텝 [step] 을 부르고, [lost] 가 되면 판이 끝난다(모찌 정지).
/// 시간은 시뮬 초로 받아 [BalanceConfig.simTimeScale] 로 실제 초로 바꾼다
/// (보스 수치는 플레이어가 느끼는 실제 초 기준).
abstract class BossRule {
  BossRule({required this.goalM, required this.timeScale});

  /// 스테이지에 맞는 보스 규칙. 보스가 아니거나 규칙이 없는 보스(4-5·5-5, P11)는 null.
  static BossRule? forStage(
    StageSpec? stage,
    BalanceConfig config, {
    required double ease,
  }) {
    final goal = stage?.targetM;
    if (stage == null || !stage.boss || goal == null) return null;
    final spec = config.world.boss;
    final scale = config.simTimeScale;
    return switch (stage.id) {
      '1-5' => CatChase(goalM: goal, timeScale: scale, spec: spec, ease: ease),
      '2-5' => PigeonRace(
        goalM: goal,
        timeScale: scale,
        spec: spec,
        ease: ease,
      ),
      '3-5' => CrowThief(goalM: goal, timeScale: scale, spec: spec, ease: ease),
      _ => null,
    };
  }

  final double goalM;
  final double timeScale;

  bool _lost = false;

  /// 보스에게 져서 판이 끝났는지.
  bool get lost => _lost;

  /// 보스 위치 (m). 화면에 그리지 않는 보스는 null.
  double? get rivalXM;

  /// 보스 게이지 (0~1). 게이지가 없는 보스는 null.
  double? get meter => null;

  /// 발사 후 실제 시간 (초).
  double realSec(FlightState s) => s.simTimeSec / timeScale;

  /// 한 스텝 진행. 골을 이미 지났으면([goalReached]) 판정하지 않는다.
  void step(FlightState s, RunStats stats, {required bool goalReached}) {
    if (_lost || goalReached || s.phase == FlightPhase.ready) return;
    if (judge(s, stats)) _lost = true;
  }

  /// 골 통과 순간 (★★★ 기록용).
  void onGoal(FlightState s, RunStats stats) {}

  /// 이번 스텝에 보스에게 졌으면 true.
  bool judge(FlightState s, RunStats stats);
}
