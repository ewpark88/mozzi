import 'dart:math' as math;
import 'dart:ui';

import 'package:mozzi/domain/character/mochi_expression.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// 모찌 얼굴 9종 (GDD §3 표정 9종, 샘플 drawFace·eyeDot). 좌표는 샘플 단위.
class MochiFace {
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static const double _l = -14;
  static const double _r = 14;
  static const double _y = -4;

  /// [t] 애니메이션 시간(초, 어질 눈 회전), [blink] 기본 표정 눈 감기.
  void paint(
    Canvas c,
    MochiExpression expr, {
    double t = 0,
    bool blink = false,
  }) {
    _line
      ..color = MochiPalette.eye
      ..strokeWidth = 2.6;
    switch (expr) {
      case MochiExpression.idle:
        if (blink) {
          for (final x in const [_l, _r]) {
            _stroke(
              c,
              Path()
                ..moveTo(x - 5, _y)
                ..quadraticBezierTo(x, _y + 3, x + 5, _y),
            );
          }
        } else {
          _eye(c, _l, _y, 5.4);
          _eye(c, _r, _y, 5.4);
        }
        _wMouth(c);
      case MochiExpression.expect:
        _eye(c, _l, _y - 1, 6.2);
        _eye(c, _r, _y - 1, 6.2);
        _oval(c, const Offset(0, 13), 4, 4.6, MochiPalette.mouth);
      case MochiExpression.tense:
        _chevrons(c, 5);
        _stroke(
          c,
          Path()
            ..moveTo(-6, 13)
            ..lineTo(6, 13),
        );
        _oval(c, const Offset(34, -16), 3, 4.5, MochiPalette.sweat);
      case MochiExpression.joy:
        _chevrons(c, 4);
        _openMouth(c, 24);
        _oval(c, const Offset(0, 16), 3.6, 2.4, MochiPalette.tongue);
      case MochiExpression.puff:
        _eye(c, _l, _y - 2, 5);
        _eye(c, _r, _y - 2, 5);
        c.drawCircle(const Offset(0, 12), 2.6, _line);
      case MochiExpression.dizzy:
        _spirals(c, t);
        final zig = Path()..moveTo(-7, 13);
        for (var i = 0; i <= 4; i++) {
          zig.lineTo(-7 + i * 3.5, 13 + (i.isOdd ? -2 : 2));
        }
        _stroke(c, zig);
      case MochiExpression.flat:
        for (final x in const [_l, _r]) {
          _stroke(
            c,
            Path()
              ..moveTo(x - 6, _y)
              ..lineTo(x + 6, _y),
          );
        }
        _stroke(
          c,
          Path()
            ..moveTo(-8, 12)
            ..lineTo(8, 12),
        );
      case MochiExpression.proud:
        _star(c, const Offset(_l, _y), 8);
        _star(c, const Offset(_r, _y), 8);
        _openMouth(c, 20, half: 7);
      case MochiExpression.determined:
        _determined(c);
    }
  }

  void _stroke(Canvas c, Path p) => c.drawPath(p, _line);

  void _oval(Canvas c, Offset at, double rx, double ry, Color color) {
    _fill
      ..shader = null
      ..color = color;
    c.drawOval(Shade.oval(at, rx, ry), _fill);
  }

  void _wMouth(Canvas c) => _stroke(
    c,
    Path()
      ..moveTo(-6, 11)
      ..quadraticBezierTo(-3, 15, 0, 11)
      ..quadraticBezierTo(3, 15, 6, 11),
  );

  /// 눈 질끈 (><). [h] = 위아래 벌어짐.
  void _chevrons(Canvas c, double h) {
    _stroke(
      c,
      Path()
        ..moveTo(_l - 6, _y - h)
        ..lineTo(_l + 3, _y)
        ..lineTo(_l - 6, _y + h),
    );
    _stroke(
      c,
      Path()
        ..moveTo(_r + 6, _y - h)
        ..lineTo(_r - 3, _y)
        ..lineTo(_r + 6, _y + h),
    );
  }

  void _openMouth(Canvas c, double depth, {double half = 8}) {
    _fill
      ..shader = null
      ..color = MochiPalette.mouth;
    c.drawPath(
      Path()
        ..moveTo(-half, 10)
        ..quadraticBezierTo(0, depth, half, 10)
        ..close(),
      _fill,
    );
  }

  /// 광택 있는 눈동자 (2.5D eyeDot).
  void _eye(Canvas c, double x, double y, double r) {
    _fill.shader = Shade.radial(
      Offset(x, y + r * .4),
      0,
      Offset(x, y),
      r * 1.1,
      const [
        (0, MochiPalette.pupilCore),
        (.6, MochiPalette.pupilMid),
        (1, MochiPalette.pupilEdge),
      ],
    );
    c.drawOval(Shade.oval(Offset(x, y), r, r * 1.08), _fill);
    _fill
      ..shader = null
      ..color = MochiPalette.specular;
    c
      ..drawOval(
        Shade.oval(Offset(x - r * .32, y - r * .4), r * .42, r * .42),
        _fill,
      )
      ..drawOval(
        Shade.oval(Offset(x + r * .38, y + r * .32), r * .18, r * .18),
        _fill,
      );
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = MochiPalette.eyeGlint;
    c.drawArc(
      Rect.fromCircle(center: Offset(x, y), radius: r * .72),
      .3,
      1.2,
      false,
      glint,
    );
  }

  void _spirals(Canvas c, double t) {
    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? _l : _r;
      final dir = i == 0 ? -1 : 1;
      final p = Path();
      for (var a = 0.0; a < math.pi * 4; a += .3) {
        final r = .9 * a * .75;
        final pt = Offset(
          x + math.cos(a + t * 8 * dir) * r,
          _y + math.sin(a + t * 8 * dir) * r,
        );
        a == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      _stroke(c, p);
    }
  }

  void _star(Canvas c, Offset at, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isOdd ? r * .45 : r;
      final pt = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    _fill
      ..shader = null
      ..color = MochiPalette.starEye;
    c.drawPath(p, _fill);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = MochiPalette.starEyeLine;
    c.drawPath(p, line);
  }

  void _determined(Canvas c) {
    _eye(c, _l, _y, 5);
    _eye(c, _r, _y, 5);
    _stroke(
      c,
      Path()
        ..moveTo(_l - 7, _y - 11)
        ..lineTo(_l + 5, _y - 7),
    );
    _stroke(
      c,
      Path()
        ..moveTo(_r + 7, _y - 11)
        ..lineTo(_r - 5, _y - 7),
    );
    _stroke(
      c,
      Path()
        ..moveTo(-5, 13)
        ..quadraticBezierTo(0, 10, 5, 13),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = MochiPalette.snortLine;
    _fill
      ..shader = null
      ..color = MochiPalette.snort;
    for (final (x, y, r) in const [
      (-12.0, 16.0, 4.0),
      (-18.0, 19.0, 3.0),
      (12.0, 16.0, 4.0),
      (18.0, 19.0, 3.0),
    ]) {
      final o = Shade.oval(Offset(x, y), r, r * .8);
      c
        ..drawOval(o, _fill)
        ..drawOval(o, ring);
    }
  }
}
