import 'package:mozzi/domain/character/mochi_expression.dart';

/// 모찌 표정 상태 머신 (GDD §3 표정 9종 사용 시점, 샘플 setExpr 호출 위치).
///
/// 게임 이벤트를 받아 표정과 지속 시간을 정한다. 지속 시간이 끝나면 지금 단계의
/// 기본 표정(대기 = 기본, 비행 = 환희)으로 돌아간다. 판이 끝나면 결과 표정을 유지한다.
class ExpressionMachine {
  /// 씨앗을 먹을 때 빵빵 (샘플 .35초).
  static const double puffSec = .35;

  /// 세게 부딪히거나 떨어지면 어질 (샘플 .8초).
  static const double dizzySec = .8;

  /// 착지 순간 납작 (샘플 .28초).
  static const double flatSec = .28;

  /// 이보다 세게 떨어지면 어질 (m/s, 샘플 1500 px/s ≈ 17 m/s).
  static const double dizzyImpactMps = 17;

  MochiExpression _current = MochiExpression.idle;
  double _timer = 0;
  bool _flying = false;
  bool _finished = false;

  MochiExpression get current => _current;

  void _set(MochiExpression e, [double sec = 0]) {
    _current = e;
    _timer = sec;
  }

  /// 새 판.
  void reset() {
    _flying = false;
    _finished = false;
    _set(MochiExpression.idle);
  }

  /// 당기기 시작 → 기대.
  void onPullStart() => _set(MochiExpression.expect);

  /// 당기는 중: 110% 과충전이면 긴장, 아니면 기대.
  void onPull({required bool overcharged}) =>
      _set(overcharged ? MochiExpression.tense : MochiExpression.expect);

  /// 약하게 놓아 발사 취소 → 기본.
  void onPullCancel() => _set(MochiExpression.idle);

  /// 발사 → 환희.
  void onLaunch() {
    _flying = true;
    _set(MochiExpression.joy);
  }

  /// 씨앗 획득 → 잠깐 빵빵.
  void onSeed() {
    if (_flying) _set(MochiExpression.puff, puffSec);
  }

  /// 트램폴린·풍선 등에 튕김 → 환희.
  void onBounceObject() => _set(MochiExpression.joy);

  /// 장애물 충돌 → 어질.
  void onObstacle() => _set(MochiExpression.dizzy, dizzySec);

  /// 땅에 닿음: 세게면 어질, 아니면 납작.
  void onLand(double impactMps) => impactMps > dizzyImpactMps
      ? _set(MochiExpression.dizzy, dizzySec)
      : _set(MochiExpression.flat, flatSec);

  /// 판 끝: 신기록이면 뿌듯, 아니면 분발.
  void onFinish({required bool newRecord}) {
    _flying = false;
    _finished = true;
    _set(newRecord ? MochiExpression.proud : MochiExpression.determined);
  }

  void tick(double dt) {
    if (_timer <= 0 || _finished) return;
    _timer -= dt;
    if (_timer <= 0) {
      _set(_flying ? MochiExpression.joy : MochiExpression.idle);
    }
  }
}
