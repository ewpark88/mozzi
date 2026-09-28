import 'dart:math' as math;

import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/flight_control_spec.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';

/// 한 판 비행에 쓰는 물리 값. 업그레이드 레벨을 물리로 옮긴 결과다. (ADR-012)
///
/// 조작 없이 45° 로 날리면 비행 시뮬 거리가 GDD §5 공식 거리와 같아지도록 만든다:
/// - 공기역학 → 유효 중력 `g / 공기역학 배율` (더 오래 떠서 사거리가 배율만큼 늘어남)
/// - 바운스 → 반발 계수 `e = √(b / (1 + b))`, `b = 바운스 배율 − 1`.
///   튀는 거리의 등비합이 첫 비행 거리의 `b` 배가 되어 총 거리 = 비행 × 바운스 배율.
/// - 부스터 → 연료 = 거리 예산 [boostBudgetM]. 공중에서 다 쓰면 공식 거리와 같다.
class FlightParams {
  const FlightParams({
    required this.launchSpeedMps,
    required this.gravityMps2,
    required this.restitution,
    required this.boostBudgetM,
    required this.controls,
  }) : assert(restitution >= 0 && restitution < 1, '반발 계수는 0 이상 1 미만');

  factory FlightParams.fromLevels(BalanceFormulas formulas, UpgradeLevels lv) {
    final bounceExtra = formulas.bounceMultiplier(lv) - 1;
    return FlightParams(
      launchSpeedMps: formulas.launchSpeedMps(lv),
      gravityMps2: formulas.config.gravityMps2 / formulas.aeroMultiplier(lv),
      restitution: math.sqrt(bounceExtra / (1 + bounceExtra)),
      // 공식은 (비행 + 부스터) × 바운스 배율 → 부스터 몫도 바운스 배율만큼 준다
      boostBudgetM: formulas.boostDistanceM(lv) * formulas.bounceMultiplier(lv),
      controls: formulas.config.controls,
    );
  }

  /// 힘 100%, 정확도 배율 1.0 일 때 발사 속도 (m/s).
  final double launchSpeedMps;

  /// 유효 중력 (m/s², 아래 방향 크기).
  final double gravityMps2;

  /// 착지 시 속도 보존 비율 (0 = 튀지 않음).
  final double restitution;

  /// 부스터 연료를 공중에서 다 쓰면 더해지는 거리 (m). Lv0 = 0 (연료 없음).
  final double boostBudgetM;

  final FlightControlSpec controls;

  /// 연료 (시뮬 초). 예산이 없으면 0.
  double get fuelSec => boostBudgetM > 0 ? controls.boostFuelSec : 0;

  /// 분사 중 추가 수평 이동 속도 (m/s).
  double get boostSpeedMps =>
      boostBudgetM > 0 ? boostBudgetM / controls.boostFuelSec : 0;
}
