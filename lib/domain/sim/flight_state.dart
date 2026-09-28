import 'package:meta/meta.dart';

/// 비행 단계 (GDD §2: 발사 → 비행 → 착지 → 미끄러짐 → 정지).
enum FlightPhase {
  /// 발사 전.
  ready,

  /// 공중 (튀어 오른 뒤 포함).
  flying,

  /// 땅 위를 미끄러지는 중.
  sliding,

  /// 정지. 결과 화면으로 넘어간다.
  stopped,
}

/// 비행 시뮬의 한 순간 (불변). 좌표는 미터, 발사 지점 = (0, 0), y 는 위가 +.
@immutable
class FlightState {
  const FlightState({
    required this.phase,
    required this.xM,
    required this.yM,
    required this.vxMps,
    required this.vyMps,
    required this.simTimeSec,
    required this.bounces,
    required this.maxHeightM,
    this.fuelSec = 0,
    this.fuelMaxSec = 0,
    this.boosting = false,
    this.inflating = false,
    this.diving = false,
  });

  static const FlightState initial = FlightState(
    phase: FlightPhase.ready,
    xM: 0,
    yM: 0,
    vxMps: 0,
    vyMps: 0,
    simTimeSec: 0,
    bounces: 0,
    maxHeightM: 0,
  );

  final FlightPhase phase;
  final double xM;
  final double yM;
  final double vxMps;
  final double vyMps;

  /// 발사 후 흐른 시뮬 시간 (초, 시간 배율 적용 전).
  final double simTimeSec;

  /// 땅에 닿은 횟수.
  final int bounces;
  final double maxHeightM;

  /// 남은 부스터 연료 / 최대 연료 (시뮬 초). HUD 연료 게이지.
  final double fuelSec;
  final double fuelMaxSec;

  /// 조작 상태 (연출·HUD).
  final bool boosting;
  final bool inflating;
  final bool diving;

  /// 이번 판 거리 (m). 결과·씨앗 계산에 쓴다.
  double get distanceM => xM;

  bool get isAirborne => phase == FlightPhase.flying;
}
