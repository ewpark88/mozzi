import 'dart:math' as math;

import 'package:mozzi/domain/sim/flight_controls.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/landing.dart';

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

  /// 오브젝트 효과로 속도(와 높이)를 바꾼다 (공중에서만, P5). 튕기면 급강하가 끝난다.
  void redirect({double? vx, double? vy, double? y, bool endDive = false}) {
    if (!_airborne) return;
    if (endDive) _controls.onGround();
    _state = _copy(y: y, vx: vx, vy: vy);
  }

  /// 빨간 우산: [sec] 초 동안 완전 활공 (낙하 ≤ 수평 × [ratio], 감속 없음).
  void forceGlide({required double sec, required double ratio}) {
    if (!_airborne) return;
    _controls
      ..forcedGlideSec = sec
      ..forcedGlideRatio = ratio;
  }

  /// 급강하 시작 후 시간 (급강하 중이 아니면 null) — 퍼펙트 판정용.
  double? get diveElapsedSec =>
      _controls.diving ? _controls.diveElapsedSec : null;

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
    final ratio = _controls.glideRatio(params.controls.inflateGlideRatio);
    if (ratio != null) {
      final cap = ratio * _state.vxMps;
      if (_state.vyMps <= -cap) {
        _glide(dt, ratio);
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

  /// 활공: 낙하 속도 = 수평 속도 × [ratio] 로 일정.
  void _glide(double dt, double ratio) {
    final s = _state;
    final cap = ratio * s.vxMps;
    final yEnd = s.yM - cap * dt;
    if (yEnd > 0) {
      final vxEnd = _dragged(s.vxMps, dt);
      _state = _copy(
        x: s.xM + s.vxMps * dt + _controls.takeBoostDisplacement(dt),
        y: yEnd,
        vx: vxEnd,
        // 감속된 수평 속도 기준으로 상한을 다시 맞춘다
        vy: -ratio * vxEnd,
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
    final out = LandingOutcome.resolve(
      vxMps: vx,
      vyImpactMps: vyImpact,
      restitution: params.restitution,
      gravityMps2: params.gravityMps2,
      slideThresholdMps: slideThresholdMps,
    );
    _slideEndX = xHit + out.slideM;
    _slideDecel = out.slideDecel;
    _state = _copy(
      x: xHit,
      y: 0,
      vx: out.vxMps,
      vy: out.vyMps,
      time: time,
      bounces: _state.bounces + 1,
      maxHeight: maxHeight,
      phase: out.phase,
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
    final airborne = (phase ?? _state.phase) == FlightPhase.flying;
    return _state.copyWith(
      phase: phase,
      xM: x,
      yM: y,
      vxMps: vx,
      vyMps: vy,
      simTimeSec: time,
      bounces: bounces,
      maxHeightM: maxHeight,
      fuelSec: _controls.fuelSec,
      fuelMaxSec: _controls.fuelMaxSec,
      boosting: airborne && _controls.boosting,
      inflating: airborne && _controls.inflating,
      diving: airborne && _controls.diving,
    );
  }
}
