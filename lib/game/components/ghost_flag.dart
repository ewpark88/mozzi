import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/game/render/palette.dart';

/// 고스트 깃발: 이 스테이지 직전 최고 기록 지점 (GDD §2 콤보와 착지). 반투명한 작은 깃발.
class GhostFlag extends Component with HasGameReference {
  double? xM;

  final Paint _pole = Paint()..color = BossPalette.ghostPole;
  final Paint _flag = Paint()..color = BossPalette.ghostFlag;

  @override
  void render(Canvas canvas) {
    final x = xM;
    if (x == null || x <= 0) return;
    final view = game.camera.visibleWorldRect;
    if (x < view.left - 50 || x > view.right + 50) return;
    final h = view.height * 0.16;
    canvas
      ..drawRect(Rect.fromLTWH(x - h * 0.02, -h, h * 0.04, h), _pole)
      ..drawPath(
        Path()
          ..moveTo(x, -h)
          ..lineTo(x - h * 0.3, -h * 0.9)
          ..lineTo(x, -h * 0.8)
          ..close(),
        _flag,
      );
  }
}
