import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 카메라 위치를 읽어 배경 레이어를 스크롤하는 쪽 (MozziGame 이 구현).
abstract interface class ParallaxSource {
  /// 카메라 초점 월드 x (m).
  double get cameraFocusXM;

  /// 현재 줌 (실제 px / m).
  double get cameraZoom;

  /// 지금 배경 색 (다음 월드 경계 100m 전부터 섞임, GDD §4 배치 규칙).
  WorldPalette get backdropPalette;

  /// 저사양 모드: 대기 원근 안개·해 글로우 끔 (GDD §3 성능).
  bool get lowSpec;
}

/// 배경 5레이어 중 뒤쪽 4개 (GDD §3 배경, 샘플 drawBg):
/// 하늘(+해) → 원경 산(0.08, 대기 원근 안개) → 구름(0.15) → 중경 언덕(0.3) →
/// 근경 덤불·울타리(0.45·0.6). 5번째 전경 풀잎은 [ForegroundGrass].
/// 샘플 가상 좌표(높이 540)로 그린다. 멀수록 흐리고 채도가 낮고 밝게.
class ParallaxBackdrop extends Component with HasGameReference {
  ParallaxBackdrop(this.source);

  final ParallaxSource source;

  static const double _vh = VirtualViewport.virtualHeight;
  static const List<(double, double, double)> _cloudPuffs = [
    (0, 0, 34),
    (30, -12, 28),
    (58, 0, 30),
    (28, 8, 30),
  ];

  /// 셰이더를 칠하기 전 색 (Paint 색의 알파가 셰이더에 곱해지므로 불투명으로).
  static const Color _opaque = Color(0xFFFFFFFF);

  final Paint _p = Paint()..isAntiAlias = true;
  final Paint _line = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    if (size.y <= 0) return;
    final s = size.y / _vh;
    final vw = size.x / s;
    const gy = _vh * VirtualViewport.groundLineRatio;
    final cam = source.cameraFocusXM * source.cameraZoom / s;
    final l = source.backdropPalette;
    final low = source.lowSpec;
    canvas
      ..save()
      ..scale(s);
    _sky(canvas, vw, l, low);
    _mountains(canvas, vw, gy, cam, l, low);
    _clouds(canvas, vw, cam, l, low);
    _hills(canvas, vw, gy, cam, l, low);
    _bushes(canvas, vw, gy, cam, l);
    _fence(canvas, vw, gy, cam, l);
    canvas.restore();
  }

  void _sky(Canvas c, double vw, WorldPalette l, bool low) {
    _p.color = _opaque;
    _p.shader = Gradient.linear(Offset.zero, const Offset(0, _vh), [
      l.skyTop,
      l.skyBottom,
    ]);
    c.drawRect(Rect.fromLTWH(0, 0, vw, _vh), _p);
    final sun = Offset(vw * .82, 80);
    if (!low) {
      _p
        ..color = _opaque
        ..shader = Shade.radial(sun, 10, sun, 190, [
          (0, Shade.alpha(l.sun, .55)),
          (1, Shade.alpha(l.sun, 0)),
        ]);
      c.drawCircle(sun, 190, _p);
    }
    _p
      ..shader = null
      ..color = Shade.alpha(l.sun, .95);
    c.drawCircle(sun, 38, _p);
  }

  void _mountains(
    Canvas c,
    double vw,
    double gy,
    double cam,
    WorldPalette l,
    bool low,
  ) {
    final my = gy - 110;
    final path = Path()..moveTo(0, _vh);
    for (var x = 0.0; x <= vw + 30; x += 30) {
      final wx = x + cam * .08;
      path.lineTo(
        x,
        my - math.sin(wx / 260).abs() * 70 - math.sin(wx / 97) * 12,
      );
    }
    path
      ..lineTo(vw, _vh)
      ..close();
    _p
      ..shader = null
      ..color = l.far;
    c.drawPath(path, _p);
    if (low) return;
    // 지평선 안개 (대기 원근)
    _p.color = _opaque;
    _p.shader = Gradient.linear(Offset(0, my - 90), Offset(0, gy), [
      Shade.alpha(l.skyBottom, 0),
      Shade.alpha(l.skyBottom, .55),
    ]);
    c.drawRect(Rect.fromLTWH(0, my - 90, vw, _vh), _p);
  }

  void _clouds(Canvas c, double vw, double cam, WorldPalette l, bool low) {
    const spacing = 420.0;
    final scroll = cam * .15;
    final first = (scroll / spacing).floor() - 1;
    for (var i = first; i <= first + (vw / spacing).ceil() + 2; i++) {
      final x = i * spacing - scroll;
      final y = 70.0 + ((i * 97) % 90).abs();
      for (final (dx, dy, r) in _cloudPuffs) {
        final at = Offset(x + dx * .9, y + dy * .9);
        final rr = r * .9;
        if (!low) {
          _p
            ..shader = null
            ..color = Shade.alpha(l.cloudShade, .9);
          c.drawOval(Shade.oval(at + const Offset(2, 5), rr, rr * .8), _p);
        }
        _p.color = _opaque;
        _p.shader = low
            ? null
            : Shade.radial(at + Offset(-rr * .35, -rr * .4), 1, at, rr * 1.05, [
                (0, const Color(0xFFFFFFFF)),
                (.7, const Color(0xF5FAFCFF)),
                (1, Shade.alpha(l.cloudShade, .9)),
              ]);
        if (low) _p.color = const Color(0xEBFFFFFF);
        c.drawOval(Shade.oval(at, rr, rr * .8), _p);
      }
    }
  }

  void _hills(
    Canvas c,
    double vw,
    double gy,
    double cam,
    WorldPalette l,
    bool low,
  ) {
    final hy = gy - 60;
    final path = Path()..moveTo(0, _vh);
    for (var x = 0.0; x <= vw + 20; x += 20) {
      final wx = x + cam * .3;
      path.lineTo(x, hy + math.sin(wx / 170) * 18 + math.sin(wx / 63) * 6);
    }
    path
      ..lineTo(vw, _vh)
      ..close();
    _p.color = _opaque;
    _p.shader = Gradient.linear(Offset(0, hy - 30), Offset(0, hy + 120), [
      Shade.lit(l.mid, .12),
      l.midDeep,
    ]);
    c.drawPath(path, _p);
    if (low) return;
    _p
      ..shader = null
      ..color = Shade.alpha(l.skyBottom, .22);
    c.drawRect(Rect.fromLTWH(0, hy - 40, vw, _vh), _p);
  }

  void _bushes(Canvas c, double vw, double gy, double cam, WorldPalette l) {
    final by = gy - 24;
    final off = (cam * .45) % 150;
    for (var x = -off - 150; x < vw + 150; x += 150) {
      for (final (dx, dy, r) in const [
        (0.0, 0.0, 26.0),
        (24.0, -8.0, 22.0),
        (46.0, 2.0, 24.0),
      ]) {
        final at = Offset(x + dx, by + dy);
        _p.color = _opaque;
        _p.shader = Shade.radial(at + const Offset(-8, -10), 2, at, r + 4, [
          (0, Shade.lit(l.near, .28)),
          (1, Shade.lit(l.near, -.18)),
        ]);
        c.drawOval(Shade.oval(at, r, r * .8), _p);
      }
    }
  }

  void _fence(Canvas c, double vw, double gy, double cam, WorldPalette l) {
    final fy = gy - 18;
    final off = (cam * .6) % 36;
    _p
      ..shader = null
      ..color = l.fence;
    c
      ..drawRect(Rect.fromLTWH(0, fy - 34, vw, 6), _p)
      ..drawRect(Rect.fromLTWH(0, fy - 16, vw, 6), _p);
    _line
      ..color = Shade.lit(l.fence, -.35)
      ..strokeWidth = 1.5;
    for (var x = -off - 36; x < vw + 36; x += 36) {
      _p.color = _opaque;
      _p.shader = Gradient.linear(Offset(x, 0), Offset(x + 14, 0), [
        Shade.lit(l.fence, .25),
        Shade.lit(l.fence, -.18),
      ]);
      final post = Path()
        ..moveTo(x, fy)
        ..lineTo(x, fy - 44)
        ..lineTo(x + 7, fy - 52)
        ..lineTo(x + 14, fy - 44)
        ..lineTo(x + 14, fy)
        ..close();
      c
        ..drawPath(post, _p)
        ..drawPath(post, _line);
    }
    _p
      ..shader = null
      ..color = const Color(0x29283C1E);
    c.drawRect(Rect.fromLTWH(0, fy - 2, vw, 8), _p);
  }
}

/// 배경 5번째 레이어: 카메라 앞을 지나가는 전경 풀잎 (깊이감, GDD §3 배경).
class ForegroundGrass extends Component with HasGameReference {
  ForegroundGrass(this.source);

  final ParallaxSource source;

  static const double _factor = 1.25;
  static const double _spacingPx = 70;

  final Paint _paint = Paint()
    ..color = BackyardPalette.grassDark
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    _paint.strokeWidth = size.y * 0.012;
    final scroll = source.cameraFocusXM * source.cameraZoom * _factor;
    final shift = scroll % _spacingPx;
    for (var x = -shift; x < size.x + _spacingPx; x += _spacingPx) {
      final tuft = ((x + scroll) / _spacingPx).round() % 3;
      final hPx = size.y * (0.05 + 0.02 * tuft);
      canvas
        ..drawLine(
          Offset(x, size.y),
          Offset(x - hPx * 0.2, size.y - hPx),
          _paint,
        )
        ..drawLine(
          Offset(x + 8, size.y),
          Offset(x + 12, size.y - hPx * 0.8),
          _paint,
        );
    }
  }
}
