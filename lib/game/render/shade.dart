import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// 2.5D 셰이딩 도우미 (샘플 `모찌 런처 2.5D.html` 의 lit·rgba·radial·softSpot).
abstract final class Shade {
  /// [k] ≥ 0 이면 흰색 쪽으로 k 만큼 밝게, < 0 이면 (1 + k) 배로 어둡게.
  static Color lit(Color c, double k) {
    int ch(double v) => (v * 255).round().clamp(0, 255);
    final r = c.r;
    final g = c.g;
    final b = c.b;
    return k >= 0
        ? Color.fromARGB(
            ch(c.a),
            ch(r + (1 - r) * k),
            ch(g + (1 - g) * k),
            ch(b + (1 - b) * k),
          )
        : Color.fromARGB(
            ch(c.a),
            ch(r * (1 + k)),
            ch(g * (1 + k)),
            ch(b * (1 + k)),
          );
  }

  /// 같은 색, 투명도 [a] (0~1).
  static Color alpha(Color c, double a) => c.withValues(alpha: a.clamp(0, 1));

  /// 캔버스 createRadialGradient(시작 원 → 끝 원) 과 같은 방사형 그라데이션.
  static Shader radial(
    Offset from,
    double fromR,
    Offset to,
    double toR,
    List<(double, Color)> stops,
  ) => Gradient.radial(
    to,
    math.max(0.01, toR),
    [for (final s in stops) s.$2],
    [for (final s in stops) s.$1],
    TileMode.clamp,
    null,
    from,
    math.max(0, fromR),
  );

  /// 가장자리로 갈수록 투명해지는 부드러운 타원 점 (오클루전·하이라이트·홍조).
  static void softSpot(
    Canvas c,
    Paint p,
    Offset at,
    double rx,
    double ry,
    Color color,
    double a, {
    double rot = 0,
  }) {
    final x = math.max(0.5, rx);
    final y = math.max(0.5, ry);
    // Paint 색의 알파가 셰이더에 곱해지므로 불투명으로 둔다
    p
      ..color = const Color(0xFFFFFFFF)
      ..shader = radial(Offset.zero, 0, Offset.zero, x, [
        (0, alpha(color, a)),
        (1, alpha(color, 0)),
      ]);
    c
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(rot)
      ..scale(1, y / x)
      ..drawCircle(Offset.zero, x, p)
      ..restore();
    p.shader = null;
  }

  /// 중심 [c], 반지름 [rx]·[ry] 인 타원 사각형.
  static Rect oval(Offset c, double rx, double ry) =>
      Rect.fromCenter(center: c, width: rx.abs() * 2, height: ry.abs() * 2);

  /// 회전 타원을 경로에 추가.
  static void addOval(Path path, Offset c, double rx, double ry, double rot) {
    if (rot == 0) {
      path.addOval(oval(c, rx, ry));
      return;
    }
    final m = Matrix4Rotation.around(c, rot);
    path.addPath(Path()..addOval(oval(c, rx, ry)), Offset.zero, matrix4: m);
  }
}

/// 한 점을 중심으로 회전하는 4×4 행렬 (Path.addPath 용).
abstract final class Matrix4Rotation {
  static Float64List around(Offset c, double rot) {
    final cs = math.cos(rot);
    final sn = math.sin(rot);
    // 열 우선(column-major): translate(c) · rotate · translate(-c)
    return Float64List.fromList([
      cs, sn, 0, 0, //
      -sn, cs, 0, 0,
      0, 0, 1, 0,
      c.dx - cs * c.dx + sn * c.dy, c.dy - sn * c.dx - cs * c.dy, 0, 1,
    ]);
  }
}
