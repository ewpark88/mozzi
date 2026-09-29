import 'package:mozzi/core/json/json_reader.dart';

/// 비행 중 조작 3종 밸런스 값 (GDD §2, 시트 「설정」 비행 조작 표).
class FlightControlSpec {
  const FlightControlSpec({
    required this.boostFuelSec,
    required this.boostTapSec,
    required this.boostLv0FuelSec,
    required this.boostCutOnLand,
    required this.inflateGlideRatio,
    required this.inflateDragPerSec,
    required this.diveSpeedRatio,
    required this.diveBounceMult,
    required this.divePerfectWindowSec,
    required this.divePerfectMult,
    required this.gestureTapMaxSec,
    required this.gestureHoldSec,
    required this.gestureSwipePx,
    required this.gestureSwipeMaxSec,
  });

  factory FlightControlSpec.fromJson(JsonReader r) => FlightControlSpec(
    boostFuelSec: r.number('boost_fuel_sec'),
    boostTapSec: r.number('boost_tap_sec'),
    boostLv0FuelSec: r.number('boost_lv0_fuel_sec'),
    boostCutOnLand: r.boolean('boost_cut_on_land'),
    inflateGlideRatio: r.number('inflate_glide_ratio'),
    inflateDragPerSec: r.number('inflate_decel_per_sec'),
    diveSpeedRatio: r.number('dive_speed_ratio'),
    diveBounceMult: r.number('dive_bounce_mult'),
    divePerfectWindowSec: r.number('dive_perfect_window_sec'),
    divePerfectMult: r.number('dive_perfect_mult'),
    gestureTapMaxSec: r.number('gesture_tap_max_sec'),
    gestureHoldSec: r.number('gesture_hold_sec'),
    gestureSwipePx: r.number('gesture_swipe_min_px'),
    gestureSwipeMaxSec: r.number('gesture_swipe_max_sec'),
  );

  /// 부스터 연료 (시뮬 초). 공식 부스터 거리를 이 시간 동안 나눠 쓴다.
  final double boostFuelSec;

  /// 탭 한 번에 쓰는 연료 (시뮬 초).
  final double boostTapSec;

  /// 부스터 업그레이드 Lv0 의 연료 (시뮬 초). GDD §2: 0 = 연료 없음.
  final double boostLv0FuelSec;

  /// 착지하면 분사 중이던 연료가 즉시 사라지는지 (GDD §2).
  final bool boostCutOnLand;

  /// 볼 부풀리기 중 최대 낙하 속도 = 수평 속도 × 이 값.
  final double inflateGlideRatio;

  /// 볼 부풀리기 중 수평 속도 감소율 (1/초, 지수 감쇠).
  final double inflateDragPerSec;

  /// 급강하 낙하 속도 = 수평 속도 × 이 값 이상.
  final double diveSpeedRatio;

  /// 급강하로 바운스 오브젝트 적중 시 튀는 속도 배율 (P5).
  final double diveBounceMult;

  /// 급강하 시작 후 이 시간 안에 적중하면 퍼펙트 (P5).
  final double divePerfectWindowSec;
  final double divePerfectMult;

  /// 이 시간 안에 떼면 탭(부스터). 실제 초.
  final double gestureTapMaxSec;

  /// 이 시간 이상 누르고 있으면 홀드(볼 부풀리기) 시작. 실제 초.
  final double gestureHoldSec;

  /// 아래로 이만큼(가상 px) [gestureSwipeMaxSec] 안에 쓸면 급강하.
  final double gestureSwipePx;
  final double gestureSwipeMaxSec;
}
