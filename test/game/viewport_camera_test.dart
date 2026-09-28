import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/camera/camera_rig.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

void main() {
  group('VirtualViewport (가로 고정 반응형, ADR-011)', () {
    test('가상 높이 540 고정, 너비는 화면 비율만큼', () {
      final cases = <(double, double), double>{
        (1024.0, 768.0): 720.0, // 태블릿 4:3
        (1280.0, 800.0): 864.0, // 태블릿 16:10
        (1920.0, 1080.0): 960.0, // 16:9 (샘플과 같음)
        (2400.0, 1080.0): 1200.0, // 20:9 폰
        (2520.0, 1080.0): 1260.0, // 21:9 폰
      };
      for (final MapEntry(key: screen, value: expectedWidth) in cases.entries) {
        final vp = VirtualViewport(
          screenWidth: screen.$1,
          screenHeight: screen.$2,
        );
        expect(
          vp.virtualWidth,
          closeTo(expectedWidth, 1e-9),
          reason: '$screen',
        );
        expect(
          vp.scale * VirtualViewport.virtualHeight,
          closeTo(screen.$2, 1e-9),
        );
      }
    });
  });

  group('CameraRig', () {
    const vp = VirtualViewport(screenWidth: 1920, screenHeight: 1080);
    FlightState at({double y = 0, double vx = 0}) => FlightState(
      phase: FlightPhase.flying,
      xM: 10,
      yM: y,
      vxMps: vx,
      vyMps: 0,
      simTimeSec: 0,
      bounces: 0,
      maxHeightM: y,
    );

    test('Lv0 속도·지면 근처에서는 기본 배율(샘플과 같은 화면 크기)', () {
      final rig = CameraRig(basePxPerM: 52.576, timeScale: 1.6484);
      expect(rig.targetPxPerM(at(vx: 10.6), vp), 52.576);
    });

    test('높이 올라가면 모찌가 화면 안에 들어오도록 줌아웃', () {
      final rig = CameraRig(basePxPerM: 52.576, timeScale: 1.6484);
      final target = rig.targetPxPerM(at(y: 100), vp);
      expect(
        (100 + CameraRig.headroomM) * target,
        lessThanOrEqualTo(vp.skyHeight),
      );
    });

    test('빠를수록 앞이 보이도록 줌아웃', () {
      final rig = CameraRig(basePxPerM: 52.576, timeScale: 1.6484);
      expect(
        rig.targetPxPerM(at(vx: 80), vp),
        lessThan(rig.targetPxPerM(at(vx: 20), vp)),
      );
    });

    test('줌은 부드럽게 따라간다', () {
      final rig = CameraRig(basePxPerM: 52.576, timeScale: 1.6484)
        ..update(at(y: 200), vp, 1 / 60);
      expect(rig.pxPerM, lessThan(52.576));
      expect(rig.pxPerM, greaterThan(rig.targetPxPerM(at(y: 200), vp)));
    });
  });
}
