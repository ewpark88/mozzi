import 'dart:math' as math;

import 'package:meta/meta.dart';

/// 모찌 렌더 입력값 → 몸 변형 (GDD §3 애니메이션 입력값, 샘플 drawHero).
///
/// 순수 계산이라 게임 판정에 영향이 없다 (시각 전용). 단위는 샘플 좌표(몸 반지름 [unitR]).
@immutable
class MochiDeform {
  const MochiDeform({
    required this.along,
    required this.across,
    required this.axisAngle,
    required this.lean,
    required this.scaleX,
    required this.scaleY,
    required this.liftUnits,
    required this.shadowWidth,
    required this.shadowAlpha,
  });

  /// [stretch] 당김 0~1, [stretchAngle] 당긴 방향(라디안, 화면 좌표 y 아래 +),
  /// [speedUnits] 비행 속도(샘플 px/초 단위), [velocityAngle] 비행 방향,
  /// [squash] 착지 스프링(− 눌림, + 늘어남), [breath] 대기 숨쉬기(±),
  /// [heightUnits] 지면에서의 높이(샘플 단위).
  factory MochiDeform.of({
    double stretch = 0,
    double stretchAngle = 0,
    double speedUnits = 0,
    double velocityAngle = 0,
    double squash = 0,
    double breath = 0,
    double heightUnits = 0,
  }) {
    var along = 1.0;
    var across = 1.0;
    var axis = 0.0;
    var lean = 0.0;
    if (stretch > 0) {
      // 샘플: sx = 1 + 당긴 거리/125, sy = 1/√sx (MAXPULL 150 → stretch 1)
      along = 1 + stretch * maxPullUnits / pullStretchUnits;
      across = 1 / math.sqrt(along);
      axis = stretchAngle;
      // 당긴 반대쪽(발사 방향)을 살짝 바라본다
      lean = _wrap(stretchAngle + math.pi) * leanRatio;
    } else if (speedUnits > flySpeedMin) {
      final st = math.min(flyStretchMax, speedUnits / flyStretchSpeed);
      along = 1 + st;
      across = 1 - st * 0.7;
      axis = velocityAngle;
    }
    final lift = math.max(0, heightUnits);
    final far = 1 / (1 + lift / shadowFadeUnits);
    return MochiDeform(
      along: along,
      across: across,
      axisAngle: axis,
      lean: lean,
      scaleX: 1 + squash,
      scaleY: 1 - squash * 0.85 + breath,
      liftUnits: unitR * squash * 0.9,
      // 찌그러질수록 넓어지고, 높이 날수록 작고 연해진다 (GDD §3 말랑 표현·접지 그림자)
      shadowWidth:
          unitR * 1.1 * (1 + math.max(0, squash) * 1.2) * (0.45 + 0.55 * far),
      shadowAlpha: 0.32 * far,
    );
  }

  /// 샘플 몸 반지름 (RAD 38).
  static const double unitR = 38;

  static const double maxPullUnits = 150;
  static const double pullStretchUnits = 125;
  static const double leanRatio = 0.25;
  static const double flySpeedMin = 50;
  static const double flyStretchMax = 0.28;
  static const double flyStretchSpeed = 4200;
  static const double shadowFadeUnits = 160;

  /// 변형 축([axisAngle]) 방향 배율 / 수직 배율.
  final double along;
  final double across;
  final double axisAngle;

  /// 몸 기울기 (라디안).
  final double lean;

  /// 착지 찌그러짐 배율 (가로·세로).
  final double scaleX;
  final double scaleY;

  /// 찌그러질 때 발이 땅에 붙도록 내리는 양 (샘플 단위).
  final double liftUnits;

  /// 접지 그림자 가로 반지름 (샘플 단위)·투명도.
  final double shadowWidth;
  final double shadowAlpha;

  /// 하이라이트가 늘어나는 비율 (늘어난 방향으로 길어짐).
  double get highlightStretch => along * scaleX;

  static double _wrap(double a) => math.atan2(math.sin(a), math.cos(a));
}

/// 시각 전용 감쇠 스프링 (샘플 spring: 찌그러짐 k 260·c 11, 볼 k 90·c 8).
class VisualSpring {
  VisualSpring({required this.k, required this.damping, this.rest = 0})
    : value = rest;

  final double k;
  final double damping;
  final double rest;
  double value;
  double velocity = 0;

  void step(double dt) {
    velocity += (-k * (value - rest) - damping * velocity) * dt;
    value += velocity * dt;
  }
}
