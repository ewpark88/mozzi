import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/flight_params.dart';
import 'package:mozzi/domain/sim/flight_simulator.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §2 당기기와 정확도 게이지.
void main() {
  final config = loadDefaultBalance();
  final spec = config.launch;

  group('바늘 속도 (GDD 표)', () {
    final gauge = AccuracyGauge(spec);
    final table = <double, double>{
      0.0: 0.45,
      0.5: 1.1,
      1.0: 1.8,
      1.05: 2.6,
      1.1: 3.4,
    };
    for (final MapEntry(key: power, value: speed) in table.entries) {
      test('힘 ${(power * 100).round()}% → $speed 트랙/초', () {
        expect(gauge.needleSpeed(power), closeTo(speed, 0.03));
      });
    }
  });

  group('판정 (GDD 표: 구간·배율)', () {
    final gauge = AccuracyGauge(spec);
    GaugeJudgement at(double needle) => gauge.judge(needle);

    test('트랙 0.45~0.55 는 PERFECT ×1.15', () {
      for (final n in [0.45, 0.5, 0.55]) {
        expect(at(n).grade, GaugeGrade.perfect, reason: '$n');
        expect(at(n).multiplier, 1.15);
      }
    });

    test('GREAT 0.35~0.45: 바깥 1.03 → 안쪽 1.13 (ADR-013)', () {
      expect(at(0.35).grade, GaugeGrade.great);
      expect(at(0.35).multiplier, closeTo(1.03, 1e-9));
      expect(at(0.449).multiplier, closeTo(1.13, 0.002));
    });

    test('GOOD 0.20~0.35: 0.95 → 1.03', () {
      expect(at(0.2).grade, GaugeGrade.good);
      expect(at(0.2).multiplier, closeTo(0.95, 1e-9));
      expect(at(0.349).multiplier, closeTo(1.03, 0.002));
    });

    test('아쉬워요 0~0.20: 0.80 → 0.95', () {
      expect(at(0).grade, GaugeGrade.miss);
      expect(at(0).multiplier, closeTo(0.8, 1e-9));
      expect(at(0.199).multiplier, closeTo(0.95, 0.002));
    });

    test('좌우 대칭', () {
      for (final n in [0.05, 0.25, 0.4, 0.47]) {
        expect(at(n).multiplier, closeTo(at(1 - n).multiplier, 1e-9));
        expect(at(n).grade, at(1 - n).grade);
      }
    });

    test('구간 경계에서 배율이 끊기지 않는다 (PERFECT 제외)', () {
      expect(at(0.35 - 1e-9).multiplier, closeTo(at(0.35).multiplier, 1e-6));
      expect(at(0.2 - 1e-9).multiplier, closeTo(at(0.2).multiplier, 1e-6));
    });
  });

  group('바늘 왕복', () {
    test('끝에서 반사되고 트랙 밖으로 나가지 않는다', () {
      final gauge = AccuracyGauge(spec)..reset();
      final positions = <double>[];
      for (var i = 0; i < 600; i++) {
        gauge.advance(1 / 60, 1.1);
        positions.add(gauge.needle);
      }
      expect(positions.every((p) => p >= 0 && p <= 1), isTrue);
      expect(positions.reduce(math.max), greaterThan(0.95));
      expect(positions.reduce(math.min), lessThan(0.05));
    });

    test('같은 입력이면 같은 위치 (결정론)', () {
      double run() {
        final g = AccuracyGauge(spec)..reset();
        for (var i = 0; i < 97; i++) {
          g.advance(1 / 60, 0.7);
        }
        return g.needle;
      }

      expect(run(), run());
    });
  });

  group('당기기 → 발사', () {
    test('최대 당김에서 힘 110%, 그 이상은 잘린다', () {
      final c = LaunchController(spec)
        ..start(500, 300)
        ..move(500 - 400, 300 + 300);
      expect(c.power, closeTo(1.1, 1e-9));
      final (px, py) = c.pull;
      expect(math.sqrt(px * px + py * py), closeTo(spec.pullMaxPx, 1e-9));
    });

    test('왼쪽 아래로 당기면 오른쪽 위로 날아간다 (45°)', () {
      final c = LaunchController(spec);
      expect(c.launchAngle(-100, 100), closeTo(math.pi / 4, 1e-9));
    });

    test('앞으로만 난다: 아래로 향하면 0°, 너무 가파르면 최대 각', () {
      final c = LaunchController(spec);
      expect(c.launchAngle(-100, -50), 0);
      expect(
        c.launchAngle(100, 100),
        closeTo(spec.maxAngleDeg * math.pi / 180, 1e-9),
      );
    });

    test('너무 약하게 놓으면 발사 취소', () {
      final c = LaunchController(spec)
        ..start(0, 0)
        ..move(-5, 5);
      expect(c.release(), isNull);
      expect(c.phase, PullPhase.idle);
    });

    test('놓는 순간 바늘 위치로 판정해 발사 배율을 정한다', () {
      final c = LaunchController(spec)
        ..start(0, 0)
        ..move(-106, 106); // 길이 150 → 110%
      // 110% 바늘 속도 3.42 트랙/초 → 0.5 도달까지 약 0.146초
      for (var i = 0; i < 9; i++) {
        c.update(1 / 60);
      }
      final d = c.release()!;
      expect(d.power, closeTo(1.1, 0.01));
      expect(d.judgement.grade, GaugeGrade.perfect);
    });
  });

  group('거리 배율 (ADR-013: 힘×판정 배율이 거리에 곱해짐)', () {
    final formulas = BalanceFormulas(config);
    double distance(double speedMultiplier) {
      final sim = FlightSimulator(
        FlightParams.fromLevels(formulas, const UpgradeLevels.zero()),
      )..launch(angleRad: math.pi / 4, speedMultiplier: speedMultiplier);
      return sim.runToStop().distanceM;
    }

    test('110% + PERFECT = 기본(100%·배율 1) 대비 ×1.265 (GDD "최대 거리 ×1.27")', () {
      final best = math.pow(1.1 * 1.15, spec.speedExponent).toDouble();
      expect(distance(best) / distance(1), closeTo(1.265, 0.001));
    });

    test('100% + PERFECT = ×1.15', () {
      final perfect = math.pow(1.15, spec.speedExponent).toDouble();
      expect(distance(perfect) / distance(1), closeTo(1.15, 0.001));
    });
  });
}
