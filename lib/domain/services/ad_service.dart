import 'package:mozzi/core/result.dart';

/// 광고를 못 보여준 이유.
enum AdError {
  /// 불러온 광고가 없음.
  notLoaded,

  /// 끝까지 보지 않고 닫음 (보상 없음).
  dismissed,
}

/// 광고 서비스 (GDD §7 광고 배치). P6 은 가짜 구현, 실제 AdMob 은 P9.
abstract interface class AdService {
  /// 보상형 광고를 지금 보여줄 수 있는지 (결과 화면 “2배 받기” 버튼 표시).
  bool get rewardedReady;

  /// 보상형 광고. 끝까지 보면 [Ok], 아니면 [Err].
  Future<Result<void, AdError>> showRewarded();
}
