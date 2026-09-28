import 'package:mozzi/domain/balance/flight_control_spec.dart';
import 'package:mozzi/domain/balance/launch_spec.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/input/flight_gesture.dart';

/// 볼 부풀리기·급강하 해금 (GDD §9: 월드 1 클리어 후 해금, 온보딩은 P8). 부스터는 항상.
class ControlUnlocks {
  const ControlUnlocks({this.inflate = true, this.dive = true});

  static const ControlUnlocks all = ControlUnlocks();

  final bool inflate;
  final bool dive;

  bool allows(FlightGesture g) => switch (g) {
    FlightGesture.boostTap => true,
    FlightGesture.inflateStart || FlightGesture.inflateEnd => inflate,
    FlightGesture.dive => dive,
  };
}

/// 한 판의 터치 입력 라우팅: 발사 전에는 당기기(게이지), 비행 중에는 조작 3종 제스처.
/// 좌표는 가상 화면 px, 시간은 실제 초.
class PlayInput {
  PlayInput({
    required LaunchSpec launchSpec,
    required FlightControlSpec controlSpec,
    required this.phaseOf,
    required this.onLaunch,
    required this.onGesture,
  }) : launch = LaunchController(launchSpec),
       gestures = FlightGestureRecognizer(controlSpec);

  final LaunchController launch;
  final FlightGestureRecognizer gestures;

  /// 현재 비행 단계.
  final FlightPhase Function() phaseOf;

  /// 당기기를 놓아 발사가 확정됨.
  final void Function(LaunchDecision decision) onLaunch;

  /// 비행 중 제스처 (해금된 것만).
  final void Function(FlightGesture gesture) onGesture;

  ControlUnlocks unlocks = ControlUnlocks.all;

  bool get pulling => launch.phase == PullPhase.pulling;

  void down(double x, double y, double t) {
    switch (phaseOf()) {
      case FlightPhase.ready:
        launch.start(x, y);
      case FlightPhase.flying:
        _emit(gestures.down(x, y, t));
      case FlightPhase.sliding:
      case FlightPhase.stopped:
        return;
    }
  }

  void move(double x, double y, double t) {
    if (pulling) {
      launch.move(x, y);
    } else {
      _emit(gestures.move(x, y, t));
    }
  }

  void up(double t) {
    if (pulling) {
      final decision = launch.release();
      if (decision != null) onLaunch(decision);
      return;
    }
    _emit(gestures.up(t));
  }

  /// 매 프레임: 게이지 바늘 이동, 홀드 판정.
  void tick(double realDt, double t) {
    launch.update(realDt);
    if (phaseOf() == FlightPhase.flying) {
      _emit(gestures.tick(t));
    } else {
      gestures.reset();
    }
  }

  void reset() {
    launch.cancel();
    gestures.reset();
  }

  void _emit(List<FlightGesture> events) {
    for (final e in events) {
      if (unlocks.allows(e)) onGesture(e);
    }
  }
}
