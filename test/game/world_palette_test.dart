import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/game/render/palette.dart';

/// GDD §4 배치 규칙: 다음 구역 원경을 경계 약 100m 전부터 미리 보여준다.
void main() {
  const starts = <double>[0, 500, 2000, 6000, 15000, 40000];

  test('월드 안에서는 그 월드 색', () {
    expect(WorldPalette.atDistance(starts, 100).far, WorldPalette.backyard.far);
    expect(WorldPalette.atDistance(starts, 1000).far, WorldPalette.park.far);
  });

  test('경계 100m 전부터 다음 월드 색으로 섞인다', () {
    expect(WorldPalette.atDistance(starts, 399).far, WorldPalette.backyard.far);
    final half = WorldPalette.atDistance(starts, 450).far;
    expect(half, isNot(WorldPalette.backyard.far));
    expect(half, isNot(WorldPalette.park.far));
    expect(WorldPalette.atDistance(starts, 500).far, WorldPalette.park.far);
  });
}
