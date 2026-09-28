import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/input/flight_gesture.dart';
import 'package:mozzi/game/input/play_input.dart';

import '../helpers/balance_fixture.dart';

void main() {
  final config = loadDefaultBalance();
  late FlightPhase phase;
  late List<LaunchDecision> launches;
  late List<FlightGesture> gestures;
  late PlayInput input;

  setUp(() {
    phase = FlightPhase.ready;
    launches = [];
    gestures = [];
    input = PlayInput(
      launchSpec: config.launch,
      controlSpec: config.controls,
      phaseOf: () => phase,
      onLaunch: launches.add,
      onGesture: gestures.add,
    );
  });

  test('발사 전에는 당기기 → 놓으면 발사 결정', () {
    input
      ..down(500, 200, 0)
      ..move(400, 300, 0.05);
    expect(input.pulling, isTrue);
    input.up(0.1);
    expect(launches, hasLength(1));
    expect(gestures, isEmpty);
  });

  test('비행 중에는 탭 → 부스터 (당기기가 아님)', () {
    phase = FlightPhase.flying;
    input.down(500, 200, 1);
    expect(input.pulling, isFalse);
    input.up(1.05);
    expect(gestures, [FlightGesture.boostTap]);
    expect(launches, isEmpty);
  });

  test('비행 중 홀드는 tick 으로 판정된다', () {
    phase = FlightPhase.flying;
    input
      ..down(500, 200, 1)
      ..tick(0.016, 1 + config.controls.gestureHoldSec + 0.001)
      ..up(2);
    expect(gestures, [FlightGesture.inflateStart, FlightGesture.inflateEnd]);
  });

  test('해금되지 않은 조작은 무시된다 (GDD §9: 월드 1 클리어 후 해금)', () {
    phase = FlightPhase.flying;
    input
      ..unlocks = const ControlUnlocks(inflate: false, dive: false)
      ..down(500, 200, 1)
      ..move(500, 200 + config.controls.gestureSwipePx, 1.1)
      ..up(1.15)
      ..down(500, 200, 2)
      ..tick(0.016, 2 + config.controls.gestureHoldSec + 0.001)
      ..up(3)
      ..down(500, 200, 4)
      ..up(4.05);
    expect(gestures, [FlightGesture.boostTap]);
  });

  test('미끄러짐·정지 중 터치는 아무것도 하지 않는다', () {
    for (final p in [FlightPhase.sliding, FlightPhase.stopped]) {
      phase = p;
      input
        ..down(500, 200, 1)
        ..up(1.05);
    }
    expect(gestures, isEmpty);
    expect(launches, isEmpty);
  });
}
