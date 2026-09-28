import 'package:mozzi/domain/balance/flight_control_spec.dart';

/// 비행 중 제스처 결과 (GDD §2 비행 중 조작 3종 입력).
enum FlightGesture {
  /// 짧게 탭 → 부스터.
  boostTap,

  /// 길게 누르기 시작 → 볼 부풀리기 시작.
  inflateStart,

  /// 누르던 손을 뗌 → 볼 부풀리기 끝.
  inflateEnd,

  /// 아래로 쓸기 → 급강하.
  dive,
}

/// 탭 / 홀드 / 아래 스와이프를 구분한다 (오인식 방지 임계값은 시트 값).
///
/// - 누른 뒤 [FlightControlSpec.gestureHoldSec] 안에 떼면 탭
/// - 그보다 오래 누르고 있으면 홀드 (떼면 홀드 끝)
/// - [FlightControlSpec.gestureSwipeMaxSec] 안에 아래로 [FlightControlSpec.gestureSwipePx] 이상,
///   가로보다 세로로 더 움직이면 스와이프 (홀드 중에도 가능 → 부풀리기 끝 + 급강하)
///
/// 좌표는 가상 화면 px (y 아래 +), 시간은 실제 초.
class FlightGestureRecognizer {
  FlightGestureRecognizer(this.spec);

  final FlightControlSpec spec;

  _Touch _touch = _Touch.none;
  double _x0 = 0;
  double _y0 = 0;
  double _t0 = 0;

  bool get isHolding => _touch == _Touch.holding;

  List<FlightGesture> down(double x, double y, double t) {
    final out = <FlightGesture>[];
    if (_touch == _Touch.holding) out.add(FlightGesture.inflateEnd);
    _touch = _Touch.pending;
    _x0 = x;
    _y0 = y;
    _t0 = t;
    return out;
  }

  List<FlightGesture> move(double x, double y, double t) {
    if (_touch != _Touch.pending && _touch != _Touch.holding) return const [];
    final dy = y - _y0;
    final dx = (x - _x0).abs();
    final quick = t - _t0 <= spec.gestureSwipeMaxSec;
    if (dy >= spec.gestureSwipePx && dy > dx && quick) {
      final wasHolding = _touch == _Touch.holding;
      _touch = _Touch.consumed;
      return [if (wasHolding) FlightGesture.inflateEnd, FlightGesture.dive];
    }
    return const [];
  }

  /// 매 프레임 호출: 오래 누르고 있으면 홀드 시작.
  List<FlightGesture> tick(double t) {
    if (_touch == _Touch.pending && t - _t0 >= spec.gestureHoldSec) {
      _touch = _Touch.holding;
      return const [FlightGesture.inflateStart];
    }
    return const [];
  }

  List<FlightGesture> up(double t) {
    final touch = _touch;
    _touch = _Touch.none;
    return switch (touch) {
      _Touch.pending when t - _t0 < spec.gestureHoldSec => const [
        FlightGesture.boostTap,
      ],
      _Touch.pending => const [],
      _Touch.holding => const [FlightGesture.inflateEnd],
      _Touch.consumed || _Touch.none => const [],
    };
  }

  void reset() => _touch = _Touch.none;
}

enum _Touch { none, pending, holding, consumed }
