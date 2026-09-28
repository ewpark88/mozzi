import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mozzi/domain/balance/launch_spec.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';

/// 당기기 단계.
enum PullPhase { idle, pulling }

/// 발사 결정 (놓은 순간 확정).
@immutable
class LaunchDecision {
  const LaunchDecision({
    required this.angleRad,
    required this.power,
    required this.judgement,
    required this.speedMultiplier,
  });

  /// 지면 기준 발사 각 (0 ~ 최대 각).
  final double angleRad;

  /// 힘 (0 ~ 1.1).
  final double power;
  final GaugeJudgement judgement;

  /// 비행 시뮬에 넘길 발사 속도 배율 = (힘 × 판정 배율)^지수 (ADR-013).
  final double speedMultiplier;

  /// 거리 배율 (속도 배율의 제곱).
  double get distanceMultiplier => speedMultiplier * speedMultiplier;
}

/// 당기기 → 게이지 → 놓기 → 발사 결정 (GDD §2 당기기와 정확도 게이지).
///
/// 입력 좌표는 가상 화면 px (x 오른쪽, y 아래 +). 화면 아무 곳이나 누른 채 끌면
/// 누른 지점 기준 드래그 벡터의 반대 방향으로 날아간다 (2.5D 샘플과 같음).
class LaunchController {
  LaunchController(this.spec) : gauge = AccuracyGauge(spec);

  final LaunchSpec spec;
  final AccuracyGauge gauge;

  PullPhase _phase = PullPhase.idle;
  double _startX = 0;
  double _startY = 0;
  double _pullX = 0;
  double _pullY = 0;

  PullPhase get phase => _phase;

  /// 누른 지점 기준 당긴 벡터 (가상 px, 최대 길이로 잘림).
  (double, double) get pull => (_pullX, _pullY);

  /// 힘 (0 ~ [LaunchSpec.maxPower]).
  double get power {
    final len = math.sqrt(_pullX * _pullX + _pullY * _pullY);
    return math.min(1, len / spec.pullMaxPx) * spec.maxPower;
  }

  /// 늘어남 정도 0~1 (모찌 변형·고무 소리 음높이용).
  double get stretch => power / spec.maxPower;

  bool get isOvercharged => power > 1;

  void start(double x, double y) {
    _phase = PullPhase.pulling;
    _startX = x;
    _startY = y;
    _pullX = 0;
    _pullY = 0;
    gauge.reset();
  }

  void move(double x, double y) {
    if (_phase != PullPhase.pulling) return;
    var dx = x - _startX;
    var dy = y - _startY;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > spec.pullMaxPx) {
      dx *= spec.pullMaxPx / len;
      dy *= spec.pullMaxPx / len;
    }
    _pullX = dx;
    _pullY = dy;
  }

  /// 당기는 동안 바늘을 움직인다 (실제 시간).
  void update(double realDt) {
    if (_phase == PullPhase.pulling) gauge.advance(realDt, power);
  }

  /// 놓기. 힘이 [LaunchSpec.minPower] 미만이면 취소(null).
  LaunchDecision? release() {
    if (_phase != PullPhase.pulling) return null;
    _phase = PullPhase.idle;
    final p = power;
    if (p < spec.minPower) return null;
    final judgement = gauge.judge(gauge.needle);
    return LaunchDecision(
      angleRad: launchAngle(_pullX, _pullY),
      power: p,
      judgement: judgement,
      speedMultiplier: math
          .pow(p * judgement.multiplier, spec.speedExponent)
          .toDouble(),
    );
  }

  void cancel() => _phase = PullPhase.idle;

  /// 당긴 벡터의 반대 방향 각 (지면 기준, 위가 +). 앞으로만 날도록 0°~최대 각으로 제한.
  double launchAngle(double pullX, double pullY) {
    // 화면 y 는 아래가 + → 발사 방향 = (−pullX, pullY) 를 수학 좌표로
    final angle = math.atan2(pullY, -pullX);
    final maxRad = spec.maxAngleDeg * math.pi / 180;
    // 아래쪽으로 향하면 수평(0°), 뒤로 넘어가면 최대 각
    if (angle < 0) return 0;
    return math.min(angle, maxRad);
  }
}
