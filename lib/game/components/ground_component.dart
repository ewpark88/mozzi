import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/game/render/palette.dart';

/// 지면 (월드 레이어). 카메라에 보이는 범위만 그린다. y = 0 이 지표면.
class GroundComponent extends Component with HasGameReference {
  GroundComponent({required this.grassDepthM, required this.bladeSpacingM});

  /// 풀 띠 두께 (m).
  final double grassDepthM;

  /// 풀잎 간격 (m).
  final double bladeSpacingM;

  static const double _soilDepthM = 400;

  final Paint _grass = Paint()..color = BackyardPalette.grass;
  final Paint _soil = Paint()..color = BackyardPalette.soil;
  final Paint _blade = Paint()
    ..color = BackyardPalette.grassDark
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final left = view.left - 1;
    final right = view.right + 1;
    canvas
      ..drawRect(Rect.fromLTRB(left, 0, right, grassDepthM), _grass)
      ..drawRect(Rect.fromLTRB(left, grassDepthM, right, _soilDepthM), _soil);
    _blade.strokeWidth = bladeSpacingM * 0.06;
    final start = (left / bladeSpacingM).floor() * bladeSpacingM;
    for (var x = start; x < right; x += bladeSpacingM) {
      canvas.drawLine(
        Offset(x, grassDepthM * 0.1),
        Offset(x - bladeSpacingM * 0.09, -grassDepthM * 0.3),
        _blade,
      );
    }
  }
}
