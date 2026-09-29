import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/data/fake/silent_sound_service.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/onboarding/onboarding.dart';
import 'package:mozzi/domain/services/sound_service.dart';
import 'package:mozzi/game/run_setup.dart';
import 'package:mozzi/ui/play/play_hooks.dart';
import 'package:mozzi/ui/play/play_screen.dart';
import 'package:mozzi/ui/strings.dart';

import '../helpers/balance_fixture.dart';

/// GDD §9 온보딩 안내·무료 업그레이드, §3 사운드 (발사·고무 소리·착지).
void main() {
  final formulas = BalanceFormulas(loadDefaultBalance());
  final stage = formulas.config.world.stage(1, 2);

  late SilentSoundService sound;
  late int claimed;

  Future<void> pump(
    WidgetTester tester, {
    OnboardingHint? hint,
    bool free = false,
    bool adHighlight = false,
  }) async {
    tester.view
      ..physicalSize = const Size(1830, 824)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    sound = SilentSoundService();
    claimed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayScreen(
          formulas: formulas,
          isDev: false,
          stage: stage,
          hooks: PlayHooks(
            setupFor: (s) => RunSetup(
              stage: s,
              levels: UpgradeLevels.of(const {UpgradeType.boost: 1}),
              hint: hint,
            ),
            onRunEnd: (_) {},
            nextStageOf: (_) => null,
            onMap: () {},
            onUpgrades: () async {},
            onAdDouble: (_) async => true,
            sound: sound,
            freeUpgrade: () => free && claimed == 0 ? UpgradeType.boost : null,
            onClaimFreeUpgrade: () => claimed++,
            highlightAdOffer: () => adHighlight,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> launch(WidgetTester tester) async {
    final g = await tester.startGesture(const Offset(450, 200));
    await g.moveBy(const Offset(-60, 60));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(sound.looping, contains(Sfx.squeak), reason: '당기는 동안 고무 소리');
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> untilResult(WidgetTester tester) async {
    for (
      var i = 0;
      i < 1900 && find.text(Strings.retry).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('발사하면 휘익, 착지하면 뿅, 고무 소리는 멈춘다', (tester) async {
    await pump(tester);
    await launch(tester);
    expect(sound.played, contains(Sfx.release));
    expect(sound.looping, isNot(contains(Sfx.squeak)));
    await untilResult(tester);
    expect(sound.played, contains(Sfx.land));
  });

  testWidgets('2판 안내: 비행 중에 부스터 탭 안내', (tester) async {
    await pump(tester, hint: OnboardingHint.boost);
    expect(find.text(Strings.tutorialBoost), findsNothing);
    await launch(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(Strings.tutorialBoost), findsOneWidget);
  });

  testWidgets('5판 안내: 발사 전 PERFECT 안내', (tester) async {
    await pump(tester, hint: OnboardingHint.perfect);
    expect(find.text(Strings.tutorialPerfect), findsOneWidget);
    expect(find.text(Strings.pullHint), findsNothing);
  });

  testWidgets('결과 화면: 첫 무료 업그레이드는 한 번만, 3판은 광고 2배 안내', (
    tester,
  ) async {
    await pump(tester, free: true, adHighlight: true);
    await launch(tester);
    await untilResult(tester);
    final label = Strings.freeUpgrade(Strings.upgradeName('upg_boost'));
    expect(find.text(label), findsOneWidget);
    expect(find.text(Strings.adOfferHint), findsOneWidget);
    await tester.tap(find.text(label));
    await tester.pump();
    expect(claimed, 1);
    expect(find.text(Strings.pullHint), findsOneWidget, reason: '새 판 준비');
  });
}
