import 'dart:math' as math;

import 'package:mozzi/domain/sim/flight_controls.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

/// 결정론 비행 시뮬레이터 (ADR-001, ADR-012) + 비행 중 조작 3종 (GDD §2, P4).
///
/// 고정 시간 간격 [fixedDt] 로만 진행한다. 중력이 일정하므로 한 스텝 안의 위치를
/// 해석적으로 계산하고, 땅에 닿는 순간도 정확히 구해서 스텝 크기와 무관하게
/// 공식 거리와 일치한다. 튀는 높이가 작아지면 남은 튐 거리(등비급수의 나머지)를
/// 일정 감속 미끄러짐으로 이동해 “착지 → 미끄러짐 → 정지”를 만든다.
class FlightSimulator {
  FlightSimulator(this.params)
    : _controls = FlightControls(
        fuelMaxSec: params.fuelSec,
        tapSec: params.controls.boostTapSec,
        boostSpeedMps: params.boostSpeedMps,
      );

  /// 시뮬 1스텝 (초). 화면 프레임과 무관하다 (FixedStepper 가 나눠 호출).
  static const double fixedDt = 1 / 60;

  /// 튀어 오르는 수직 속도가 이보다 작으면 미끄러짐으로 전환 (m/s).
  static const double slideThresholdMps = 1;

  final FlightParams params;
  final FlightControls _controls;
  FlightState _state = FlightState.initial;

  /// 미끄러짐 목표 지점과 감속도.
  double _slideEndX = 0;
  double _slideDecel = 0;

  FlightState get state => _state;

  bool get _airborne => _state.phase == FlightPhase.flying;

  /// 발사. [angleRad] 는 지면 기준 발사 각(0~π/2), [speedMultiplier] 는
  /// 힘 × 정확도 배율 (GDD §2). 조작 없는 기준 발사 = 45°, 1.0.
  void launch({required double angleRad, double speedMultiplier = 1}) {
    if (_state.phase != FlightPhase.ready) {
      throw StateError('이미 발사됨: ${_state.phase}');
    }
    final v = params.launchSpeedMps * speedMultiplier;
    _state = _copy(
      phase: FlightPhase.flying,
      vx: v * math.cos(angleRad),
      vy: v * math.sin(angleRad),
    );
  }

  /// 부스터 탭 (공중에서만). 연료가 없으면 false.
  bool boostTap() {
    if (!_airborne || !_controls.tapBoost()) return false;
    _state = _copy();
    return true;
  }

  /// 볼 부풀리기 켜기/끄기 (켜기는 공중에서만, 급강하 중에는 안 됨).
  void setInflate({required bool on}) {
    if (on && (!_airborne || _controls.diving)) return;
    _controls.inflating = on;
    _state = _copy();
  }

  /// 급강하 (공중에서만): 낙하 속도를 수평 속도 × 비율 이상으로. 부풀리기는 풀린다.
  bool dive() {
    if (!_airborne) return false;
    _controls.startDive();
    final down = -params.controls.diveSpeedRatio * _state.vxMps;
    _state = _copy(vy: math.min(_state.vyMps, down));
    return true;
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

  /// [dt] 초 진행. 착지로 한 스텝이 쪼개지면 남은 시간을 이어서 진행한다.
  void _advance(double dt) {
    switch (_state.phase) {
      case FlightPhase.ready:
      case FlightPhase.stopped:
        return;
      case FlightPhase.flying:
        _controls.tick(dt);
        _stepFlying(dt);
      case FlightPhase.sliding:
        _stepSliding(dt);
    }
  }

  /// 공중 진행. 볼 부풀리기 중이면 낙하 속도 상한에 닿는 순간을 기준으로 구간을 나눈다.
  void _stepFlying(double dt) {
    if (_controls.inflating) {
      final cap = params.controls.inflateGlideRatio * _state.vxMps;
      if (_state.vyMps <= -cap) {
        _glide(dt, cap);
        return;
      }
      final tCap = (_state.vyMps + cap) / params.gravityMps2;
      if (tCap < dt) {
        _ballistic(tCap);
        if (_airborne) _stepFlying(dt - tCap);
        return;
      }
    }
    _ballistic(dt);
  }

  /// 중력 포물선 구간 (해석적). 땅에 닿으면 착지 처리 후 남은 시간을 이어 간다.
  void _ballistic(double dt) {
    final g = params.gravityMps2;
    final s = _state;
    final yEnd = s.yM + s.vyMps * dt - 0.5 * g * dt * dt;
    if (yEnd > 0) {
      _state = _copy(
        x: s.xM + s.vxMps * dt + _controls.takeBoostDisplacement(dt),
        y: yEnd,
        vx: _dragged(s.vxMps, dt),
        vy: s.vyMps - g * dt,
        time: s.simTimeSec + dt,
        maxHeight: math.max(s.maxHeightM, _apex(s)),
      );
      return;
    }
    // 이번 구간 안에서 땅(y = 0)에 닿는 시각: y + vy·t − ½g·t² = 0 의 양의 근
    final tHit = (s.vyMps + math.sqrt(s.vyMps * s.vyMps + 2 * g * s.yM)) / g;
    _land(
      xHit: s.xM + s.vxMps * tHit + _controls.takeBoostDisplacement(tHit),
      vx: _dragged(s.vxMps, tHit),
      vyImpact: s.vyMps - g * tHit,
      time: s.simTimeSec + tHit,
      maxHeight: math.max(s.maxHeightM, _apex(s)),
    );
    final remaining = dt - tHit;
    if (remaining > 0) _advance(remaining);
  }

  /// 볼 부풀리기 활공: 낙하 속도 = 상한 [cap] 로 일정.
  void _glide(double dt, double cap) {
    final s = _state;
    final yEnd = s.yM - cap * dt;
    if (yEnd > 0) {
      final vxEnd = _dragged(s.vxMps, dt);
      _state = _copy(
        x: s.xM + s.vxMps * dt + _controls.takeBoostDisplacement(dt),
        y: yEnd,
        vx: vxEnd,
        // 감속된 수평 속도 기준으로 상한을 다시 맞춘다
        vy: -params.controls.inflateGlideRatio * vxEnd,
        time: s.simTimeSec + dt,
      );
      return;
    }
    final tHit = s.yM / cap;
    _land(
      xHit: s.xM + s.vxMps * tHit + _controls.takeBoostDisplacement(tHit),
      vx: _dragged(s.vxMps, tHit),
      vyImpact: -cap,
      time: s.simTimeSec + tHit,
      maxHeight: s.maxHeightM,
    );
    final remaining = dt - tHit;
    if (remaining > 0) _advance(remaining);
  }

  /// 볼 부풀리기 중 수평 감속 (지수 감쇠).
  double _dragged(double vx, double dt) => _controls.inflating
      ? vx * math.exp(-params.controls.inflateDragPerSec * dt)
      : vx;

  void _land({
    required double xHit,
    required double vx,
    required double vyImpact,
    required double time,
    required double maxHeight,
  }) {
    _controls.onGround();
    final e = params.restitution;
    final vxOut = vx * e;
    final vyOut = -vyImpact * e;
    final bounces = _state.bounces + 1;
    if (vyOut >= slideThresholdMps) {
      _state = _copy(
        x: xHit,
        y: 0,
        vx: vxOut,
        vy: vyOut,
        time: time,
        bounces: bounces,
        maxHeight: maxHeight,
      );
      return;
    }
    // 남은 튐 거리 = Σ (2·vx·vy/g)·e^(2k) = (2·vx·vy/g) / (1 − e²)
    final tail = (2 * vxOut * vyOut / params.gravityMps2) / (1 - e * e);
    if (tail <= 0 || vxOut <= 0) {
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
    _slideDecel = vxOut * vxOut / (2 * tail);
    _state = _copy(
      x: xHit,
      y: 0,
      vx: vxOut,
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
  }) {
    final p = phase ?? _state.phase;
    final airborne = p == FlightPhase.flying;
    return FlightState(
      phase: p,
      xM: x ?? _state.xM,
      yM: y ?? _state.yM,
      vxMps: vx ?? _state.vxMps,
      vyMps: vy ?? _state.vyMps,
      simTimeSec: time ?? _state.simTimeSec,
      bounces: bounces ?? _state.bounces,
      maxHeightM: maxHeight ?? _state.maxHeightM,
      fuelSec: _controls.fuelSec,
      fuelMaxSec: _controls.fuelMaxSec,
      boosting: airborne && _controls.boosting,
      inflating: airborne && _controls.inflating,
      diving: airborne && _controls.diving,
    );
  }
}
