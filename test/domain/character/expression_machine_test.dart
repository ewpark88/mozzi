import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/character/expression_machine.dart';
import 'package:mozzi/domain/character/mochi_expression.dart';

/// GDD §3 표정 9종 사용 시점 — 표정 전이.
void main() {
  late ExpressionMachine m;
  setUp(() => m = ExpressionMachine());

  test('대기 = 기본, 당기기 = 기대, 과충전 = 긴장, 취소하면 기본', () {
    expect(m.current, MochiExpression.idle);
    m.onPullStart();
    expect(m.current, MochiExpression.expect);
    m.onPull(overcharged: true);
    expect(m.current, MochiExpression.tense);
    m.onPull(overcharged: false);
    expect(m.current, MochiExpression.expect);
    m.onPullCancel();
    expect(m.current, MochiExpression.idle);
  });

  test('발사 = 환희, 씨앗 = 잠깐 빵빵 뒤 환희로', () {
    m
      ..onLaunch()
      ..onSeed();
    expect(m.current, MochiExpression.puff);
    m.tick(ExpressionMachine.puffSec + .01);
    expect(m.current, MochiExpression.joy);
  });

  test('발사 전에는 씨앗 표정이 없다', () {
    m.onSeed();
    expect(m.current, MochiExpression.idle);
  });

  test('장애물 = 어질, 세게 착지 = 어질, 살짝 착지 = 납작', () {
    m
      ..onLaunch()
      ..onObstacle();
    expect(m.current, MochiExpression.dizzy);
    m.tick(ExpressionMachine.dizzySec + .01);
    expect(m.current, MochiExpression.joy);
    m.onLand(ExpressionMachine.dizzyImpactMps + 1);
    expect(m.current, MochiExpression.dizzy);
    m.onLand(3);
    expect(m.current, MochiExpression.flat);
  });

  test('트램폴린 등에 튕기면 환희', () {
    m
      ..onLaunch()
      ..onLand(3)
      ..onBounceObject();
    expect(m.current, MochiExpression.joy);
  });

  test('판 끝: 신기록 = 뿌듯, 아니면 분발 — 결과 표정은 유지', () {
    m
      ..onLaunch()
      ..onFinish(newRecord: true);
    expect(m.current, MochiExpression.proud);
    m
      ..onLand(3)
      ..tick(5);
    expect(m.current, isNot(MochiExpression.joy));
    m
      ..reset()
      ..onLaunch()
      ..onFinish(newRecord: false);
    expect(m.current, MochiExpression.determined);
  });
}
