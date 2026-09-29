import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/progress/player_progress.dart';

/// 판 안내 (GDD §9 온보딩: 조작은 한 번에 하나씩).
enum OnboardingHint {
  /// 1판: 당기기만.
  pull,

  /// 2판: 비행 중 탭 = 부스터.
  boost,

  /// 5판: 초록 구간에서 놓으면 PERFECT.
  perfect,
}

/// 온보딩 스크립트 (GDD §9 첫 15분, ADR-019). 판 수(`totalRuns`)로 단계를 정한다.
///
/// - 1판: 당기기 안내 + 트램폴린 자동 배치 (크게 튀어 오르는 첫 경험)
/// - 1판 뒤: 첫 업그레이드 무료 (부스터 Lv1 — Lv0 은 연료가 없어 부스터를 가르칠 수 없음)
/// - 2판: 부스터 안내
/// - 3판 결과: 광고 2배 처음 제안 (황금 씨앗 확정 이벤트는 P14)
/// - 5판: 퍼펙트 릴리즈 안내 (전면 광고는 이후부터, P9)
/// - 월드 1 클리어: 부풀리기·급강하 해금은 1-5 보스 보상(P6), 캐릭터 교체 안내는 P12
class Onboarding {
  const Onboarding(this.formulas);

  final BalanceFormulas formulas;

  /// `onboardingStep` 값: 첫 무료 업그레이드를 받았음.
  static const int stepFreeUpgradeClaimed = 1;

  /// 첫 무료 업그레이드 종류.
  static const UpgradeType freeUpgradeType = UpgradeType.boost;

  /// 트램폴린은 조작 없이 날렸을 때 떨어지는 곳 앞쪽에 놓는다 (기대 거리 × 이 비율).
  static const double trampAtRatio = .8;

  /// 광고 2배를 처음 강조해 제안하는 판 (3판 결과).
  static const int adOfferRun = 3;

  /// 퍼펙트 릴리즈를 가르치는 판 (5판).
  static const int perfectRun = 5;

  /// 이번 판(= 다음에 할 판)의 안내.
  OnboardingHint? hintFor(PlayerProgress p) {
    final run = p.totalRuns + 1;
    if (run == 1) return OnboardingHint.pull;
    if (run == 2 && p.levels[UpgradeType.boost] > 0) {
      return OnboardingHint.boost;
    }
    if (run == perfectRun) return OnboardingHint.perfect;
    return null;
  }

  /// 1판이면 트램폴린 자동 배치 위치 (m), 아니면 null.
  double? tutorialTrampM(PlayerProgress p) => p.totalRuns == 0
      ? formulas.expectedDistanceM(p.levels) * trampAtRatio
      : null;

  /// 받을 수 있는 무료 업그레이드 (1판 이상 했고 아직 안 받았으면).
  UpgradeType? freeUpgrade(PlayerProgress p) =>
      p.totalRuns >= 1 && p.onboardingStep < stepFreeUpgradeClaimed
      ? freeUpgradeType
      : null;

  /// 무료 업그레이드를 받는다 (씨앗 차감 없음, 한 번만).
  PlayerProgress claimFreeUpgrade(PlayerProgress p) {
    final type = freeUpgrade(p);
    if (type == null) return p;
    return p.copyWith(
      levels: p.levels.increment(type),
      onboardingStep: stepFreeUpgradeClaimed,
    );
  }

  /// 방금 끝난 판([after] = 기록 반영 후)이 광고 2배를 강조해 제안할 판인지.
  bool highlightAdOffer(PlayerProgress after) => after.totalRuns == adOfferRun;
}
