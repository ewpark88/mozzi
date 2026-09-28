import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:mozzi/game/render/palette.dart';

/// 거리 표지 (월드 레이어). 줌에 따라 간격을 10·50·100·500·1000m 로 바꿔
/// 화면에서 겹치지 않게 한다. 글자는 화면 크기가 일정하도록 줌을 되돌려 그린다.
class DistanceMarkers extends Component with HasGameReference {
  static const List<double> _stepsM = [10, 50, 100, 500, 1000, 5000];

  /// 표지 사이 최소 화면 간격 (실제 px).
  static const double _minSpacingPx = 140;
  static const double _fontPx = 15;

  final Map<int, TextPainter> _labels = {};
  final Paint _post = Paint()..color = BackyardPalette.marker;

  double _stepFor(double zoom) => _stepsM.firstWhere(
    (s) => s * zoom >= _minSpacingPx,
    orElse: () => _stepsM.last,
  );

  TextPainter _label(int meters) => _labels.putIfAbsent(meters, () {
    return TextPainter(
      text: TextSpan(
        text: '${meters}m',
        style: const TextStyle(
          color: BackyardPalette.marker,
          fontSize: _fontPx,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });

  @override
  void render(Canvas canvas) {
    final zoom = game.camera.viewfinder.zoom;
    final view = game.camera.visibleWorldRect;
    final step = _stepFor(zoom);
    final first = ((view.left / step).ceil() * step).clamp(
      step,
      double.infinity,
    );
    final inv = 1 / zoom;
    for (var x = first; x < view.right; x += step) {
      canvas.drawRect(
        Rect.fromLTWH(x - 2 * inv, -18 * inv, 4 * inv, 18 * inv),
        _post,
      );
      final label = _label(x.round());
      canvas
        ..save()
        ..translate(x, -20 * inv)
        ..scale(inv)
        ..translate(-label.width / 2, -label.height);
      label.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }
}
