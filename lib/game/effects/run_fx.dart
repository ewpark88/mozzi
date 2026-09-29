import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mozzi/domain/run/object_interactor.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/effects/particle_effects.dart';
import 'package:mozzi/game/render/palette.dart';

/// 한 판의 연출 (파티클·햅틱). 게임 규칙과 무관하다.
class RunFx {
  RunFx(this.world);

  final World world;
  final math.Random _rnd = math.Random(7);

  void _add(Component fx) {
    final added = world.add(fx);
    if (added is Future<void>) unawaited(added);
  }

  /// PERFECT 발사 반짝이 + 진동 (GDD §2).
  void launch({required Vector2 at, required double r, required bool perfect}) {
    if (perfect) _add(ParticleEffects.perfectBurst(at, r, _rnd));
    unawaited(HapticFeedback.heavyImpact());
  }

  /// 부스터 분사 중 불꽃.
  void boosting(FlightState s, Vector2 at, double r) => _add(
    ParticleEffects.boostFlame(at, r, math.atan2(-s.vyMps, s.vxMps), _rnd),
  );

  /// 착지·튕김 먼지 퍼프 (GDD §3 이펙트: 부피감 있는 퍼프).
  void dust(FlightState s, double r) =>
      _add(ParticleEffects.dustPuff(Vector2(s.xM, 0), r, s.vxMps, _rnd));

  /// 오브젝트 적중 반짝 (씨앗 노랑), 급강하 퍼펙트는 진동.
  void hits(List<ObjectHit> hits, double mochiR) {
    for (final h in hits) {
      final o = h.object;
      final color = o.kind == ObjectKind.seed
          ? ObjectPalette.seed
          : GaugePalette.perfectBurst[1];
      _add(
        ParticleEffects.hitSparkle(
          Vector2(o.xM, -o.yM),
          mochiR * o.scale,
          color,
          _rnd,
        ),
      );
      if (h.divePerfect) unawaited(HapticFeedback.heavyImpact());
    }
  }

  /// 골 통과 폭죽 + 진동 (GDD §4 클리어 연출). [viewHeight] = 화면에 보이는 높이 (m).
  void goal(double goalM, double viewHeight) {
    _add(
      ParticleEffects.goalConfetti(
        Vector2(goalM, -viewHeight * 0.4),
        viewHeight * 0.4,
        _rnd,
      ),
    );
    unawaited(HapticFeedback.heavyImpact());
  }
}
