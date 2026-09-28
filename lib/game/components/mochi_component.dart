import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/render/palette.dart';

/// 모찌 플레이스홀더 (단색 파츠: 몸통·등 무늬·볼·눈). P7 에서 2.5D 셰이딩으로 교체.
///
/// 위치는 비행 시뮬 상태를 그대로 따른다. 착지 찌그러짐은 시각 전용 스프링
/// (게임 판정에 영향 없음, GDD §3 말랑 표현).
class MochiComponent extends PositionComponent {
  MochiComponent({required this.radiusM})
    : super(anchor: Anchor.center, size: Vector2.all(radiusM * 2));

  /// 몸통 반지름 (m). 2.5D 샘플 RAD 38px 을 기본 카메라 배율로 환산한 값.
  final double radiusM;

  static const double _springK = 180;
  static const double _springDamping = 14;
  static const double _landingSquash = -0.35;

  double _squash = 0;
  double _squashV = 0;
  int _seenBounces = 0;
  double _spin = 0;

  final Paint _body = Paint()..color = MochiPalette.body;
  final Paint _patch = Paint()..color = MochiPalette.backPatch;
  final Paint _blush = Paint()
    ..color = MochiPalette.blush.withValues(alpha: 0.8);
  final Paint _eye = Paint()..color = MochiPalette.eye;
  final Paint _outline = Paint()
    ..color = MochiPalette.outline
    ..style = PaintingStyle.stroke;

  /// 시뮬 상태를 반영한다 (월드 좌표: x 오른쪽, y 아래가 +).
  void syncFrom(FlightState s) {
    position.setValues(s.xM, -(s.yM + radiusM));
    if (s.bounces > _seenBounces) {
      _seenBounces = s.bounces;
      _squash = _landingSquash;
      _squashV = 0;
    }
    if (s.phase == FlightPhase.ready) {
      _seenBounces = 0;
      _spin = 0;
    }
    angle = s.isAirborne ? _spin : 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _squashV += (-_springK * _squash - _springDamping * _squashV) * dt;
    _squash += _squashV * dt;
    _spin += dt * 2.2;
  }

  @override
  void render(Canvas canvas) {
    final r = radiusM;
    final c = Offset(r, r);
    // 찌그러짐: 세로로 눌리면 가로로 퍼진다 (부피 유지 근사)
    final sy = 1 + _squash;
    final sx = 1 / math.max(sy, 0.4);
    canvas
      ..save()
      ..translate(c.dx, c.dy + r * (1 - sy))
      ..scale(sx, sy);
    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: r * 2.1,
      height: r * 2,
    );
    _outline.strokeWidth = r * 0.09;
    canvas
      ..drawOval(bodyRect, _body)
      ..drawArc(
        bodyRect.deflate(r * 0.05),
        math.pi * 1.05,
        math.pi * 0.7,
        false,
        _patch..style = PaintingStyle.fill,
      )
      ..drawOval(bodyRect, _outline)
      ..drawCircle(Offset(-r * 0.55, r * 0.25), r * 0.28, _blush)
      ..drawCircle(Offset(r * 0.55, r * 0.25), r * 0.28, _blush)
      ..drawCircle(Offset(-r * 0.32, -r * 0.05), r * 0.11, _eye)
      ..drawCircle(Offset(r * 0.32, -r * 0.05), r * 0.11, _eye)
      ..restore();
  }
}
