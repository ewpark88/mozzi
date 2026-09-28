import 'package:mozzi/domain/sim/flight_state.dart';

/// 땅에 닿은 뒤의 결과 (ADR-012): 다시 튀거나, 남은 튐 거리를 미끄러지거나, 멈춘다.
class LandingOutcome {
  const LandingOutcome({
    required this.phase,
    required this.vxMps,
    required this.vyMps,
    this.slideM = 0,
    this.slideDecel = 0,
  });

  /// 반발 계수 [restitution] 로 튄 결과. 튀는 수직 속도가 [slideThresholdMps] 보다 작으면
  /// 남은 튐 거리 합(등비급수 나머지) Σ(2·vx·vy/g)·e^(2k) = (2·vx·vy/g)/(1−e²) 를 미끄러진다.
  factory LandingOutcome.resolve({
    required double vxMps,
    required double vyImpactMps,
    required double restitution,
    required double gravityMps2,
    required double slideThresholdMps,
  }) {
    final e = restitution;
    final vx = vxMps * e;
    final vy = -vyImpactMps * e;
    if (vy >= slideThresholdMps) {
      return LandingOutcome(phase: FlightPhase.flying, vxMps: vx, vyMps: vy);
    }
    final tail = (2 * vx * vy / gravityMps2) / (1 - e * e);
    if (tail <= 0 || vx <= 0) {
      return const LandingOutcome(
        phase: FlightPhase.stopped,
        vxMps: 0,
        vyMps: 0,
      );
    }
    return LandingOutcome(
      phase: FlightPhase.sliding,
      vxMps: vx,
      vyMps: 0,
      slideM: tail,
      slideDecel: vx * vx / (2 * tail),
    );
  }

  final FlightPhase phase;
  final double vxMps;
  final double vyMps;

  /// 미끄러질 거리 (m)와 감속도 (m/s²).
  final double slideM;
  final double slideDecel;
}
