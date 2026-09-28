import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §2 콤보, §4 월드 테마 오브젝트 효과·스테이지 골.
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);

  LaunchDecision launch({
    double speedMult = 1,
    GaugeGrade grade = GaugeGrade.good,
  }) => LaunchDecision(
    angleRad: math.pi / 4,
    power: 1,
    judgement: GaugeJudgement(grade: grade, multiplier: 1, off: 0.5),
    speedMultiplier: speedMult,
  );

  RunSession session(
    List<WorldObject> objects, {
    UpgradeLevels levels = const UpgradeLevels.zero(),
    StageSpec? stage,
  }) => RunSession(
    formulas: formulas,
    levels: levels,
    stage: stage,
    runSeed: 0,
    field: ObjectField.fixed(objects),
  );

  WorldObject obj(int id, ObjectKind k, double x, double y) =>
      WorldObject(id: id, kind: k, xM: x, yM: y, scale: 1);

  /// Lv0 45° 궤적의 x 위치 높이 (모찌 아래쪽 기준).
  double trajY(double x) {
    const v = 15.0;
    final g = config.gravityMps2;
    return x - g * x * x / (v * v);
  }

  double centerY(double x) => trajY(x) + config.mochiRadiusM;

  test('오브젝트 없으면 RunSession 도 공식 거리와 같다', () {
    final s = session(const [])..launch(launch());
    expect(
      s.runToStop().distanceM,
      closeTo(formulas.expectedDistanceM(const UpgradeLevels.zero()), 0.01),
    );
  });

  test('씨앗: 먹을 때마다 개수·콤보가 오르고 값은 ×1.1씩 (GDD §2 콤보)', () {
    final s =
        session([
            for (var i = 0; i < 5; i++)
              obj(i, ObjectKind.seed, 3.0 + i, centerY(3.0 + i)),
          ])
          ..launch(launch())
          ..runToStop();
    expect(s.stats.seedsPicked, 5);
    expect(s.stats.comboMax, 5);
    final expected = [
      for (var k = 0; k < 5; k++) math.pow(1.1, k),
    ].reduce((a, b) => a + b);
    expect(s.stats.pickupValue, closeTo(expected, 1e-9));
    expect(s.stats.hits('seed'), 5);
  });

  test('착지하면 콤보가 초기화된다', () {
    final s = session(
      [obj(1, ObjectKind.seed, 5, centerY(5))],
      levels: UpgradeLevels.of(const {UpgradeType.bounce: 30}),
    )..launch(launch());
    while (s.state.bounces == 0) {
      s.step();
    }
    expect(s.stats.combo, 0);
    expect(s.stats.comboMax, 1);
  });

  test('트램폴린: 내려오다 닿으면 땅에 닿기 전에 크게 튕겨 더 멀리 간다', () {
    final base = session(const [])..launch(launch());
    final baseD = base.runToStop().distanceM;
    // Lv0 궤적은 x ≈ 22.4m 에서 판 높이(0.5m)로 내려온다
    final s = session([obj(1, ObjectKind.tramp, 22.6, 0)])..launch(launch());
    while (s.stats.hits('tramp') == 0 && s.state.phase == FlightPhase.flying) {
      s.step();
    }
    expect(s.stats.hits('tramp'), 1);
    expect(s.state.bounces, 0, reason: '땅이 아니라 트램폴린');
    expect(
      s.state.vyMps,
      greaterThanOrEqualTo(config.world.object(ObjectKind.tramp).p2),
    );
    expect(s.runToStop().distanceM, greaterThan(baseD + 5));
  });

  test('급강하로 트램폴린을 바로 맞히면 퍼펙트 (배율 1.5 × 1.2)', () {
    final s = session([obj(1, ObjectKind.tramp, 18.4, 0)])..launch(launch());
    while (s.state.xM < 16) {
      s.step();
    }
    s.dive();
    while (s.stats.hits('tramp') == 0 && s.state.phase == FlightPhase.flying) {
      s.step();
    }
    expect(s.stats.divePerfects, 1);
    expect(s.state.diving, isFalse);
  });

  test('풍선: 위로 12.1 m/s 이상', () {
    final s = session([obj(1, ObjectKind.balloon, 15, centerY(15))])
      ..launch(launch());
    while (s.stats.hits('balloon') == 0 &&
        s.state.phase == FlightPhase.flying) {
      s.step();
    }
    expect(s.state.vyMps, greaterThanOrEqualTo(12.1 - 0.2));
  });

  test('나뭇가지(장애물): 수평 15% 감속, 콤보는 안 쌓이고 비행은 계속', () {
    final s = session([obj(1, ObjectKind.branch, 8, centerY(8))])
      ..launch(launch());
    double? vxBefore;
    while (s.stats.hits('branch') == 0) {
      vxBefore = s.state.vxMps;
      s.step();
    }
    expect(s.state.vxMps, closeTo(vxBefore! * 0.85, 0.05));
    expect(s.stats.comboMax, 0);
    expect(s.state.phase, FlightPhase.flying);
  });

  test('광고판 +8, 까마귀는 3개 강탈', () {
    final s =
        session([
            obj(1, ObjectKind.billboard, 6, centerY(6)),
            obj(2, ObjectKind.crow, 12, centerY(12)),
          ])
          ..launch(launch())
          ..runToStop();
    expect(s.stats.hits('billboard'), 1);
    expect(s.stats.hits('crow'), 1);
    expect(s.stats.seedsPicked, 5);
  });

  test('빨간 우산: 3초 동안 낙하 속도 ≤ 수평 × 0.15', () {
    final s = session([obj(1, ObjectKind.umbrella, 11.5, centerY(11.5))])
      ..launch(launch());
    while (s.stats.hits('umbrella') == 0) {
      s.step();
    }
    for (var i = 0; i < 90 && s.state.phase == FlightPhase.flying; i++) {
      s.step();
      if (s.state.vyMps < 0) {
        expect(-s.state.vyMps, lessThanOrEqualTo(0.15 * s.state.vxMps + 0.2));
      }
    }
  });

  group('스테이지 골', () {
    final stage11 = config.world.stage(1, 1);

    test('1-1(25m): 조작 없이는 못 깨고, PERFECT 발사(×1.15)면 깬다 — GDD 설계 의도', () {
      final plain = session(const [], stage: stage11)
        ..launch(launch())
        ..runToStop();
      expect(plain.stats.goalTimeSec, isNull);
      final perfect = session(const [], stage: stage11)
        ..launch(launch(speedMult: math.sqrt(1.15), grade: GaugeGrade.perfect))
        ..runToStop();
      expect(perfect.stats.goalTimeSec, isNotNull);
      final stars = perfect.stars()!;
      expect(stars.cleared, isTrue);
      expect(stars.star3, isTrue, reason: '1-1 ★★★ = PERFECT 발사');
    });

    test('골을 넘는 순간의 연료 비율을 기록한다', () {
      final s =
          session(
              const [],
              stage: stage11,
              levels: UpgradeLevels.of(const {UpgradeType.boost: 2}),
            )
            ..launch(launch())
            ..boostTap()
            ..runToStop();
      expect(s.stats.fuelAtGoal, closeTo(1 - 0.3 / 1.5, 1e-9));
    });
  });
}
