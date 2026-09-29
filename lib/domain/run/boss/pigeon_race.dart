import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

/// 2-5 비둘기 대장 레이스: 발사 순간 출발해 일정 속도로 [timeSec] 에 골인.
/// 대장이 먼저 골인하면 실패. 모찌가 먼저 골인하면 차이(초)를 ★★★ 에 기록 (GDD §4).
/// 완화: T × (1 + 완화).
class PigeonRace extends BossRule {
  PigeonRace({
    required super.goalM,
    required super.timeScale,
    required BossSpec spec,
    required double ease,
  }) : timeSec = spec.rival25TimeSec * (1 + ease);

  /// 대장이 골까지 걸리는 실제 시간.
  final double timeSec;

  double _x = 0;

  @override
  double get rivalXM => _x;

  @override
  bool judge(FlightState s, RunStats stats) {
    final t = realSec(s);
    _x = goalM * (t / timeSec).clamp(0, 1);
    return t >= timeSec;
  }

  @override
  void onGoal(FlightState s, RunStats stats) =>
      stats.bossMarginSec = timeSec - realSec(s);
}
