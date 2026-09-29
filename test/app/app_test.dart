import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/core/env/app_env.dart';
import 'package:mozzi/data/fake/memory_save_store.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/ui/play/play_screen.dart';
import 'package:mozzi/ui/strings.dart';
import 'package:mozzi/ui/upgrade/upgrade_screen.dart';
import 'package:mozzi/ui/world_map/world_map_screen.dart';

import '../helpers/balance_fixture.dart';

void main() {
  late MemorySaveStore store;

  /// 화면 전환 애니메이션을 끝낸다 (월드맵 모찌·게임 루프는 계속 움직여 pumpAndSettle 불가).
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pumpApp(WidgetTester tester, {PlayerProgress? progress}) async {
    tester.view
      ..physicalSize = const Size(1830, 824)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    store = MemorySaveStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvProvider.overrideWithValue(
            const AppEnv(flavor: Flavor.prod, useFakeServices: true),
          ),
          balanceConfigProvider.overrideWithValue(loadDefaultBalance()),
          saveStoreProvider.overrideWithValue(store),
          if (progress != null)
            initialProgressProvider.overrideWithValue(progress),
        ],
        child: const MozziApp(),
      ),
    );
    await tester.pump();
  }

  testWidgets('앱은 월드맵으로 기동하고, 처음에는 1-1 만 열려 있다', (tester) async {
    await pumpApp(tester);
    expect(find.byType(WorldMapScreen), findsOneWidget);
    expect(find.text('1-1'), findsOneWidget);
    expect(find.text('1-2'), findsNothing, reason: '잠긴 스테이지는 자물쇠');
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('한 판 루프: 월드맵 → 1-1 발사 → 결과(씨앗 저장) → 업그레이드 구매 → 월드맵', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('1-1'));
    await settle(tester);
    expect(find.byType(PlayScreen), findsOneWidget);

    final pull = await tester.startGesture(const Offset(450, 200));
    await pull.moveBy(const Offset(-60, 60));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await pull.up();
    for (
      var i = 0;
      i < 1900 && find.text(Strings.retry).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text(Strings.retry), findsOneWidget, reason: '결과 화면');
    final saved = (await store.load())!;
    expect(saved.totalRuns, 1);
    expect(saved.wallet.seeds, greaterThan(0), reason: '실패해도 씨앗');
    expect(saved.stage('1-1').bestDistanceM, greaterThan(0));

    await tester.tap(find.text(Strings.upgrades));
    await settle(tester);
    expect(find.byType(UpgradeScreen), findsOneWidget);
    await tester.tap(find.text(Strings.back));
    await settle(tester);
    await tester.tap(find.byTooltip(Strings.worldMap));
    await settle(tester);
    expect(find.byType(WorldMapScreen), findsOneWidget);
  });

  testWidgets('업그레이드 화면에서 사면 씨앗이 줄고 레벨이 저장된다', (tester) async {
    await pumpApp(
      tester,
      progress: PlayerProgress(wallet: const Wallet(seeds: 30)),
    );
    await tester.tap(find.text(Strings.upgrades));
    await settle(tester);
    // 고무줄 Lv0 비용 10 (GDD §5)
    await tester.tap(find.text(Strings.upgradeCost(10)));
    await tester.pump();
    final saved = (await store.load())!;
    expect(saved.levels[UpgradeType.launch], 1);
    expect(saved.wallet.seeds, 20);
    expect(find.text(Strings.seedsWallet(20)), findsOneWidget);
  });

  test('번들 에셋에서 밸런스 기본값을 읽는다 (pubspec assets 등록 확인)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final config = await loadBalanceDefaults(rootBundle);
    expect(config.upgrade(UpgradeType.launch).baseCost, 10);
    expect(config.simTimeScale, greaterThan(1));
  });

  test('Provider 로 공식과 업그레이드 서비스를 얻는다', () {
    final container = ProviderContainer(
      overrides: [
        balanceConfigProvider.overrideWithValue(loadDefaultBalance()),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container
          .read(upgradeServiceProvider)
          .formulas
          .upgradeCost(UpgradeType.boost, 0),
      25,
    );
  });
}
