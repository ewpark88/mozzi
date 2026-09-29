import 'dart:math' as math;

import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 3-5 까마귀 대장: 따라오며 씨앗을 훔친다. 훔친 게이지가 비행 중 실제 초당
/// [BossSpec.crow35StealPerSec] 씩, 까마귀에 부딪힐 때마다 [BossSpec.crow35HitMeter]
/// 씩 차고 100% 가 되면 실패. 골 통과 시 게이지를 ★★★ 에 기록 (GDD §4).
/// 완화: 게이지 상승 × (1 − 완화).
class CrowThief extends BossRule {
  CrowThief({
    required super.goalM,
    required super.timeScale,
    required BossSpec spec,
    required double ease,
  }) : stealPerSec = spec.crow35StealPerSec * (1 - ease),
       hitMeter = spec.crow35HitMeter * (1 - ease);

  final double stealPerSec;
  final double hitMeter;

  /// 대장이 모찌 뒤를 따라오는 거리 (화면 연출용, m).
  static const double followGapM = 6;

  double _meter = 0;
  double _lastRealSec = 0;
  int _crowHits = 0;
  double _x = 0;

  @override
  double get rivalXM => _x;

  @override
  double get meter => _meter;

  @override
  bool judge(FlightState s, RunStats stats) {
    final t = realSec(s);
    _meter += stealPerSec * (t - _lastRealSec);
    _lastRealSec = t;
    final hits = stats.hits(ObjectKind.crow.key);
    _meter += hitMeter * (hits - _crowHits);
    _crowHits = hits;
    _meter = math.min(1, _meter);
    _x = math.max(0, s.xM - followGapM);
    return _meter >= 1;
  }

  @override
  void onGoal(FlightState s, RunStats stats) => stats.bossMeterMax = _meter;
}
