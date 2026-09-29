import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

/// 1-5 고양이 추격: 발사 [BossSpec.cat15DelaySec] 뒤 땅 위를 일정 속도로 달려,
/// 발사 후 [BossSpec.cat15TimeSec] 에 골에 닿는다. 모찌 위치를 따라잡으면 실패.
/// 모찌가 날 때는 뒤처지고, 땅에 닿아 느려지면 다가온다 (GDD §4).
/// 완화: 골 도달 시간 × (1 + 완화).
class CatChase extends BossRule {
  CatChase({
    required super.goalM,
    required super.timeScale,
    required BossSpec spec,
    required double ease,
  }) : delaySec = spec.cat15DelaySec,
       speedMps = goalM / (spec.cat15TimeSec * (1 + ease) - spec.cat15DelaySec);

  final double delaySec;

  /// 실제 초당 m.
  final double speedMps;

  double _x = 0;

  @override
  double get rivalXM => _x;

  @override
  bool judge(FlightState s, RunStats stats) {
    final t = realSec(s) - delaySec;
    if (t <= 0) return false;
    _x = speedMps * t;
    return _x >= s.xM;
  }
}
