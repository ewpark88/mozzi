import 'dart:math' as math;

import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 비행을 따라가는 카메라 계산 (Flame 과 무관한 순수 계산 → 단위 테스트 가능).
///
/// - 기본 배율은 `cam_base_px_per_m` (Lv0 에서 2.5D 샘플과 같은 화면 크기)
/// - 높이 올라가면 모찌와 지면이 함께 보이도록, 빨라지면 앞이 보이도록 줌아웃
/// - 급격한 변화는 지수 보간으로 부드럽게
class CameraRig {
  CameraRig({required this.basePxPerM, required this.timeScale})
    : _pxPerM = basePxPerM;

  final double basePxPerM;
  final double timeScale;

  /// 모찌 위로 남길 여유 높이 (m).
  static const double headroomM = 1.5;

  /// 앞을 보여줄 실제 시간 (초). 빠를수록 멀리 보이게 줌아웃.
  static const double lookAheadSec = 0.4;

  /// 가상 화면 너비 중 앞쪽으로 보여줄 비율.
  static const double lookAheadWidthRatio = 0.65;

  /// 줌 보간 속도 (1/초).
  static const double zoomFollowRate = 4;

  double _pxPerM;
  double _focusX = 0;

  /// 현재 배율 (가상 px / m).
  double get pxPerM => _pxPerM;

  /// 카메라가 따라가는 월드 x (m). 화면 [VirtualViewport.focusXRatio] 위치에 놓인다.
  double get focusX => _focusX;

  /// 상태에 맞는 목표 배율.
  double targetPxPerM(FlightState s, VirtualViewport vp) {
    final fitHeight = vp.skyHeight * 0.85 / (s.yM + headroomM);
    final aheadM = s.vxMps.abs() * lookAheadSec * timeScale + 3;
    final fitSpeed = vp.virtualWidth * lookAheadWidthRatio / aheadM;
    return math.min(basePxPerM, math.min(fitHeight, fitSpeed));
  }

  /// 실제 시간 [realDt] 만큼 카메라를 갱신한다.
  void update(FlightState s, VirtualViewport vp, double realDt) {
    final target = targetPxPerM(s, vp);
    final k = 1 - math.exp(-zoomFollowRate * realDt);
    _pxPerM += (target - _pxPerM) * k;
    _focusX = s.xM;
  }

  /// 새 판 시작.
  void reset() {
    _pxPerM = basePxPerM;
    _focusX = 0;
  }
}
