import 'dart:math' as math;

/// 비행 중 조작 3종 상태 (GDD §2). 입력은 공중(flying)에서만 받는다 — 판단은 시뮬레이터가.
///
/// - 부스터: 탭마다 [tapSec] 만큼 분사 예약. 분사 중에는 수평으로 [boostSpeedMps] 만큼
///   더 이동한다(속도가 아니라 이동량 추가 → 공중에서 연료를 다 쓰면 정확히 공식 부스터 거리).
/// - 볼 부풀리기: 누르는 동안 활공.
/// - 급강하: 한 번 쓰면 다음 접지까지 유지.
class FlightControls {
  FlightControls({
    required this.fuelMaxSec,
    required this.tapSec,
    required this.boostSpeedMps,
  }) : _fuel = fuelMaxSec;

  final double fuelMaxSec;
  final double tapSec;
  final double boostSpeedMps;

  double _fuel;
  double _burnLeft = 0;
  bool inflating = false;
  bool _diving = false;
  double _diveElapsed = 0;

  double get fuelSec => _fuel;
  bool get boosting => _burnLeft > 0;
  bool get diving => _diving;

  /// 급강하 시작 후 흐른 시뮬 시간 (퍼펙트 판정용, P5).
  double get diveElapsedSec => _diveElapsed;

  /// 탭: 남은 연료에서 한 번 분사를 예약한다. 연료가 없으면 false.
  bool tapBoost() {
    if (_fuel <= 0 || boostSpeedMps <= 0) return false;
    final burn = math.min(tapSec, _fuel);
    _fuel -= burn;
    _burnLeft += burn;
    return true;
  }

  void startDive() {
    _diving = true;
    _diveElapsed = 0;
    inflating = false;
  }

  /// 공중에서 [dt] 초 동안의 부스터 추가 이동량 (m). 분사 시간을 소모한다.
  double takeBoostDisplacement(double dt) {
    if (_burnLeft <= 0) return 0;
    final burn = math.min(dt, _burnLeft);
    _burnLeft -= burn;
    return boostSpeedMps * burn;
  }

  void tick(double dt) {
    if (_diving) _diveElapsed += dt;
  }

  /// 땅에 닿음: 분사 중이던 연료는 사라지고(공중에서 써야 함) 급강하가 끝난다.
  /// 볼 부풀리기는 손을 떼기 전까지 유지 (튄 뒤에도 계속 활공).
  void onGround() {
    _burnLeft = 0;
    _diving = false;
  }
}
