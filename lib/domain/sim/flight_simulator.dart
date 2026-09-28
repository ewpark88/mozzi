import 'dart:math' as math;

import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

/// 결정론 비행 시뮬레이터 (ADR-001, ADR-012).
///
/// 고정 시간 간격 [fixedDt] 로만 진행한다. 중력이 일정하므로 한 스텝 안의 위치를
/// 해석적으로 계산하고, 땅에 닿는 순간도 정확히 구해서 스텝 크기와 무관하게
/// 공식 거리와 일치한다. 튀는 높이가 작아지면 남은 튐 거리(등비급수의 나머지)를
/// 일정 감속 미끄러짐으로 이동해 “착지 → 미끄러짐 → 정지”를 만든다.
class FlightSimulator {
  FlightSimulator(this.params);

  /// 시뮬 1스텝 (초). 화면 프레임과 무관하다 (FixedStepper 가 나눠 호출).
  static const double fixedDt = 1 / 60;

  /// 튀어 오르는 수직 속도가 이보다 작으면 미끄러짐으로 전환 (m/s).
  static const double slideThresholdMps = 1;

  final FlightParams params;
  FlightState _state = FlightState.initial;

  /// 미끄러짐 목표 지점과 감속도.
  double _slideEndX = 0;
  double _slideDecel = 0;

  FlightState get state => _state;

  /// 발사. [angleRad] 는 지면 기준 발사 각(0~π/2), [speedMultiplier] 는
  /// 힘 × 정확도 배율 (GDD §2, P3). 조작 없는 기준 발사 = 45°, 1.0.
  void launch({required double angleRad, double speedMultiplier = 1}) {
    if (_state.phase != FlightPhase.ready) {
      throw StateError('이미 발사됨: ${_state.phase}');
    }
    final v = params.launchSpeedMps * speedMultiplier;
    _state = FlightState(
      phase: FlightPhase.flying,
      xM: 0,
      yM: 0,
      vxMps: v * math.cos(angleRad),
      vyMps: v * math.sin(angleRad),
      simTimeSec: 0,
      bounces: 0,
      maxHeightM: 0,
    );
  }

  /// [fixedDt] 만큼 진행한다. 정지 후에는 아무것도 하지 않는다.
  void step() => _advance(fixedDt);

  /// 정지할 때까지 돌린다 (헤드리스 테스트·보정용). 스텝 수 상한으로 무한 루프 방지.
  FlightState runToStop({int maxSteps = 60 * 60 * 10}) {
    for (var i = 0; i < maxSteps && _state.phase != FlightPhase.stopped; i++) {
      step();
    }
    return _state;
  }

  void _stepFlying(double dt) {
    final g = params.gravityMps2;
    final s = _state;
    final yEnd = s.yM + s.vyMps * dt - 0.5 * g * dt * dt;
    if (yEnd > 0) {
      final vy = s.vyMps - g * dt;
      _state = _copy(
        x: s.xM + s.vxMps * dt,
        y: yEnd,
        vy: vy,
        time: s.simTimeSec + dt,
        maxHeight: math.max(s.maxHeightM, _apex(s)),
      );
      return;
    }
    // 이번 스텝 안에서 땅(y = 0)에 닿는 시각: y + vy·t − ½g·t² = 0 의 양의 근
    final tHit = (s.vyMps + math.sqrt(s.vyMps * s.vyMps + 2 * g * s.yM)) / g;
    final vyImpact = s.vyMps - g * tHit;
    _land(
      xHit: s.xM + s.vxMps * tHit,
      vyImpact: vyImpact,
      time: s.simTimeSec + tHit,
      maxHeight: math.max(s.maxHeightM, _apex(s)),
    );
    final remaining = dt - tHit;
    if (remaining > 0) _advance(remaining);
  }

  /// [dt] 초 진행. 착지로 한 스텝이 쪼개지면 남은 시간을 이어서 진행한다.
  void _advance(double dt) {
    switch (_state.phase) {
      case FlightPhase.ready:
      case FlightPhase.stopped:
        return;
      case FlightPhase.flying:
        _stepFlying(dt);
      case FlightPhase.sliding:
        _stepSliding(dt);
    }
  }

  void _land({
    required double xHit,
    required double vyImpact,
    required double time,
    required double maxHeight,
  }) {
    final e = params.restitution;
    final vx = _state.vxMps * e;
    final vy = -vyImpact * e;
    final bounces = _state.bounces + 1;
    if (vy >= slideThresholdMps) {
      _state = _copy(
        x: xHit,
        y: 0,
        vx: vx,
        vy: vy,
        time: time,
        bounces: bounces,
        maxHeight: maxHeight,
      );
      return;
    }
    // 남은 튐 거리 = Σ (2·vx·vy/g)·e^(2k) = (2·vx·vy/g) / (1 − e²)
    final tail = (2 * vx * vy / params.gravityMps2) / (1 - e * e);
    if (tail <= 0 || vx <= 0) {
      _state = _copy(
        x: xHit,
        y: 0,
        vx: 0,
        vy: 0,
        time: time,
        bounces: bounces,
        maxHeight: maxHeight,
        phase: FlightPhase.stopped,
      );
      return;
    }
    _slideEndX = xHit + tail;
    _slideDecel = vx * vx / (2 * tail);
    _state = _copy(
      x: xHit,
      y: 0,
      vx: vx,
      vy: 0,
      time: time,
      bounces: bounces,
      maxHeight: maxHeight,
      phase: FlightPhase.sliding,
    );
  }

  void _stepSliding(double dt) {
    final s = _state;
    final vxEnd = s.vxMps - _slideDecel * dt;
    if (vxEnd <= 0) {
      _state = _copy(
        x: _slideEndX,
        vx: 0,
        time: s.simTimeSec + dt,
        phase: FlightPhase.stopped,
      );
      return;
    }
    _state = _copy(
      x: math.min(
        s.xM + s.vxMps * dt - 0.5 * _slideDecel * dt * dt,
        _slideEndX,
      ),
      vx: vxEnd,
      time: s.simTimeSec + dt,
    );
  }

  double _apex(FlightState s) =>
      s.vyMps > 0 ? s.yM + s.vyMps * s.vyMps / (2 * params.gravityMps2) : s.yM;

  FlightState _copy({
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? time,
    int? bounces,
    double? maxHeight,
    FlightPhase? phase,
  }) => FlightState(
    phase: phase ?? _state.phase,
    xM: x ?? _state.xM,
    yM: y ?? _state.yM,
    vxMps: vx ?? _state.vxMps,
    vyMps: vy ?? _state.vyMps,
    simTimeSec: time ?? _state.simTimeSec,
    bounces: bounces ?? _state.bounces,
    maxHeightM: maxHeight ?? _state.maxHeightM,
  );
}
