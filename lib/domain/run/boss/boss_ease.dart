import 'dart:math' as math;

import 'package:mozzi/domain/balance/world_config.dart';

/// 보스 연속 실패 완화 (GDD §4 보스 스테이지 상세).
///
/// 같은 보스를 3판 연속 실패할 때마다 [BossSpec.failEaseStep] 씩, 최대
/// [BossSpec.failEaseMax] 까지 완화한다. 클리어하면 연속 실패가 0 으로 초기화된다.
abstract final class BossEase {
  /// 완화 한 단계에 필요한 연속 실패 수.
  static const int failsPerStep = 3;

  /// 연속 실패 [consecutiveFails] 번일 때 완화 비율 (0 ~ 최대).
  static double ratio(int consecutiveFails, BossSpec spec) => math.min(
    spec.failEaseMax,
    spec.failEaseStep * (consecutiveFails ~/ failsPerStep),
  );
}
