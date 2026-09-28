import 'package:mozzi/core/json/json_reader.dart';

/// 당기기·정확도 게이지 밸런스 값 (GDD §2, 시트 「설정」 게이지 표).
class LaunchSpec {
  const LaunchSpec({
    required this.maxPower,
    required this.needleSpeedBase,
    required this.needleSpeedK,
    required this.overchargeK,
    required this.perfectOff,
    required this.greatOff,
    required this.goodOff,
    required this.perfectMult,
    required this.greatMult,
    required this.goodMult,
    required this.missMult,
    required this.speedExponent,
    required this.pullMaxPx,
    required this.minPower,
    required this.maxAngleDeg,
  });

  factory LaunchSpec.fromJson(JsonReader r) => LaunchSpec(
    maxPower: r.number('gauge_max_power'),
    needleSpeedBase: r.number('gauge_speed_base'),
    needleSpeedK: r.number('gauge_speed_k'),
    overchargeK: r.number('gauge_over_k'),
    perfectOff: r.number('gauge_zone_width'),
    greatOff: r.number('gauge_great_off'),
    goodOff: r.number('gauge_good_off'),
    perfectMult: r.number('gauge_perfect_mult'),
    greatMult: (
      r.number('gauge_great_mult_min'),
      r.number('gauge_great_mult_max'),
    ),
    goodMult: (
      r.number('gauge_good_mult_min'),
      r.number('gauge_good_mult_max'),
    ),
    missMult: (
      r.number('gauge_miss_mult_min'),
      r.number('gauge_miss_mult_max'),
    ),
    speedExponent: r.number('gauge_speed_exponent'),
    pullMaxPx: r.number('pull_max_px'),
    minPower: r.number('pull_min_power'),
    maxAngleDeg: r.number('launch_angle_max_deg'),
  );

  /// 최대 힘 (1.1 = 110%).
  final double maxPower;

  /// 바늘 속도 `base + k·p` (p ≤ 1), 과충전 `(base + k)·(1 + overK·(p − 1))` (트랙 너비/초).
  final double needleSpeedBase;
  final double needleSpeedK;
  final double overchargeK;

  /// 판정 경계: 가운데에서 벗어난 정도 off(0 = 정중앙, 1 = 끝) 이하.
  final double perfectOff;
  final double greatOff;
  final double goodOff;

  final double perfectMult;

  /// (구간 바깥 경계 배율, 안쪽 경계 배율). 구간 안에서 선형 보간 (ADR-013).
  final (double, double) greatMult;
  final (double, double) goodMult;
  final (double, double) missMult;

  /// 발사 속도 배율 = (힘 × 판정 배율)^지수. 0.5 면 거리가 힘×배율에 비례 (ADR-013).
  final double speedExponent;

  /// 이 거리(가상 px)만큼 당기면 최대 힘.
  final double pullMaxPx;

  /// 이보다 약하게 놓으면 발사 취소.
  final double minPower;

  /// 발사 각 상한 (°). 하한은 0° (앞으로만 날아감).
  final double maxAngleDeg;
}
