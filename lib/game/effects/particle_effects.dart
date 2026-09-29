import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// 파티클 연출 모음 (월드 좌표 = m, 크기는 모찌 반지름 `r`(m) 기준).
/// 반짝이는 가산 블렌딩 글로우, 먼지는 부피감 있는 퍼프 (GDD §3 이펙트).
abstract final class ParticleEffects {
  /// 가산 블렌딩으로 빛나는 점: 가운데 흰빛 → [color] → 투명, 수명 동안 사라짐.
  static Particle glow(double radius, Color color) {
    final paint = Paint()..blendMode = BlendMode.plus;
    return ComputedParticle(
      renderer: (canvas, particle) {
        final fade = 1 - particle.progress;
        paint.shader = Shade.radial(Offset.zero, 0, Offset.zero, radius, [
          (0, Shade.alpha(const Color(0xFFFFFFFF), fade)),
          (.35, Shade.alpha(color, .9 * fade)),
          (1, Shade.alpha(color, 0)),
        ]);
        canvas.drawCircle(Offset.zero, radius, paint);
      },
    );
  }

  /// 착지 먼지: 부드러운 방사형 퍼프가 커지며 옅어진다 (샘플 dust).
  static ParticleSystemComponent dustPuff(
    Vector2 at,
    double r,
    double vx,
    math.Random rnd,
  ) {
    final paint = Paint();
    return ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: 6,
        lifespan: 0.6,
        generator: (i) {
          final size = r * (0.25 + rnd.nextDouble() * 0.25);
          return AcceleratedParticle(
            position: Vector2((rnd.nextDouble() - 0.5) * r, 0),
            speed: Vector2(
              (rnd.nextDouble() - 0.5) * r * 3 + vx * 0.15,
              -r * (1 + rnd.nextDouble() * 3),
            ),
            acceleration: Vector2(0, r * 4),
            child: ComputedParticle(
              renderer: (canvas, p) {
                final k = p.progress;
                final rr = size * (1 + k);
                paint.shader = Shade.radial(
                  Offset(-rr * .3, -rr * .3),
                  0,
                  Offset.zero,
                  rr,
                  [
                    (0, Shade.alpha(FxPalette.dust, .8 * (1 - k))),
                    (.6, Shade.alpha(FxPalette.dust, .5 * (1 - k))),
                    (1, Shade.alpha(FxPalette.dust, 0)),
                  ],
                );
                canvas.drawCircle(Offset.zero, rr, paint);
              },
            ),
          );
        },
      ),
    );
  }

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
            child: glow(r * 0.3, colors[i % colors.length]),
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

  /// 골 통과 폭죽 (GDD §4 클리어 연출). [size] 는 화면에 보이는 크기 기준 (m).
  static ParticleSystemComponent goalConfetti(
    Vector2 at,
    double size,
    math.Random rnd,
  ) {
    const colors = ObjectPalette.confetti;
    return ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: 40,
        lifespan: 1.4,
        generator: (i) {
          final a = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.6;
          final v = size * (1.5 + rnd.nextDouble());
          return AcceleratedParticle(
            speed: Vector2(math.cos(a) * v, math.sin(a) * v),
            acceleration: Vector2(0, size * 1.5),
            child: CircleParticle(
              radius: size * 0.03,
              paint: Paint()..color = colors[i % colors.length],
            ),
          );
        },
      ),
    );
  }

  /// 오브젝트 적중 반짝 (씨앗은 노랑, 그 외 흰색).
  static ParticleSystemComponent hitSparkle(
    Vector2 at,
    double r,
    Color color,
    math.Random rnd,
  ) => ParticleSystemComponent(
    position: at.clone(),
    particle: Particle.generate(
      count: 8,
      lifespan: 0.4,
      generator: (i) {
        final a = rnd.nextDouble() * math.pi * 2;
        final v = r * (3 + rnd.nextDouble() * 3);
        return AcceleratedParticle(
          speed: Vector2(math.cos(a) * v, math.sin(a) * v),
          child: glow(r * 0.25, color),
        );
      },
    ),
  );
}
