import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
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
        expect(find.text(Strings.tapToLaunch), findsOneWidget);
        expect(find.text(Strings.devLevels), findsOneWidget);
      });
    });
  });

  test('HUD 배율은 짧은 변 기준, 범위 제한', () {
    expect(hudScaleOf(const Size(844, 390)), 1);
    expect(hudScaleOf(const Size(568, 320)), closeTo(0.82, 0.01));
    expect(hudScaleOf(const Size(1366, 1024)), 1.6);
  });

  testWidgets('탭하면 발사되고, 정지하면 공식 거리와 같은 기록과 재도전 버튼이 나온다', (tester) async {
    await pumpPlay(tester, const Size(915, 412), dev: false);
    await tester.tapAt(const Offset(450, 200));
    // 시뮬 시간 약 2.2초 ÷ 시간 배율 → 실제 약 1.4초. 여유 있게 3초 진행.
    for (var i = 0; i < 180; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text(Strings.retry), findsOneWidget);
    final expected = formulas.expectedDistanceM(
      UpgradeLevels.of(const {UpgradeType.launch: 0}),
    );
    expect(find.text(Strings.distance(expected)), findsOneWidget);

    await tester.tap(find.text(Strings.retry));
    await tester.pump();
    await tester.pump();
    expect(find.text(Strings.tapToLaunch), findsOneWidget);
    expect(FlightPhase.values, contains(FlightPhase.ready));
  });
}
