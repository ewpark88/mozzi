import 'package:meta/meta.dart';
import 'package:mozzi/domain/balance/launch_spec.dart';

/// 정확도 판정 (GDD §2 판정 표). 선언 순서 = 좋은 순.
enum GaugeGrade { perfect, great, good, miss }

/// 놓은 순간의 판정 결과.
@immutable
class GaugeJudgement {
  const GaugeJudgement({
    required this.grade,
    required this.multiplier,
    required this.off,
  });

  final GaugeGrade grade;

  /// 발사 배율 (PERFECT 1.15 등).
  final double multiplier;

  /// 가운데에서 벗어난 정도 (0 = 정중앙, 1 = 끝).
  final double off;
}

/// 정확도 게이지: 당기는 동안 바늘이 트랙(0~1) 위를 왕복하고, 놓는 순간의 위치로 판정한다.
///
/// 바늘은 실제 시간(시뮬 시간 배율 적용 안 함)으로 움직인다 — 손으로 맞추는 조작이므로.
class AccuracyGauge {
  AccuracyGauge(this.spec);

  final LaunchSpec spec;

  /// 구간 경계 포함 판정용 여유 (0.5 − 0.45 = 0.0500…04 같은 부동소수 오차). GDD 구간은 경계 포함.
  static const double _boundaryEps = 1e-9;

  double _needle = 0;
  double _direction = 1;

  /// 바늘 위치 (0 = 왼쪽 끝, 0.5 = 가운데, 1 = 오른쪽 끝).
  double get needle => _needle;

  /// 당기기 시작: 왼쪽 끝에서 오른쪽으로 (샘플과 같음).
  void reset() {
    _needle = 0;
    _direction = 1;
  }

  /// 힘 [power] 일 때 바늘 속도 (트랙 너비/초). 과충전(>1)이면 급격히 빨라진다.
  double needleSpeed(double power) {
    final atFull = spec.needleSpeedBase + spec.needleSpeedK;
    if (power <= 1) return spec.needleSpeedBase + spec.needleSpeedK * power;
    return atFull * (1 + spec.overchargeK * (power - 1));
  }

  /// 실제 시간 [realDt] 만큼 바늘을 움직인다 (끝에서 반사).
  void advance(double realDt, double power) {
    _needle += _direction * needleSpeed(power) * realDt;
    // 한 프레임에 여러 번 반사될 만큼 빨라도 트랙 안으로 접는다
    while (_needle > 1 || _needle < 0) {
      if (_needle > 1) {
        _needle = 2 - _needle;
        _direction = -1;
      } else {
        _needle = -_needle;
        _direction = 1;
      }
    }
  }

  /// 바늘 위치 [needle] 의 판정.
  GaugeJudgement judge(double needle) {
    final off = ((needle - 0.5).abs() / 0.5).clamp(0.0, 1.0);
    if (off <= spec.perfectOff + _boundaryEps) {
      return GaugeJudgement(
        grade: GaugeGrade.perfect,
        multiplier: spec.perfectMult,
        off: off,
      );
    }
    if (off <= spec.greatOff + _boundaryEps) {
      return _band(
        GaugeGrade.great,
        off,
        spec.greatOff,
        spec.perfectOff,
        spec.greatMult,
      );
    }
    if (off <= spec.goodOff + _boundaryEps) {
      return _band(
        GaugeGrade.good,
        off,
        spec.goodOff,
        spec.greatOff,
        spec.goodMult,
      );
    }
    return _band(GaugeGrade.miss, off, 1, spec.goodOff, spec.missMult);
  }

  /// 구간 [outer]~[inner] 에서 바깥 경계 = 최소 배율, 안쪽 경계 = 최대 배율 선형 보간.
  GaugeJudgement _band(
    GaugeGrade grade,
    double off,
    double outer,
    double inner,
    (double, double) mult,
  ) {
    final t = (outer - off) / (outer - inner);
    return GaugeJudgement(
      grade: grade,
      multiplier: mult.$1 + (mult.$2 - mult.$1) * t,
      off: off,
    );
  }
}
