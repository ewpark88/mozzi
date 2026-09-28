/// 화면 프레임 시간을 고정 시뮬 스텝 수로 바꾼다. (ARCHITECTURE §4)
///
/// 실제 시간 × [timeScale](시트 `sim_time_scale`) 을 누적해 [stepDt] 단위로 잘라 준다.
/// 같은 총 시간이면 프레임레이트와 무관하게 같은 스텝 수가 나와 결과가 같다.
class FixedStepper {
  FixedStepper({
    required this.stepDt,
    required this.timeScale,
    this.maxStepsPerFrame = 12,
  }) : assert(stepDt > 0 && timeScale > 0, 'stepDt, timeScale 은 양수');

  final double stepDt;
  final double timeScale;

  /// 한 프레임에 돌릴 최대 스텝 수. 긴 멈춤(백그라운드 복귀 등) 뒤 폭주를 막는다.
  final int maxStepsPerFrame;

  double _accumulator = 0;

  /// 이번 프레임([realDtSec] 초)에 진행할 스텝 수.
  int advance(double realDtSec) {
    _accumulator += realDtSec * timeScale;
    var steps = (_accumulator / stepDt).floor();
    if (steps > maxStepsPerFrame) {
      steps = maxStepsPerFrame;
      _accumulator = 0;
    } else {
      _accumulator -= steps * stepDt;
    }
    return steps;
  }

  /// 다음 스텝까지 진행 비율 (0~1). 렌더링 보간용.
  double get alpha => _accumulator / stepDt;

  void reset() => _accumulator = 0;
}
