import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mozzi/core/math/round_half_up.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/run/star_rules.dart';

/// 한 판 결과 (GDD §2 콤보와 착지 — 결과 화면, §4 스테이지 구조). 불변.
///
/// 씨앗 = 거리 씨앗 + 먹은 씨앗 (ADR-017):
/// - 거리 씨앗 = `seedsForDistance(거리)` — 페이싱 시트 공식 그대로.
/// - 먹은 씨앗 = 비행 중 먹은 씨앗 값(콤보 배율 적용) × 볼주머니 배율, 사사오입.
/// 실패해도 씨앗은 받는다. 결과 화면 광고는 합계에 `ad_reward_multiplier`.
@immutable
class RunResult {
  const RunResult({
    required this.stageId,
    required this.distanceM,
    required this.previousBestM,
    required this.distanceSeeds,
    required this.pickupSeeds,
    required this.comboMax,
    required this.stars,
    required this.bossLost,
  });

  /// 정지한 판에서 결과를 만든다. [previousBestM] 은 이 스테이지의 직전 최고 기록.
  factory RunResult.fromSession(
    RunSession session,
    UpgradeLevels levels, {
    required double previousBestM,
  }) {
    final f = session.formulas;
    final distance = session.state.distanceM;
    return RunResult(
      stageId: session.stage?.id,
      distanceM: distance,
      previousBestM: previousBestM,
      distanceSeeds: f.seedsForDistance(distance, levels),
      pickupSeeds: pickupSeedsFor(session.stats.pickupValue, levels, f),
      comboMax: session.stats.comboMax,
      stars: session.stars(),
      bossLost: session.bossLost,
    );
  }

  /// 먹은 씨앗 값 → 지갑에 넣는 씨앗 (볼주머니 배율, 사사오입).
  static int pickupSeedsFor(
    double pickupValue,
    UpgradeLevels levels,
    BalanceFormulas f,
  ) => roundHalfUp(math.max(0, pickupValue) * f.seedMultiplier(levels));

  /// 스테이지 ID ("1-1"). 자유 비행이면 null.
  final String? stageId;
  final double distanceM;

  /// 이 스테이지의 직전 최고 기록 (m). 처음이면 0.
  final double previousBestM;
  final int distanceSeeds;
  final int pickupSeeds;
  final int comboMax;

  /// 별 판정 (자유 비행이면 null).
  final StarResult? stars;

  /// 보스에게 져서 끝났는지.
  final bool bossLost;

  /// 이번 판 씨앗 합계 (광고 전).
  int get seeds => distanceSeeds + pickupSeeds;

  /// 광고를 봤을 때 받는 씨앗.
  int seedsWithAd(double adMultiplier) => roundHalfUp(seeds * adMultiplier);

  bool get cleared => stars?.cleared ?? false;

  int get starCount => stars?.count ?? 0;

  /// 직전 최고 기록 대비 변화 (m). + 면 신기록.
  double get bestDeltaM => distanceM - previousBestM;

  bool get isNewRecord => distanceM > previousBestM;
}
