import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/game/input/flight_gesture.dart';

import '../helpers/balance_fixture.dart';

/// GDD §2: 부스터 = 탭, 볼 부풀리기 = 홀드, 급강하 = 아래로 스와이프.
void main() {
  final spec = loadDefaultBalance().controls;
  late FlightGestureRecognizer g;
  setUp(() => g = FlightGestureRecognizer(spec));

  test('짧게 탭하면 부스터', () {
    g.down(100, 100, 0);
    expect(g.tick(0.05), isEmpty);
    expect(g.up(0.1), [FlightGesture.boostTap]);
  });

  test('탭 판정 시간(gesture_tap_max_sec) 안에 떼면 탭', () {
    g.down(100, 100, 0);
    expect(g.up(spec.gestureTapMaxSec - 0.01), [FlightGesture.boostTap]);
  });

  test('오래 누르면 부풀리기 시작, 떼면 끝', () {
    g.down(100, 100, 0);
    expect(g.tick(spec.gestureHoldSec - 0.01), isEmpty);
    expect(g.tick(spec.gestureHoldSec), [FlightGesture.inflateStart]);
    expect(g.isHolding, isTrue);
    expect(g.tick(1), isEmpty, reason: '한 번만');
    expect(g.up(1.2), [FlightGesture.inflateEnd]);
  });

  test('빠르게 아래로 쓸면 급강하 (탭으로 오인하지 않음)', () {
    g.down(100, 100, 0);
    expect(g.move(105, 100 + spec.gestureSwipePx, 0.1), [FlightGesture.dive]);
    expect(g.up(0.15), isEmpty);
  });

  test('홀드 중 아래로 쓸면 부풀리기를 끝내고 급강하', () {
    g
      ..down(100, 100, 0)
      ..tick(spec.gestureHoldSec);
    expect(
      g.move(100, 100 + spec.gestureSwipePx, spec.gestureHoldSec + 0.05),
      [FlightGesture.inflateEnd, FlightGesture.dive],
    );
    expect(g.up(0.5), isEmpty);
  });

  test('옆으로 쓸기·느린 쓸기·짧은 쓸기는 급강하가 아니다', () {
    g.down(100, 100, 0);
    expect(g.move(200, 150, 0.1), isEmpty, reason: '가로가 더 큼');
    g
      ..up(0.12)
      ..down(100, 100, 1);
    expect(
      g.move(100, 100 + spec.gestureSwipePx, 1 + spec.gestureSwipeMaxSec + 0.1),
      isEmpty,
      reason: '느림',
    );
    g
      ..up(2)
      ..down(100, 100, 3);
    expect(
      g.move(100, 100 + spec.gestureSwipePx - 5, 3.1),
      isEmpty,
      reason: '짧음',
    );
  });

  test('홀드 판정 시간을 넘겨 뗀 경우(홀드 직전 프레임)는 탭이 아니다', () {
    g.down(100, 100, 0);
    expect(g.up(spec.gestureHoldSec + 0.01), isEmpty);
  });
}
