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

  /// 당기기 변형: 당긴 방향(라디안, 월드 좌표)·늘어남 0~1·과충전 떨림.
  double _pullAngle = 0;
  double _stretch = 0;
  bool _trembling = false;
  double _clock = 0;

  /// 비행 조작 연출 (GDD §3 빵빵 표정·§2 급강하). 0~1 로 부드럽게 전환.
  double _puff = 0;
  double _dive = 0;
  bool _inflating = false;
  bool _diving = false;

  final Paint _body = Paint()..color = MochiPalette.body;
  final Paint _patch = Paint()..color = MochiPalette.backPatch;
  final Paint _blush = Paint()
    ..color = MochiPalette.blush.withValues(alpha: 0.8);
  final Paint _eye = Paint()..color = MochiPalette.eye;
  final Paint _outline = Paint()
    ..color = MochiPalette.outline
    ..style = PaintingStyle.stroke;

  /// 당기는 중 변형 (GDD §2 “드래그 거리만큼 늘어남”). [offsetXM]/[offsetYM] 은 당긴 쪽으로
  /// 끌려간 위치 (월드 m, y 아래 +). 샘플처럼 당긴 벡터의 절반만큼 따라간다.
  void setPull({
    required double offsetXM,
    required double offsetYM,
    required double stretch,
    required bool trembling,
  }) {
    _stretch = stretch;
    _trembling = trembling;
    if (stretch > 0) {
      _pullAngle = math.atan2(offsetYM, offsetXM);
      final shake = trembling ? math.sin(_clock * 70) * radiusM * 0.04 : 0.0;
      position.add(Vector2(offsetXM + shake, offsetYM));
    }
  }

  /// 비행 조작 상태 (볼 부풀리기 → 볼이 빵빵, 급강하 → 회전 멈추고 길쭉).
  void setControls({required bool inflating, required bool diving}) {
    _inflating = inflating;
    _diving = diving;
  }

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
    angle = s.isAirborne && !_diving ? _spin : 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _squashV += (-_springK * _squash - _springDamping * _squashV) * dt;
    _squash += _squashV * dt;
    _spin += dt * 2.2;
    _clock += dt;
    final k = 1 - math.exp(-12 * dt);
    _puff += ((_inflating ? 1 : 0) - _puff) * k;
    _dive += ((_diving ? 1 : 0) - _dive) * k;
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
      ..translate(c.dx, c.dy + r * (1 - sy));
    if (_stretch > 0) {
      // 당긴 방향으로 늘어나고 옆으로 가늘어진다 (과충전이면 더)
      final along = 1 + 0.45 * _stretch;
      final across = 1 - (_trembling ? 0.22 : 0.18) * _stretch;
      canvas
        ..rotate(_pullAngle)
        ..scale(along, across)
        ..rotate(-_pullAngle);
    }
    // 부풀리면 옆으로 빵빵, 급강하면 세로로 길쭉
    canvas.scale(
      sx * (1 + 0.15 * _puff) * (1 - 0.15 * _dive),
      sy * (1 + 0.05 * _puff) * (1 + 0.25 * _dive),
    );
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
      ..drawCircle(
        Offset(-r * 0.55, r * 0.25),
        r * (0.28 + 0.12 * _puff),
        _blush,
      )
      ..drawCircle(
        Offset(r * 0.55, r * 0.25),
        r * (0.28 + 0.12 * _puff),
        _blush,
      )
      ..drawCircle(Offset(-r * 0.32, -r * 0.05), r * 0.11, _eye)
      ..drawCircle(Offset(r * 0.32, -r * 0.05), r * 0.11, _eye)
      ..restore();
  }
}
