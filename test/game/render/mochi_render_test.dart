import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/character/mochi_expression.dart';
import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/render/mochi/mochi_cache.dart';
import 'package:mozzi/game/render/mochi/mochi_face.dart';
import 'package:mozzi/game/render/mochi/mochi_painter.dart';
import 'package:mozzi/game/render/object_painter.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// GDD §3 2.5D 렌더링: 표정 9종·자세·저사양 경로가 모두 그려지고, 셰이딩 결과를 캐싱한다.
void main() {
  Canvas canvas() => Canvas(PictureRecorder());

  test('표정 9종 × 서기/비행 × 저사양 모두 예외 없이 그린다', () {
    final body = MochiBodyPainter();
    final face = MochiFace();
    for (final e in MochiExpression.values) {
      for (final fly in [false, true]) {
        for (final low in [false, true]) {
          final c = canvas();
          body.paint(
            c,
            fly: fly,
            cheek: 1.2,
            rim: MochiPalette.rimLight,
            lowSpec: low,
          );
          face.paint(c, e, t: 1.3, blink: true);
        }
      }
    }
  });

  test('저사양 모드는 털 질감을 끈다 (GDD §3 성능)', () {
    final body = MochiBodyPainter()
      ..paint(
        canvas(),
        fly: false,
        cheek: 1,
        rim: MochiPalette.rimLight,
        lowSpec: false,
      );
    expect(body.lastFurStrokes, MochiBodyPainter.furCount);
    body.paint(
      canvas(),
      fly: false,
      cheek: 1,
      rim: MochiPalette.rimLight,
      lowSpec: true,
    );
    expect(body.lastFurStrokes, 0);
  });

  group('셰이딩 캐시', () {
    test('같은 자세·볼·조명이면 다시 그리지 않는다', () {
      final cache = MochiBodyCache();
      addTearDown(cache.dispose);
      final a = cache.body(
        fly: false,
        cheek: 1,
        rim: MochiPalette.rimLight,
        lowSpec: false,
      );
      final b = cache.body(
        fly: false,
        cheek: 1.01,
        rim: MochiPalette.rimLight,
        lowSpec: false,
      );
      expect(identical(a, b), isTrue, reason: '볼 크기는 0.05 단계로 묶음');
      expect(cache.misses, 1);
      cache.body(
        fly: true,
        cheek: 1,
        rim: MochiPalette.rimLight,
        lowSpec: false,
      );
      final city = cache.body(
        fly: false,
        cheek: 1,
        rim: WorldPalette.city.rim,
        lowSpec: false,
      );
      expect(identical(city, a), isFalse);
      expect(cache.misses, 3);
    });

    test('항목 수 상한을 넘으면 오래된 것부터 버린다', () {
      final cache = MochiBodyCache(maxEntries: 3);
      addTearDown(cache.dispose);
      for (var i = 0; i < 6; i++) {
        cache.body(
          fly: false,
          cheek: 1 + i * .1,
          rim: MochiPalette.rimLight,
          lowSpec: false,
        );
      }
      expect(cache.size, 3);
    });
  });

  test('오브젝트 12종 모두 같은 셰이딩 규칙으로 그린다', () {
    final p = ObjectPainter()..rim = WorldPalette.park.rim;
    for (final k in ObjectKind.values) {
      p.draw(
        canvas(),
        k,
        const Offset(3, -2),
        .8,
        id: 3,
        t: .5,
        areaHeightM: 4,
      );
    }
  });

  test('lit: 양수는 밝게, 음수는 어둡게', () {
    const c = Color(0xFF808080);
    expect(Shade.lit(c, .5).r, greaterThan(c.r));
    expect(Shade.lit(c, -.5).r, lessThan(c.r));
    expect(Shade.lit(c, 0), c);
  });
}
