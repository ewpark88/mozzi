import 'dart:math' as math;
import 'dart:ui';

import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';
import 'package:mozzi/game/render/shaded_shapes.dart';

/// 오브젝트 2.5D 셰이딩 (GDD §3 오브젝트: 모찌와 같은 규칙 — 좌상단 광원 면 그라데이션,
/// 외곽선, 스페큘러, 림라이트. 풍선은 스페큘러 강하게, 씨앗은 광택 약하게).
/// 좌표: 월드 m (y 아래 +). 반지름 r = 오브젝트 반지름 (m).
class ObjectPainter {
  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// 스페큘러 세기 (GDD: 풍선 강 / 씨앗 약).
  static const double glossBalloon = .95;
  static const double glossSeed = .35;
  static const double glossDefault = .6;

  final ShadedShapes _shapes = ShadedShapes();

  /// 림라이트 색 (월드 조명).
  Color get rim => _shapes.rim;
  set rim(Color value) => _shapes.rim = value;

  void draw(
    Canvas c,
    ObjectKind kind,
    Offset at,
    double r, {
    int id = 0,
    double t = 0,
    double areaHeightM = 0,
  }) {
    switch (kind) {
      case ObjectKind.seed:
        _shapes.ball(c, at, r * .7, r, ObjectPalette.seed, gloss: glossSeed);
      case ObjectKind.tramp:
        _tramp(c, at.dx, r);
      case ObjectKind.clothesline:
        _clothesline(c, at, r);
      case ObjectKind.balloon:
        _balloon(c, at.translate(0, math.sin(t * 2 + id) * r * .2), r, id);
      case ObjectKind.fountain:
        _fountain(c, at.dx, r, areaHeightM, t);
      case ObjectKind.pigeon:
        _shapes.ball(
          c,
          at,
          r * 1.1,
          r * .7,
          ObjectPalette.pigeon,
          gloss: glossDefault,
        );
        _shapes.ball(
          c,
          at.translate(r * .75, -r * .35),
          r * .38,
          r * .38,
          ObjectPalette.pigeon,
          gloss: glossDefault,
        );
      case ObjectKind.updraft:
        _p.shader = Gradient.linear(
          Offset(at.dx, 0),
          Offset(at.dx, -areaHeightM),
          [
            Shade.alpha(ObjectPalette.updraft, .32 + .08 * math.sin(t * 5)),
            Shade.alpha(ObjectPalette.updraft, 0),
          ],
        );
        c.drawRect(
          Rect.fromLTWH(at.dx - r, -areaHeightM, r * 2, areaHeightM),
          _p,
        );
      case ObjectKind.umbrella:
        _umbrella(c, at, r);
      case ObjectKind.billboard:
        _shapes.panel(
          c,
          Rect.fromCenter(center: at, width: r * 2, height: r * 1.2),
          ObjectPalette.billboard,
        );
      case ObjectKind.branch:
        _shapes.stick(
          c,
          at.translate(-r, r * .3),
          at.translate(r, -r * .3),
          r * .25,
          ObjectPalette.branch,
        );
      case ObjectKind.wire:
        _shapes.stick(
          c,
          at.translate(-r * 2, 0),
          at.translate(r * 2, r * .3),
          r * .15,
          ObjectPalette.wire,
        );
      case ObjectKind.crow:
        _shapes.ball(c, at, r, r * .65, ObjectPalette.crow, gloss: .3);
    }
    _p.shader = null;
  }

  void _tramp(Canvas c, double x, double r) {
    for (final lx in [x - r * .85, x + r * .85]) {
      _shapes.stick(
        c,
        Offset(lx, 0),
        Offset(lx, -r * .38),
        r * .12,
        ObjectPalette.trampLeg,
      );
    }
    final bed = Rect.fromLTRB(x - r, -r * .5, x + r, -r * .3);
    _p.shader = Gradient.linear(bed.topCenter, bed.bottomCenter, [
      Shade.lit(ObjectPalette.tramp, .35),
      Shade.lit(ObjectPalette.tramp, -.25),
    ]);
    final rr = RRect.fromRectAndRadius(bed, Radius.circular(r * .1));
    c.drawRRect(rr, _p);
    _line
      ..color = Shade.lit(ObjectPalette.tramp, -.45)
      ..strokeWidth = r * .04;
    c.drawRRect(rr, _line);
    Shade.softSpot(
      c,
      _p,
      Offset(x - r * .3, -r * .46),
      r * .45,
      r * .05,
      MochiPalette.specular,
      .6,
    );
  }

  void _clothesline(Canvas c, Offset at, double r) {
    _line
      ..color = ObjectPalette.clothesline
      ..strokeWidth = r * .06;
    c.drawLine(at.translate(-r, 0), at.translate(r, r * .15), _line);
    _shapes.panel(
      c,
      Rect.fromLTWH(at.dx - r * .3, at.dy + r * .02, r * .5, r * .6),
      ObjectPalette.cloth,
    );
  }

  void _balloon(Canvas c, Offset at, double r, int id) {
    _line
      ..color = ObjectPalette.string
      ..strokeWidth = r * .05;
    c.drawLine(at.translate(0, r * 1.1), at.translate(0, r * 2.4), _line);
    _shapes.ball(
      c,
      at,
      r * .9,
      r * 1.1,
      id.isEven ? ObjectPalette.balloonRed : ObjectPalette.balloonYellow,
      gloss: glossBalloon,
    );
  }

  void _fountain(Canvas c, double x, double r, double h, double t) {
    final jet = Rect.fromLTWH(x - r * .35, -h, r * .7, h);
    _p.shader = Gradient.linear(jet.topCenter, jet.bottomCenter, [
      Shade.alpha(ObjectPalette.water, .15),
      Shade.alpha(ObjectPalette.water, .6 + .1 * math.sin(t * 9)),
    ]);
    c.drawRRect(RRect.fromRectAndRadius(jet, Radius.circular(r * .3)), _p);
    _shapes.panel(
      c,
      Rect.fromLTWH(x - r, -r * .32, r * 2, r * .32),
      ObjectPalette.stone,
    );
  }

  void _umbrella(Canvas c, Offset at, double r) {
    _line
      ..color = ObjectPalette.branch
      ..strokeWidth = r * .08;
    c.drawLine(at, at.translate(0, r * 1.1), _line);
    final dome = Rect.fromCircle(center: at, radius: r);
    _p.shader = Shade.radial(
      at.translate(-r * .4, -r * .6),
      r * .05,
      at,
      r * 1.2,
      [
        (0, Shade.lit(ObjectPalette.umbrella, .45)),
        (.5, ObjectPalette.umbrella),
        (1, Shade.lit(ObjectPalette.umbrella, -.3)),
      ],
    );
    c.drawArc(dome, math.pi, math.pi, true, _p);
    _line
      ..color = Shade.lit(ObjectPalette.umbrella, -.45)
      ..strokeWidth = r * .06;
    c.drawArc(dome, math.pi, math.pi, true, _line);
    Shade.softSpot(
      c,
      _p,
      at.translate(-r * .4, -r * .6),
      r * .35,
      r * .15,
      MochiPalette.specular,
      .7,
      rot: -.5,
    );
  }
}
