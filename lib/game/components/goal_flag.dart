import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/game/render/palette.dart';

/// 스테이지 골 깃발과 골 테이프 (GDD §4 클리어: 골 테이프가 끊어짐).
/// 월드 레이어. 크기는 목표 거리에 맞춰 키운다 (멀리 갈수록 카메라가 줌아웃).
class GoalFlag extends Component with HasGameReference {
  double? goalM;
  bool broken = false;

  final Paint _pole = Paint()..color = MochiPalette.outline;
  final Paint _flag = Paint()..color = ObjectPalette.goalFlag;
  final Paint _tape = Paint()
    ..color = ObjectPalette.goalTape
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final x = goalM;
    if (x == null) return;
    final view = game.camera.visibleWorldRect;
    if (x < view.left - 50 || x > view.right + 50) return;
    // 화면에서 대략 일정한 크기: 보이는 높이의 25%
    final h = view.height * 0.25;
    canvas
      ..drawRect(Rect.fromLTWH(x - h * 0.02, -h, h * 0.04, h), _pole)
      ..drawPath(
        Path()
          ..moveTo(x, -h)
          ..lineTo(x + h * 0.35, -h * 0.88)
          ..lineTo(x, -h * 0.76)
          ..close(),
        _flag,
      );
    _tape.strokeWidth = h * 0.02;
    if (broken) {
      canvas
        ..drawLine(Offset(x, -h * 0.45), Offset(x - h * 0.15, -h * 0.2), _tape)
        ..drawLine(
          Offset(x, -h * 0.45),
          Offset(x + h * 0.15, -h * 0.25),
          _tape,
        );
    } else {
      canvas.drawLine(Offset(x, -h * 0.45), Offset(x, 0), _tape);
    }
  }
}
