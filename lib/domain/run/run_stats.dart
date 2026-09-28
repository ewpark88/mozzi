import 'dart:math' as math;

import 'package:mozzi/domain/sim/accuracy_gauge.dart';

/// 한 판 기록 (★★★ 미션 판정·결과 화면용, GDD §4 미션 타입 정의).
///
/// 오브젝트 적중은 문자열 키(시트·미션 JSON 의 obj)로 센다 — 아직 없는 월드 4~6 오브젝트
/// (번개구름·운석 등) 미션도 같은 방식으로 판정한다.
class RunStats {
  /// 콤보 1회당 씨앗 배율 (GDD §2: ×1.1씩 쌓임).
  static const double comboStep = 1.1;

  /// 발사 판정·힘 (grade_min, overcharge_perfect).
  GaugeGrade? grade;
  double power = 0;

  /// 먹은 씨앗 개수 (seeds_min) — 광고판 폭발 포함, 까마귀 강탈 차감.
  int seedsPicked = 0;

  /// 먹은 씨앗의 값 합 (콤보 배율 적용). 거리 씨앗과 별도.
  double pickupValue = 0;

  final Map<String, int> _hits = {};
  int combo = 0;
  int comboMax = 0;
  int boostTaps = 0;
  double glideSec = 0;
  int divePerfects = 0;

  /// 골 통과 시각·남은 연료 비율 (fuel_left_min). 골을 못 넘으면 null.
  double? goalTimeSec;
  double? fuelAtGoal;

  /// 최대 도달 거리 (★★ 판정).
  double maxDistanceM = 0;

  /// 보스 기록 (P6/P11): 대장과의 골인 시간 차, 강탈 게이지 최대, 기믹 퍼펙트 수.
  double? bossMarginSec;
  double? bossMeterMax;
  int bossPerfects = 0;

  /// 레일 완주 (ride_full, P11), 착륙 패드 오차 (land_in_zone, P11).
  final Map<String, int> rideFull = {};
  double? landingOffsetM;

  /// 지금 콤보의 씨앗 배율.
  double get comboMultiplier => math.pow(comboStep, combo).toDouble();

  int hits(String objKey) => _hits[objKey] ?? 0;

  Map<String, int> get allHits => Map.unmodifiable(_hits);

  /// 오브젝트 적중 기록. 장애물이 아니면 콤보가 쌓인다.
  void recordHit(String objKey, {required bool obstacle}) {
    _hits[objKey] = hits(objKey) + 1;
    if (!obstacle) {
      combo++;
      comboMax = math.max(comboMax, combo);
    }
  }

  /// 씨앗 [count] 개를 먹음 (지금 콤보 배율 적용).
  void addSeeds(int count) {
    seedsPicked += count;
    pickupValue += count * comboMultiplier;
  }

  /// 까마귀가 씨앗 [count] 개 강탈 (0 아래로 안 내려감).
  void stealSeeds(int count) {
    final taken = math.min(count, seedsPicked);
    seedsPicked -= taken;
    pickupValue = math.max(0, pickupValue - taken);
  }

  /// 착지: 콤보 초기화 (GDD §2).
  void onGround() => combo = 0;
}
