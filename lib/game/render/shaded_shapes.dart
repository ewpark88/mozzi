import 'dart:math' as math;
import 'dart:ui';

import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// 2.5D 셰이딩 기본 도형 (GDD §3 셰이딩 규칙): 좌상단 광원 면 그라데이션·외곽선·
/// 림라이트·스페큘러. 오브젝트 그리기가 이 도형을 조합한다.
class ShadedShapes {
  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// 림라이트 색 (월드 조명).
  Color rim = MochiPalette.rimLight;

  /// 셰이딩된 타원 (면 그라데이션 → 외곽선 → 림라이트 → 스페큘러).
  void ball(
    Canvas c,
    Offset at,
    double rx,
    double ry,
    Color base, {
    required double gloss,
  }) {
    final r = math.max(rx, ry);
    _p.shader = Shade.radial(
      at + Offset(-rx * .45, -ry * .55),
      r * .05,
      at + Offset(-rx * .15, -ry * .15),
      r * 1.5,
      [
        (0, Shade.lit(base, .5)),
        (.45, base),
        (1, Shade.lit(base, -.3)),
      ],
    );
    final o = Shade.oval(at, rx, ry);
    c.drawOval(o, _p);
    _p.shader = Shade.radial(
      at + Offset(-rx * .5, -ry * .6),
      0,
      at + Offset(-rx * .5, -ry * .6),
      r * 2,
      [
        (0, Shade.alpha(rim, 0)),
        (.72, Shade.alpha(rim, 0)),
        (.95, Shade.alpha(rim, .55)),
      ],
    );
    c
      ..save()
      ..clipPath(Path()..addOval(o))
      ..drawRect(o.inflate(r), _p)
      ..restore();
    _line
      ..color = Shade.lit(base, -.45)
      ..strokeWidth = r * .09;
    c.drawOval(o, _line);
    Shade.softSpot(
      c,
      _p,
      at + Offset(-rx * .35, -ry * .45),
      rx * .45,
      ry * .25,
      MochiPalette.specular,
      gloss,
      rot: -.4,
    );
  }

  void panel(Canvas c, Rect rect, Color base) {
    _p.shader = Gradient.linear(rect.topLeft, rect.bottomRight, [
      Shade.lit(base, .35),
      Shade.lit(base, -.2),
    ]);
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height * .12),
    );
    c.drawRRect(rr, _p);
    _line
      ..color = Shade.lit(base, -.5)
      ..strokeWidth = rect.height * .05;
    c.drawRRect(rr, _line);
    Shade.softSpot(
      c,
      _p,
      rect.topLeft + Offset(rect.width * .3, rect.height * .25),
      rect.width * .25,
      rect.height * .12,
      MochiPalette.specular,
      .5,
    );
  }

  void stick(Canvas c, Offset a, Offset b, double w, Color base) {
    _line
      ..color = Shade.lit(base, -.35)
      ..strokeWidth = w * 1.25;
    c.drawLine(a, b, _line);
    _line
      ..color = base
      ..strokeWidth = w;
    c.drawLine(a, b, _line);
    _line
      ..color = Shade.lit(base, .35)
      ..strokeWidth = w * .3;
    c.drawLine(a.translate(0, -w * .2), b.translate(0, -w * .2), _line);
  }
}
