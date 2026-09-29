import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/domain/run/boss/boss_rule.dart';
import 'package:mozzi/domain/run/boss/cat_chase.dart';
import 'package:mozzi/domain/run/boss/crow_thief.dart';
import 'package:mozzi/domain/run/boss/pigeon_race.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/render/palette.dart';

/// 보스를 그릴 때 필요한 값 (게임이 구현).
abstract interface class BossSource {
  BossRule? get boss;
  FlightState get runState;
}

/// 보스 캐릭터 (GDD §4): 1-5 고양이(땅), 2-5 왕관 비둘기 대장(하늘), 3-5 까마귀 대장(모찌 뒤).
/// 단색 플레이스홀더 — 2.5D 렌더링은 P7.
class BossRival extends Component with HasGameReference {
  BossRival(this.source);

  final BossSource source;

  final Paint _cat = Paint()..color = BossPalette.cat;
  final Paint _pigeon = Paint()..color = ObjectPalette.pigeon;
  final Paint _crown = Paint()..color = BossPalette.crown;
  final Paint _crow = Paint()..color = BossPalette.crowBoss;
  final Paint _eye = Paint()..color = BossPalette.eye;

  @override
  void render(Canvas canvas) {
    final boss = source.boss;
    final x = boss?.rivalXM;
    if (boss == null || x == null) return;
    final view = game.camera.visibleWorldRect;
    if (x < view.left - 50 || x > view.right + 50) return;
    final r = view.height * 0.05;
    switch (boss) {
      case CatChase():
        _body(canvas, Offset(x, -r), r, _cat, ears: true);
      case PigeonRace():
        final c = Offset(x, -view.height * 0.35);
        _body(canvas, c, r, _pigeon);
        _drawCrown(canvas, c, r);
      case CrowThief():
        final y = source.runState.yM;
        _body(canvas, Offset(x, -(y + r * 1.5)), r * 0.9, _crow);
      default:
    }
  }

  void _body(Canvas canvas, Offset c, double r, Paint p, {bool ears = false}) {
    if (ears) {
      for (final side in const [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + side * r * 0.3, c.dy - r * 0.8)
            ..lineTo(c.dx + side * r * 0.9, c.dy - r * 1.4)
            ..lineTo(c.dx + side * r * 0.9, c.dy - r * 0.4)
            ..close(),
          p,
        );
      }
    }
    canvas
      ..drawCircle(c, r, p)
      ..drawCircle(c + Offset(r * 0.4, -r * 0.2), r * 0.12, _eye);
  }

  void _drawCrown(Canvas canvas, Offset c, double r) => canvas.drawPath(
    Path()
      ..moveTo(c.dx - r * 0.5, c.dy - r * 0.8)
      ..lineTo(c.dx - r * 0.5, c.dy - r * 1.4)
      ..lineTo(c.dx - r * 0.2, c.dy - r * 1.1)
      ..lineTo(c.dx, c.dy - r * 1.5)
      ..lineTo(c.dx + r * 0.2, c.dy - r * 1.1)
      ..lineTo(c.dx + r * 0.5, c.dy - r * 1.4)
      ..lineTo(c.dx + r * 0.5, c.dy - r * 0.8)
      ..close(),
    _crown,
  );
}
