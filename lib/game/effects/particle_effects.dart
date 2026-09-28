import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';
import 'package:mozzi/game/render/palette.dart';

/// 파티클 연출 모음 (월드 좌표 = m, 크기는 모찌 반지름 `r`(m) 기준).
abstract final class ParticleEffects {
  /// PERFECT 발사: 노랑·흰 반짝이가 사방으로 (GDD §2 “이펙트와 진동”).
  static ParticleSystemComponent perfectBurst(
    Vector2 at,
    double r,
    math.Random rnd,
  ) {
    const colors = GaugePalette.perfectBurst;
    return ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: 18,
        lifespan: 0.6,
        generator: (i) {
          final a = rnd.nextDouble() * math.pi * 2;
          final v = r * (5 + rnd.nextDouble() * 5);
          return AcceleratedParticle(
            speed: Vector2(math.cos(a) * v, math.sin(a) * v),
            acceleration: Vector2(0, r * 8),
            child: CircleParticle(
              radius: r * 0.12,
              paint: Paint()..color = colors[i % colors.length],
            ),
          );
        },
      ),
    );
  }

  /// 부스터 불꽃: 진행 방향 반대로 뿜는 노랑·주황·빨강 (2.5D 샘플 fire).
  /// [headingRad] 는 모찌 진행 방향 (월드 좌표, y 아래 +).
  static ParticleSystemComponent boostFlame(
    Vector2 at,
    double r,
    double headingRad,
    math.Random rnd,
  ) {
    const colors = FxPalette.fire;
    return ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: 3,
        lifespan: 0.35,
        generator: (i) {
          final a = headingRad + math.pi + (rnd.nextDouble() - 0.5) * 0.7;
          final v = r * (6 + rnd.nextDouble() * 5);
          return AcceleratedParticle(
            position: Vector2(math.cos(a) * r * 0.8, math.sin(a) * r * 0.8),
            speed: Vector2(math.cos(a) * v, math.sin(a) * v + r * 3),
            child: CircleParticle(
              radius: r * (0.1 + rnd.nextDouble() * 0.1),
              paint: Paint()..color = colors[i % colors.length],
            ),
          );
        },
      ),
    );
  }
}
