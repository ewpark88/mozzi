/// 가로 고정 반응형 가상 화면 (ADR-011).
///
/// 가상 높이는 [virtualHeight] 로 고정하고, 너비는 기기 화면 비율만큼 늘어난다.
/// 태블릿 4:3 → 720, 16:9 → 960, 20:9 폰 → 1200, 21:9 → 1260.
/// 게임 월드는 이 가상 좌표로 배치하고, 실제 화면에는 [scale] 배로 그린다.
class VirtualViewport {
  const VirtualViewport({required this.screenWidth, required this.screenHeight})
    : assert(screenWidth > 0 && screenHeight > 0, '화면 크기는 양수');

  /// 2.5D 샘플(960×540)과 같은 가상 높이.
  static const double virtualHeight = 540;

  /// 지면이 놓이는 높이 비율 (위에서부터). 샘플 GY = VH × 0.8.
  static const double groundLineRatio = 0.8;

  /// 모찌가 놓이는 가로 위치 비율 (왼쪽부터).
  static const double focusXRatio = 0.3;

  final double screenWidth;
  final double screenHeight;

  /// 가상 좌표 1 = 실제 화면 [scale] 논리 픽셀.
  double get scale => screenHeight / virtualHeight;

  double get virtualWidth => screenWidth / scale;

  double get aspectRatio => screenWidth / screenHeight;

  /// 지면 위로 보이는 가상 높이 (px).
  double get skyHeight => virtualHeight * groundLineRatio;
}
