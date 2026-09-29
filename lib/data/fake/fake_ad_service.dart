import 'package:mozzi/core/result.dart';
import 'package:mozzi/domain/services/ad_service.dart';

/// 가짜 광고: 항상 끝까지 본 것으로 한다 (dev·테스트, 실제 광고는 P9).
class FakeAdService implements AdService {
  FakeAdService({this.result = const Ok(null), this.rewardedReady = true});

  @override
  bool rewardedReady;

  /// 돌려줄 결과 (실패 경로 테스트용).
  Result<void, AdError> result;

  /// 보여준 횟수.
  int shown = 0;

  @override
  Future<Result<void, AdError>> showRewarded() async {
    shown++;
    return result;
  }
}
