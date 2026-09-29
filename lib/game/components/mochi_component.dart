import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/domain/character/mochi_expression.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/render/mochi/mochi_cache.dart';
import 'package:mozzi/game/render/mochi/mochi_deform.dart';
import 'package:mozzi/game/render/mochi/mochi_face.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/render/shade.dart';

/// 2.5D 모찌 (GDD §3 2.5D 아트 디렉션·애니메이션 입력값, 샘플 drawHero·drawMochi).
///
/// 위치는 비행 시뮬 상태를 그대로 따른다. 찌그러짐·볼 출렁임은 시각 전용 스프링
/// (게임 판정에 영향 없음). 그림은 샘플 단위(몸 반지름 38)로 그리고 [radiusM] 에 맞춰 줄인다.
class MochiComponent extends PositionComponent {
  MochiComponent({
    required this.radiusM,
    required this.pxPerM,
    required this.timeScale,
    MochiBodyCache? cache,
  }) : _cache = cache ?? MochiBodyCache(),
       super(anchor: Anchor.center, size: Vector2.all(radiusM * 2));

  /// 몸통 반지름 (m). 2.5D 샘플 RAD 38px 을 기본 카메라 배율로 환산한 값.
  final double radiusM;

  /// 기본 카메라 배율(가상 px/m)·시뮬 재생 배율 — 속도를 샘플 단위로 바꾸는 데 쓴다.
  final double pxPerM;
  final double timeScale;

  final MochiBodyCache _cache;
  final MochiFace _face = MochiFace();
  final Paint _shadow = Paint();

  /// 표정 (P8 상태 머신이 정한다. 그 전에는 기본).
  MochiExpression expression = MochiExpression.idle;

  /// 월드 림라이트 색 (GDD §3 광원: 월드별 조명).
  Color rim = MochiPalette.rimLight;

  /// 저사양 모드: 털 질감 끔 (GDD §3 성능).
  bool lowSpec = false;

  static const double _landingSquash = 0.35;
  static const double _puffCheek = 1.35;
  static const double _blinkEverySec = 3.2;
  static const double _blinkSec = 0.12;

  final VisualSpring _squash = VisualSpring(k: 260, damping: 11);
  final VisualSpring _cheek = VisualSpring(k: 90, damping: 8, rest: 1);
  int _seenBounces = 0;
  double _spin = 0;
  double _clock = 0;
  FlightState _state = FlightState.initial;

  double _pullAngle = 0;
  double _stretch = 0;
  bool _inflating = false;
  bool _diving = false;
  double _dive = 0;

  double get _unitsPerM => MochiDeform.unitR / radiusM;

  /// 볼 스프링 값 (테스트·연출용).
  double get cheek => _cheek.value;

  /// 당기는 중 변형 (GDD §2 “드래그 거리만큼 늘어남”). [offsetXM]/[offsetYM] 은 당긴 쪽으로
  /// 끌려간 위치 (월드 m, y 아래 +). 샘플처럼 당긴 벡터의 절반만큼 따라간다.
  void setPull({
    required double offsetXM,
    required double offsetYM,
    required double stretch,
    required bool trembling,
  }) {
    _stretch = stretch;
    if (stretch > 0) {
      _pullAngle = math.atan2(offsetYM, offsetXM);
      final shake = trembling ? math.sin(_clock * 80) * radiusM * 0.05 : 0.0;
      position.add(Vector2(offsetXM + shake, offsetYM));
    }
  }

  /// 비행 조작 상태 (볼 부풀리기 → 볼 빵빵, 급강하 → 회전 멈추고 길쭉).
  void setControls({required bool inflating, required bool diving}) {
    _inflating = inflating;
    _diving = diving;
  }

  /// 씨앗을 먹으면 볼이 출렁인다 (GDD §3 볼 스프링).
  void gulp() => _cheek.velocity += 3;

  /// 시뮬 상태를 반영한다 (월드 좌표: x 오른쪽, y 아래가 +).
  void syncFrom(FlightState s) {
    _state = s;
    position.setValues(s.xM, -(s.yM + radiusM));
    if (s.bounces > _seenBounces) {
      _seenBounces = s.bounces;
      _squash
        ..value = _landingSquash
        ..velocity = 0;
    }
    if (s.phase == FlightPhase.ready) {
      _seenBounces = 0;
      _spin = 0;
    }
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _squash.step(dt);
    _cheek.step(dt);
    if (_inflating && _cheek.value < _puffCheek) {
      _cheek.value += (_puffCheek - _cheek.value) * math.min(1, dt * 10);
    }
    if (_state.isAirborne && !_diving) _spin += dt * 2.2;
    _clock += dt;
    _dive += ((_diving ? 1 : 0) - _dive) * (1 - math.exp(-12 * dt));
  }

  @override
  void render(Canvas canvas) {
    final u = radiusM / MochiDeform.unitR;
    final s = _state;
    final grounded = !s.isAirborne && s.phase != FlightPhase.ready;
    final speed = math.sqrt(s.vxMps * s.vxMps + s.vyMps * s.vyMps);
    final d = MochiDeform.of(
      stretch: _stretch,
      stretchAngle: _pullAngle,
      speedUnits: s.isAirborne ? speed * pxPerM * timeScale : 0,
      velocityAngle: math.atan2(-s.vyMps, s.vxMps),
      squash: grounded || s.phase == FlightPhase.ready ? -_squash.value : 0,
      breath: s.phase == FlightPhase.ready && _stretch == 0
          ? math.sin(_clock * 2.2) * .025
          : 0,
      heightUnits: s.yM * _unitsPerM,
    );
    canvas
      ..save()
      ..translate(radiusM, radiusM);
    _groundShadow(canvas, d, u);
    canvas
      ..scale(u)
      ..translate(0, d.liftUnits);
    if (d.along != 1) {
      canvas
        ..rotate(d.axisAngle)
        ..scale(d.along, d.across)
        ..rotate(-d.axisAngle);
    }
    canvas
      ..scale(d.scaleX, d.scaleY)
      ..rotate(d.lean + (s.isAirborne && !_diving ? _spin : 0))
      ..scale(1 - .12 * _dive, 1 + .2 * _dive)
      ..drawPicture(
        _cache.body(
          fly: s.isAirborne,
          cheek: _cheek.value,
          rim: rim,
          lowSpec: lowSpec,
        ),
      );
    _face.paint(
      canvas,
      _inflating ? MochiExpression.puff : expression,
      t: _clock,
      blink: _clock % _blinkEverySec < _blinkSec,
    );
    canvas.restore();
  }

  /// 소프트 타원 그림자: 높이 날수록 작고 연해지고, 찌그러지면 넓어진다.
  void _groundShadow(Canvas canvas, MochiDeform d, double u) {
    final groundY = _state.yM + radiusM;
    _shadow.shader = Shade.radial(
      Offset(0, groundY),
      0,
      Offset(0, groundY),
      d.shadowWidth * u,
      [
        (0, Shade.alpha(MochiPalette.groundShadow, d.shadowAlpha)),
        (1, Shade.alpha(MochiPalette.groundShadow, 0)),
      ],
    );
    canvas
      ..save()
      ..translate(0, groundY)
      ..scale(1, .28)
      ..translate(0, -groundY)
      ..drawCircle(Offset(0, groundY), d.shadowWidth * u, _shadow)
      ..restore();
  }

  @override
  void onRemove() {
    _cache.dispose();
    super.onRemove();
  }
}
