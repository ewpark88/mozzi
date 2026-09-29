import 'dart:math' as math;
import 'dart:ui';

import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// 모찌 몸 2.5D 셰이딩 (GDD §3 셰이딩 7단계, 샘플 drawMochi 의 2.5D 경로).
///
/// 좌표는 샘플 단위 (중심 0,0, 몸 가로 반지름 42). 얼굴은 MochiFace 가 위에 그린다.
/// 1 접지 그림자는 컴포넌트가 땅에 그린다. 여기서는 2~7:
/// 베이스 컬러·면 그라데이션(좌상단 45° 광원) → 앰비언트 오클루전 → 림라이트 →
/// 스페큘러 → 털 질감(저사양 끔). 외곽선은 3.6 (샘플 6 → 3~4, GDD 외곽선).
class MochiBodyPainter {
  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static const double bodyRx = 42;
  static const double bodyRy = 38;
  static const double outlineWidth = 3.6;
  static const double _earR = 12;
  static const double _earX = 24;
  static const double _earY = -31;

  /// 털 스트로크 수 (샘플 16). 저사양이면 0.
  static const int furCount = 16;

  /// 마지막으로 그린 털 스트로크 수 (테스트용).
  int lastFurStrokes = 0;

  /// [cheek] 볼 크기 배율(스프링, 1 = 기본), [rim] 월드 림라이트 색.
  void paint(
    Canvas c, {
    required bool fly,
    required double cheek,
    required Color rim,
    required bool lowSpec,
  }) {
    final parts = _silhouette(fly: fly, cheek: cheek);
    // 1) 얇은 외곽선: 모든 파츠를 먼저 긋고 채우면 안쪽 선은 가려진다
    _line
      ..color = MochiPalette.lineDeep
      ..strokeWidth = outlineWidth;
    for (final s in parts) {
      _ellipse(c, s, _line);
    }
    // 2~3) 베이스 컬러 + 좌상단 광원 면 그라데이션
    _p.shader = Shade.radial(
      const Offset(-18, -24),
      2,
      const Offset(-6, -6),
      64,
      [
        (0, Shade.lit(MochiPalette.body, .55)),
        (.42, MochiPalette.body),
        (1, Shade.lit(MochiPalette.body, -.26)),
      ],
    );
    for (final s in parts) {
      _ellipse(c, s, _p);
    }
    final clip = Path();
    for (final s in parts) {
      Shade.addOval(clip, s.center, s.rx, s.ry, s.rot);
    }
    c
      ..save()
      ..clipPath(clip);
    _patchAndShadow(c);
    _occlusion(c);
    _rimLight(c, rim);
    _specular(c);
    c.restore();
    _p.shader = null;
    lastFurStrokes = lowSpec ? 0 : _fur(c);
    _earsAndBlush(c, cheek);
    _paws(c, fly: fly);
    _nose(c);
  }

  List<_Part> _silhouette({required bool fly, required double cheek}) {
    final feet = fly
        ? const [(-22.0, 33.0, -.5), (22.0, 33.0, .5)]
        : const [(-15.0, 36.0, 0.0), (15.0, 36.0, 0.0)];
    return [
      const _Part(Offset(-_earX, _earY), _earR, _earR),
      const _Part(Offset(_earX, _earY), _earR, _earR),
      for (final f in feet) _Part(Offset(f.$1, f.$2), 10, 6, rot: f.$3),
      if (cheek > .3) ...[
        _Part(const Offset(-27, 9), 17 * cheek, 16 * cheek),
        _Part(const Offset(27, 9), 17 * cheek, 16 * cheek),
      ],
      const _Part(Offset.zero, bodyRx, bodyRy),
    ];
  }

  /// 등 무늬(같은 광원) + 코어 섀도(광원 반대쪽으로 어둡게).
  void _patchAndShadow(Canvas c) {
    _p.shader = Shade.radial(
      const Offset(-16, -40),
      2,
      const Offset(-4, -26),
      56,
      [
        (0, Shade.lit(MochiPalette.backPatch, .35)),
        (.5, MochiPalette.backPatch),
        (1, Shade.lit(MochiPalette.backPatch, -.3)),
      ],
    );
    c.drawOval(Shade.oval(const Offset(0, -40), 50, 26), _p);
    const shadow = MochiPalette.coreShadow;
    _p.shader = Shade.radial(
      const Offset(-18, -24),
      18,
      const Offset(-18, -24),
      84,
      [
        (0, Shade.alpha(shadow, 0)),
        (.5, Shade.alpha(shadow, 0)),
        (1, Shade.alpha(shadow, .55)),
      ],
    );
    c.drawRect(_square, _p);
  }

  /// 볼 아래·귀 뿌리·발 사이를 어둡게.
  void _occlusion(Canvas c) {
    const s = MochiPalette.coreShadow;
    Shade.softSpot(c, _p, const Offset(-20, 25), 16, 9, s, .38);
    Shade.softSpot(c, _p, const Offset(20, 25), 16, 9, s, .38);
    Shade.softSpot(c, _p, const Offset(-_earX * .9, _earY + 10), 10, 6, s, .3);
    Shade.softSpot(c, _p, const Offset(_earX * .9, _earY + 10), 10, 6, s, .3);
    Shade.softSpot(c, _p, const Offset(0, 38), 14, 7, s, .4);
  }

  /// 우하단 가장자리 반사광 (월드별 색).
  void _rimLight(Canvas c, Color rim) {
    _p.shader = Shade.radial(
      const Offset(-20, -24),
      0,
      const Offset(-20, -24),
      78,
      [
        (0, Shade.alpha(rim, 0)),
        (.76, Shade.alpha(rim, 0)),
        (.9, Shade.alpha(rim, .5)),
        (1, Shade.alpha(rim, .9)),
      ],
    );
    c.drawRect(_square, _p);
  }

  /// 이마·볼 하이라이트.
  void _specular(Canvas c) {
    const w = MochiPalette.specular;
    Shade.softSpot(c, _p, const Offset(-13, -23), 15, 8, w, .75, rot: -.35);
    Shade.softSpot(c, _p, const Offset(-31, 1), 7, 4.5, w, .55, rot: -.5);
    Shade.softSpot(c, _p, const Offset(22, 1), 6, 4, w, .4, rot: -.4);
  }

  /// 윗쪽 외곽의 짧고 옅은 털 스트로크 (결정론 길이).
  int _fur(Canvas c) {
    _line
      ..color = Shade.alpha(MochiPalette.lineDeep, .65)
      ..strokeWidth = 1.3;
    for (var i = 0; i < furCount; i++) {
      final a = math.pi * 1.12 + (i / (furCount - 1)) * math.pi * .76;
      final j = ((i * 37) % 7) / 7;
      final nx = math.cos(a);
      final ny = math.sin(a);
      final x = nx * bodyRx;
      final y = ny * bodyRy;
      final len = 1.6 + j * 1.2;
      c.drawLine(
        Offset(x - nx, y - ny),
        Offset(x + nx * len + ny * .8, y + ny * len - nx * .8),
        _line,
      );
    }
    return furCount;
  }

  /// 귀 안쪽(오목한 그라데이션) + 부드러운 볼 홍조.
  void _earsAndBlush(Canvas c, double cheek) {
    for (final ex in const [-_earX, _earX]) {
      _p.shader = Shade.radial(
        Offset(ex + 2, _earY + 3),
        1,
        Offset(ex, _earY + 1),
        _earR * .6,
        [
          (0, Shade.lit(MochiPalette.earInner, -.15)),
          (1, Shade.lit(MochiPalette.earInner, .2)),
        ],
      );
      c.drawOval(
        Shade.oval(Offset(ex, _earY + 1), _earR * .56, _earR * .56),
        _p,
      );
    }
    _p.shader = null;
    final bs = 9 * (cheek < .7 ? .7 : cheek);
    Shade.softSpot(
      c,
      _p,
      const Offset(-26, 10),
      bs,
      5.5,
      MochiPalette.blushSoft,
      .7,
    );
    Shade.softSpot(
      c,
      _p,
      const Offset(26, 10),
      bs,
      5.5,
      MochiPalette.blushSoft,
      .7,
    );
  }

  void _paws(Canvas c, {required bool fly}) {
    final paws = fly
        ? const [(-45.0, -8.0, -.6), (45.0, -8.0, .6)]
        : const [(-16.0, 28.0, .3), (16.0, 28.0, -.3)];
    _line
      ..color = MochiPalette.lineDeep
      ..strokeWidth = 2.6;
    for (final (x, y, rot) in paws) {
      c
        ..save()
        ..translate(x, y)
        ..rotate(rot);
      _p.shader = Shade.radial(const Offset(-2.5, -2.5), .5, Offset.zero, 8, [
        (0, Shade.lit(MochiPalette.body, .5)),
        (1, Shade.lit(MochiPalette.body, -.15)),
      ]);
      final r = Shade.oval(Offset.zero, 6.5, 5);
      c
        ..drawOval(r, _p)
        ..drawOval(r, _line)
        ..restore();
    }
    _p.shader = null;
  }

  void _nose(Canvas c) {
    _p.color = MochiPalette.nose;
    c.drawPath(
      Path()
        ..moveTo(-3.5, 4)
        ..lineTo(3.5, 4)
        ..lineTo(0, 8)
        ..close(),
      _p,
    );
    _p.color = Shade.alpha(MochiPalette.specular, .8);
    c.drawOval(Shade.oval(const Offset(-1, 5), 1.2, .8), _p);
    _p.color = const Color(0xFF000000);
  }

  void _ellipse(Canvas c, _Part s, Paint p) {
    if (s.rot == 0) {
      c.drawOval(Shade.oval(s.center, s.rx, s.ry), p);
      return;
    }
    c
      ..save()
      ..translate(s.center.dx, s.center.dy)
      ..rotate(s.rot)
      ..drawOval(Shade.oval(Offset.zero, s.rx, s.ry), p)
      ..restore();
  }

  static const Rect _square = Rect.fromLTWH(-80, -80, 160, 160);
}

class _Part {
  const _Part(this.center, this.rx, this.ry, {this.rot = 0});

  final Offset center;
  final double rx;
  final double ry;
  final double rot;
}
