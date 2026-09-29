import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/sim/flight_controls.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/flight_state.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §2 비행 중 조작 3종 + §5 부스터 공식 보정.
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);
  final spec = config.controls;

  FlightSimulator launched(UpgradeLevels lv, {double angleDeg = 45}) =>
      FlightSimulator(FlightParams.fromLevels(formulas, lv))
        ..launch(angleRad: angleDeg * math.pi / 180);

  /// 연료를 다 쓸 때까지 탭한다.
  void burnAll(FlightSimulator sim) {
    while (sim.boostTap()) {}
  }

  /// 최고점까지 진행.
  void toApex(FlightSimulator sim) {
    while (sim.state.vyMps > 0) {
      sim.step();
    }
  }

  group('부스터: 연료를 공중에서 다 쓰면 공식 거리(부스터 포함)와 같다', () {
    const steps = [0, 10, 30];
    for (final l in steps) {
      for (final b in [1, 5, 20, 40]) {
        for (final bo in [0, 15]) {
          final lv = UpgradeLevels.of({
            UpgradeType.launch: l,
            UpgradeType.aero: l,
            UpgradeType.boost: b,
            UpgradeType.bounce: bo,
          });
          test('고무줄·공기역학 $l · 부스터 $b · 바운스 $bo', () {
            final sim = launched(lv);
            burnAll(sim);
            final expected = formulas.expectedDistanceM(lv);
            expect(
              sim.runToStop().distanceM,
              closeTo(expected, expected * 0.002),
            );
          });
        }
      }
    }
  });

  test('Lv0 은 연료가 없어 부스터가 안 된다 (공식 부스터 거리 0)', () {
    final sim = launched(const UpgradeLevels.zero());
    expect(sim.state.fuelMaxSec, 0);
    expect(sim.boostTap(), isFalse);
  });

  test('탭 한 번에 연료를 탭 분량만큼 쓰고, 5번이면 바닥난다', () {
    final sim = launched(UpgradeLevels.of(const {UpgradeType.boost: 3}));
    expect(sim.state.fuelSec, spec.boostFuelSec);
    expect(sim.boostTap(), isTrue);
    expect(
      sim.state.fuelSec,
      closeTo(spec.boostFuelSec - spec.boostTapSec, 1e-9),
    );
    expect(sim.state.boosting, isTrue);
    var taps = 1;
    while (sim.boostTap()) {
      taps++;
    }
    expect(taps, (spec.boostFuelSec / spec.boostTapSec).round());
  });

  test('분사 중 착지하면 남은 분사는 사라진다 (공중에서 써야 함)', () {
    final lv = UpgradeLevels.of(const {UpgradeType.boost: 20});
    final low = launched(lv, angleDeg: 8);
    burnAll(low);
    final expected =
        formulas.expectedDistanceM(lv) * math.sin(16 * math.pi / 180);
    final full = formulas.boostDistanceM(lv);
    expect(low.runToStop().distanceM, lessThan(expected + full - 1));
  });

  test('정지 후에는 조작이 안 먹는다', () {
    final sim = launched(UpgradeLevels.of(const {UpgradeType.boost: 3}))
      ..runToStop();
    expect(sim.boostTap(), isFalse);
    expect(sim.dive(), isFalse);
  });

  group('볼 부풀리기 (낙하산 활공)', () {
    test('최고점에서 부풀리면 더 멀리, 더 오래 난다', () {
      const lv = UpgradeLevels.zero();
      final base = launched(lv).runToStop();
      final glide = launched(lv);
      toApex(glide);
      glide.setInflate(on: true);
      final end = glide.runToStop();
      expect(end.distanceM, greaterThan(base.distanceM * 1.1));
      expect(end.simTimeSec, greaterThan(base.simTimeSec));
    });

    test('부풀린 동안 낙하 속도는 수평 속도 × 활공비를 넘지 않는다', () {
      final sim = launched(const UpgradeLevels.zero());
      toApex(sim);
      sim.setInflate(on: true);
      while (sim.state.phase == FlightPhase.flying) {
        sim.step();
        if (sim.state.phase != FlightPhase.flying) break;
        expect(
          -sim.state.vyMps,
          lessThanOrEqualTo(spec.inflateGlideRatio * sim.state.vxMps + 1e-9),
        );
      }
    });

    test('부풀린 동안 수평 속도가 줄어든다', () {
      final sim = launched(const UpgradeLevels.zero());
      final vx0 = sim.state.vxMps;
      sim.setInflate(on: true);
      for (var i = 0; i < 30; i++) {
        sim.step();
      }
      expect(
        sim.state.vxMps,
        closeTo(vx0 * math.exp(-spec.inflateDragPerSec * 0.5), 1e-6),
      );
      expect(sim.state.inflating, isTrue);
    });

    test('발사 전에는 부풀릴 수 없다', () {
      final sim = FlightSimulator(
        FlightParams.fromLevels(formulas, const UpgradeLevels.zero()),
      )..setInflate(on: true);
      expect(sim.state.inflating, isFalse);
    });
  });

  group('급강하', () {
    test('낙하 속도가 수평 속도 × 비율 이상이 되고 더 빨리 떨어진다', () {
      const lv = UpgradeLevels.zero();
      final base = launched(lv).runToStop();
      final sim = launched(lv);
      toApex(sim);
      expect(sim.dive(), isTrue);
      expect(
        sim.state.vyMps,
        lessThanOrEqualTo(-spec.diveSpeedRatio * sim.state.vxMps),
      );
      expect(sim.state.diving, isTrue);
      final end = sim.runToStop();
      expect(end.simTimeSec, lessThan(base.simTimeSec));
      expect(end.distanceM, lessThan(base.distanceM));
    });

    test('급강하는 볼 부풀리기를 풀고, 급강하 중엔 부풀릴 수 없다', () {
      final sim = launched(const UpgradeLevels.zero())
        ..setInflate(on: true)
        ..dive();
      expect(sim.state.inflating, isFalse);
      sim.setInflate(on: true);
      expect(sim.state.inflating, isFalse);
    });

    test('땅에 닿으면 급강하가 끝난다', () {
      final sim = launched(UpgradeLevels.of(const {UpgradeType.bounce: 30}));
      toApex(sim);
      sim.dive();
      while (sim.state.bounces == 0) {
        sim.step();
      }
      expect(sim.state.diving, isFalse);
    });
  });

  test('같은 조작 순서면 결과가 같다 (결정론)', () {
    double run() {
      final sim = launched(
        UpgradeLevels.of(const {UpgradeType.boost: 8, UpgradeType.bounce: 5}),
      );
      for (var i = 0; i < 400 && sim.state.phase != FlightPhase.stopped; i++) {
        if (i == 10 || i == 40) sim.boostTap();
        if (i == 70) sim.setInflate(on: true);
        if (i == 120) sim.setInflate(on: false);
        if (i == 150) sim.dive();
        sim.step();
      }
      return sim.runToStop().distanceM;
    }

    expect(run(), run());
  });

  test('boost_cut_on_land 가 false 면 착지해도 분사가 남는다', () {
    FlightControls make({required bool cut}) => FlightControls(
      fuelMaxSec: 1.5,
      tapSec: 0.3,
      boostSpeedMps: 10,
      cutBoostOnLand: cut,
    )..tapBoost();
    expect((make(cut: true)..onGround()).boosting, isFalse);
    expect((make(cut: false)..onGround()).boosting, isTrue);
  });
}
