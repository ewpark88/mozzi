import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/game/render/palette.dart';

/// 카메라 위치를 읽어 배경 레이어를 스크롤하는 쪽 (MozziGame 이 구현).
abstract interface class ParallaxSource {
  /// 카메라 초점 월드 x (m).
  double get cameraFocusXM;

  /// 현재 줌 (실제 px / m).
  double get cameraZoom;

  /// 지금 배경 색 (다음 월드 경계 100m 전부터 섞임, GDD §4 배치 규칙).
  WorldPalette get backdropPalette;
}

/// 배경 5레이어 중 뒤쪽 4개: 하늘 + 원경·중경·근경 (GDD §3 배경 5레이어).
/// 5번째 전경 풀잎은 [ForegroundGrass]. 월드(지면·모찌)는 그 사이에 그려진다.
/// P2 는 단색 코드 도형 플레이스홀더, P7 에서 대기 원근·조명으로 교체.
class ParallaxBackdrop extends Component with HasGameReference {
  ParallaxBackdrop(this.source);

  final ParallaxSource source;

  /// (스크롤 비율, 화면 높이 대비 기준선, 언덕 높이 비율)
  static const List<(double, double, double)> _layers = [
    (0.05, 0.62, 0.22),
    (0.15, 0.70, 0.16),
    (0.35, 0.78, 0.10),
  ];

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final palette = source.backdropPalette;
    final colors = [palette.far, palette.mid, palette.near];
    final sky = Rect.fromLTWH(0, 0, size.x, size.y);
    _paint.shader = Gradient.linear(
      Offset.zero,
      Offset(0, size.y),
      [palette.skyTop, palette.skyBottom],
    );
    canvas.drawRect(sky, _paint);
    _paint.shader = null;
    final scrollPx = source.cameraFocusXM * source.cameraZoom;
    for (var i = 0; i < _layers.length; i++) {
      final (factor, base, amp) = _layers[i];
      _paint.color = colors[i];
      canvas.drawPath(
        _hills(size.x, size.y, scrollPx * factor, base, amp, i),
        _paint,
      );
    }
  }

  /// 결정론 언덕 실루엣 (사인 합). [offsetPx] 만큼 왼쪽으로 흘러간다.
  Path _hills(
    double w,
    double h,
    double offsetPx,
    double base,
    double amp,
    int seed,
  ) {
    final path = Path()..moveTo(0, h);
    const stepPx = 12.0;
    for (var x = 0.0; x <= w + stepPx; x += stepPx) {
      final u = (x + offsetPx) / h;
      final y =
          h * base -
          h *
              amp *
              (0.55 +
                  0.3 * math.sin(u * 2.1 + seed) +
                  0.15 * math.sin(u * 5.3 + seed * 2));
      path.lineTo(x, y);
    }
    return path
      ..lineTo(w, h)
      ..close();
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
