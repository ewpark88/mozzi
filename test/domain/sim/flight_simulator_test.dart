import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/sim/fixed_stepper.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §5 공식 ↔ 비행 시뮬 보정 (ADR-012). 부스터는 P4 에서 추가하므로 Lv 0.
void main() {
  final formulas = BalanceFormulas(loadDefaultBalance());

  FlightState fly(UpgradeLevels lv, {double angleDeg = 45, double mult = 1}) {
    final sim = FlightSimulator(FlightParams.fromLevels(formulas, lv))
      ..launch(angleRad: angleDeg * math.pi / 180, speedMultiplier: mult);
    return sim.runToStop();
  }

  test('Lv0 기준 발사는 공식 거리 22.96m 와 같다', () {
    final end = fly(const UpgradeLevels.zero());
    expect(end.phase, FlightPhase.stopped);
    expect(end.distanceM, closeTo(22.959, 0.01));
    expect(end.bounces, 1, reason: 'Lv0 바운스는 튀지 않고 바로 멈춤 (납작)');
  });

  group('조작 없는 45° 발사 거리 = 공식 d (고무줄·공기역학·바운스 조합)', () {
    const steps = [0, 5, 15, 30, 60];
    for (final l in steps) {
      for (final a in steps) {
        for (final b in steps) {
          final lv = UpgradeLevels.of({
            UpgradeType.launch: l,
            UpgradeType.aero: a,
            UpgradeType.bounce: b,
          });
          test('고무줄 $l · 공기역학 $a · 바운스 $b', () {
            final expected = formulas.expectedDistanceM(lv);
            expect(fly(lv).distanceM, closeTo(expected, expected * 0.001));
          });
        }
      }
    }
  });

  test('바운스 레벨이 있으면 튀다가 미끄러져 멈춘다', () {
    final lv = UpgradeLevels.of(const {UpgradeType.bounce: 10});
    final sim = FlightSimulator(FlightParams.fromLevels(formulas, lv))
      ..launch(angleRad: math.pi / 4);
    final phases = <FlightPhase>{};
    while (sim.state.phase != FlightPhase.stopped) {
      sim.step();
      phases.add(sim.state.phase);
    }
    expect(phases, containsAll([FlightPhase.flying, FlightPhase.sliding]));
    expect(sim.state.bounces, greaterThan(1));
  });

  test('45° 가 아닌 각도는 sin(2θ) 비율만큼 짧다', () {
    const lv = UpgradeLevels.zero();
    final at45 = fly(lv).distanceM;
    expect(
      fly(lv, angleDeg: 30).distanceM,
      closeTo(at45 * math.sin(math.pi / 3), 0.01),
    );
  });

  test('발사 속도 배율은 거리에 제곱으로 반영된다 (정확도 게이지 Q6 근거)', () {
    const lv = UpgradeLevels.zero();
    expect(
      fly(lv, mult: 1.15).distanceM,
      closeTo(fly(lv).distanceM * 1.15 * 1.15, 0.01),
    );
  });

  test('같은 입력이면 궤적이 매 스텝 같다 (결정론)', () {
    final lv = UpgradeLevels.of(const {
      UpgradeType.launch: 7,
      UpgradeType.bounce: 4,
    });
    List<double> trace() {
      final sim = FlightSimulator(FlightParams.fromLevels(formulas, lv))
        ..launch(angleRad: 0.7);
      final xs = <double>[];
      while (sim.state.phase != FlightPhase.stopped) {
        sim.step();
        xs.add(sim.state.xM);
      }
      return xs;
    }

    expect(trace(), trace());
  });

  test('두 번 발사할 수 없다', () {
    final sim = FlightSimulator(
      FlightParams.fromLevels(formulas, const UpgradeLevels.zero()),
    )..launch(angleRad: 1);
    expect(() => sim.launch(angleRad: 1), throwsStateError);
  });

  group('FixedStepper', () {
    test('30fps 와 60fps 가 같은 총 스텝 수를 낸다', () {
      int total(double frameDt, int frames) {
        final s = FixedStepper(stepDt: 1 / 60, timeScale: 1.6484);
        var n = 0;
        for (var i = 0; i < frames; i++) {
          n += s.advance(frameDt);
        }
        return n;
      }

      expect(total(1 / 30, 300), closeTo(total(1 / 60, 600), 1));
    });

    test('긴 멈춤 뒤에는 상한만큼만 진행한다', () {
      final s = FixedStepper(stepDt: 1 / 60, timeScale: 1);
      expect(s.advance(5), s.maxStepsPerFrame);
      expect(s.advance(0), 0);
    });
  });
}
