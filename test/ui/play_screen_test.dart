import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/play/play_screen.dart';
import 'package:mozzi/ui/strings.dart';

import '../helpers/balance_fixture.dart';

void main() {
  final formulas = BalanceFormulas(loadDefaultBalance());

  Future<void> pumpPlay(
    WidgetTester tester,
    Size logical, {
    bool dev = true,
  }) async {
    tester.view
      ..physicalSize = logical * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: PlayScreen(formulas: formulas, isDev: dev),
      ),
    );
    await tester.pump();
  }

  /// 가로 모드 논리 해상도: 폰 16:9·20:9·21:9, 작은 폰, 태블릿 4:3·16:10 (ADR-011)
  const screens = {
    '폰 16:9': Size(740, 416),
    '폰 20:9': Size(915, 412),
    '폰 21:9': Size(960, 411),
    '작은 폰': Size(568, 320),
    '태블릿 4:3': Size(1024, 768),
    '태블릿 16:10': Size(1280, 800),
  };

  group('모든 화면 크기에서 레이아웃이 깨지지 않는다', () {
    screens.forEach((name, size) {
      testWidgets(name, (tester) async {
        await pumpPlay(tester, size);
        expect(tester.takeException(), isNull, reason: '오버플로 등 레이아웃 오류');
        expect(find.text(Strings.pullHint), findsOneWidget);
        expect(find.text(Strings.devLevels), findsOneWidget);
      });
    });
  });

  test('HUD 배율은 짧은 변 기준, 범위 제한', () {
    expect(hudScaleOf(const Size(844, 390)), 1);
    expect(hudScaleOf(const Size(568, 320)), closeTo(0.82, 0.01));
    expect(hudScaleOf(const Size(1366, 1024)), 1.6);
  });

  testWidgets('당겼다 놓으면 판정이 뜨고 발사되어, 정지하면 재도전 버튼이 나온다', (tester) async {
    await pumpPlay(tester, const Size(915, 412), dev: false);
    final gesture = await tester.startGesture(const Offset(450, 200));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text(Strings.pullHint), findsNothing, reason: '당기는 동안 안내 숨김');
    await gesture.moveBy(const Offset(-60, 60));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    final grades = [
      Strings.gradePerfect,
      Strings.gradeGreat,
      Strings.gradeGood,
      Strings.gradeMiss,
    ];
    expect(
      grades.any((g) => find.textContaining(g).evaluate().isNotEmpty),
      isTrue,
      reason: '판정 팝업',
    );
    // 오브젝트(트램폴린 등)로 비행 시간이 달라지므로 멈출 때까지 (최대 30초)
    for (
      var i = 0;
      i < 1900 && find.text(Strings.retry).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text(Strings.retry), findsOneWidget);
    expect(find.text(Strings.distance(0)), findsNothing, reason: '날아갔어야 함');

    await tester.tap(find.text(Strings.retry));
    await tester.pump();
    await tester.pump();
    expect(find.text(Strings.pullHint), findsOneWidget);
  });

  testWidgets('살짝 당겼다 놓으면 발사되지 않는다 (최소 힘 8%)', (tester) async {
    await pumpPlay(tester, const Size(915, 412), dev: false);
    final gesture = await tester.startGesture(const Offset(450, 200));
    await gesture.moveBy(const Offset(-3, 3));
    await gesture.up();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text(Strings.pullHint), findsOneWidget);
    expect(find.text(Strings.distance(0)), findsOneWidget);
  });

  testWidgets('비행 중 탭하면 부스터 연료가 줄고, 조작 안내가 보인다', (tester) async {
    await pumpPlay(tester, const Size(915, 412), dev: false);
    final pull = await tester.startGesture(const Offset(450, 200));
    await pull.moveBy(const Offset(-60, 60));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await pull.up();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.textContaining(Strings.hintBoost), findsOneWidget);
    double fuelFactor() => tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;
    expect(fuelFactor(), 1);
    // 채움 막대가 실제로 그려지는 크기인지 (높이 0 으로 사라지지 않게)
    final fill = tester.getSize(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(fill.height, greaterThan(4));
    expect(fill.width, greaterThan(50));
    await tester.tapAt(const Offset(600, 150));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(fuelFactor(), lessThan(1));
  });
}
