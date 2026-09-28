import 'dart:math' as math;

import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/world_spec.dart';
import 'package:mozzi/domain/run/run_stats.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';

/// 오브젝트 적중 이벤트 (연출용).
class ObjectHit {
  const ObjectHit(this.object, {this.divePerfect = false});

  final WorldObject object;
  final bool divePerfect;
}

/// 모찌와 오브젝트의 충돌과 효과 (GDD §4 월드 테마, 시트 「오브젝트」 값1~3).
///
/// 땅 오브젝트(트램폴린·분수·상승기류)는 모찌 x 가 폭 안에 있고 높이 조건이 맞을 때,
/// 공중 오브젝트는 원끼리 겹칠 때 맞는다. 장애물은 감속만 하고 비행을 끝내지 않는다.
class ObjectInteractor {
  ObjectInteractor({
    required this.config,
    required this.field,
    required this.stats,
  });

  final BalanceConfig config;
  final ObjectField field;
  final RunStats stats;

  /// 트램폴린 판 높이 (m, ×배율). 샘플 26px.
  static const double padTopM = 0.5;

  /// 분수 물줄기 높이 (m, ×배율).
  static const double fountainJetM = 6;

  final Set<int> _enteredAreas = {};

  double get _r => config.mochiRadiusM;

  /// 한 스텝 진행 후: 충돌을 찾아 효과를 준다. 이번 스텝의 적중 목록.
  List<ObjectHit> afterStep(FlightSimulator sim, double dt) {
    final s = sim.state;
    if (s.phase != FlightPhase.flying) return const [];
    final hits = <ObjectHit>[];
    final range = 4 * config.world.spawn.scaleAt(s.xM) + _r * 2;
    for (final o in field.near(s.xM, range).toList()) {
      final spec = config.world.object(o.kind);
      final hit = _touches(sim.state, o, spec, dt, sim.params.gravityMps2);
      if (!hit) continue;
      final result = _apply(sim, o, spec, dt);
      if (result != null) hits.add(result);
    }
    return hits;
  }

  bool _touches(
    FlightState s,
    WorldObject o,
    ObjectSpec spec,
    double dt,
    double gravity,
  ) {
    final r = spec.radiusM * o.scale;
    final dx = (s.xM - o.xM).abs();
    switch (o.kind) {
      case ObjectKind.tramp:
        // 위에서 내려오다 다음 스텝에 판 높이 아래로 들어오면 (중력 포함 예측) 지금 튕긴다
        final yNext = s.yM + s.vyMps * dt - 0.5 * gravity * dt * dt;
        return s.vyMps < 0 && dx <= r && yNext <= padTopM * o.scale;
      case ObjectKind.fountain:
        return dx <= r && s.yM <= fountainJetM * o.scale;
      case ObjectKind.updraft:
        return dx <= r && s.yM <= spec.p2 * o.scale;
      case ObjectKind.seed ||
          ObjectKind.clothesline ||
          ObjectKind.balloon ||
          ObjectKind.pigeon ||
          ObjectKind.umbrella ||
          ObjectKind.billboard ||
          ObjectKind.branch ||
          ObjectKind.wire ||
          ObjectKind.crow:
        final dy = s.yM + _r - o.yM;
        return math.sqrt(dx * dx + dy * dy) < _r + r;
    }
  }

  ObjectHit? _apply(
    FlightSimulator sim,
    WorldObject o,
    ObjectSpec spec,
    double dt,
  ) {
    final s = sim.state;
    final speed = math.sqrt(s.vxMps * s.vxMps + s.vyMps * s.vyMps);
    if (o.kind == ObjectKind.updraft) {
      // 영역: 안에 있는 동안 계속 위로 가속, 미션 적중은 들어갈 때 한 번
      sim.redirect(vy: s.vyMps + spec.p1 * dt);
      if (_enteredAreas.add(o.id)) {
        stats.recordHit(o.kind.key, obstacle: false);
        return ObjectHit(o);
      }
      return null;
    }
    field.markUsed(o.id);
    var divePerfect = false;
    switch (spec.category) {
      case ObjectCategory.pickup:
        stats.addSeeds(spec.p1.round());
      case ObjectCategory.bounce:
        if (s.vyMps >= 0) return null; // 아래에서 닿으면 튕기지 않음
        var up = math.max(spec.p1 * -s.vyMps, spec.p2);
        final dive = sim.diveElapsedSec;
        if (dive != null) {
          up *= config.controls.diveBounceMult;
          if (dive <= config.controls.divePerfectWindowSec) {
            up *= config.controls.divePerfectMult;
            divePerfect = true;
            stats.divePerfects++;
          }
        }
        sim.redirect(vx: s.vxMps * spec.p3, vy: up, endDive: true);
      case ObjectCategory.lift:
        sim.redirect(
          vx: s.vxMps + spec.p3,
          vy: math.max(s.vyMps, math.max(spec.p1, spec.p2 * speed)),
        );
      case ObjectCategory.boost:
        sim.redirect(vx: s.vxMps * spec.p1, vy: math.max(s.vyMps, spec.p2));
      case ObjectCategory.glide:
        sim.forceGlide(sec: spec.p1, ratio: spec.p2);
      case ObjectCategory.seeds:
        stats.addSeeds(spec.p1.round());
        sim.redirect(vx: s.vxMps * (1 - spec.p2));
      case ObjectCategory.obstacle:
        _obstacle(sim, o.kind, spec);
      case ObjectCategory.area:
        break;
    }
    stats.recordHit(
      o.kind.key,
      obstacle: spec.category == ObjectCategory.obstacle,
    );
    return ObjectHit(o, divePerfect: divePerfect);
  }

  void _obstacle(FlightSimulator sim, ObjectKind kind, ObjectSpec spec) {
    final s = sim.state;
    sim.redirect(
      vx: s.vxMps * (1 - spec.p1),
      vy: kind == ObjectKind.wire ? s.vyMps - spec.p2 : null,
    );
    if (kind == ObjectKind.crow) stats.stealSeeds(spec.p2.round());
  }
}
