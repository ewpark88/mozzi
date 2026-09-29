import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_record.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/run/star_rules.dart';
import 'package:mozzi/game/boss_hud_info.dart';
import 'package:mozzi/ui/play/boss_hud.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/result/result_buttons.dart';
import 'package:mozzi/ui/result/result_panel.dart';
import 'package:mozzi/ui/strings.dart';
import 'package:mozzi/ui/upgrade/upgrade_screen.dart';
import 'package:mozzi/ui/world_map/world_map_screen.dart';

import '../helpers/balance_fixture.dart';

/// 월드맵·업그레이드·결과·보스 HUD 가 모든 가로 화면에서 깨지지 않는다 (ADR-011).
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);

  const screens = {
    '폰 20:9': Size(915, 412),
    '작은 폰': Size(568, 320),
    '태블릿 4:3': Size(1024, 768),
  };

  final progress = PlayerProgress(
    wallet: const Wallet(seeds: 1234),
    stages: const {
      '1-1': StageRecord(star1: true, star2: true, star3: true),
      '1-2': StageRecord(star1: true),
    },
  );

  const result = RunResult(
    stageId: '2-5',
    distanceM: 1830,
    previousBestM: 1900,
    distanceSeeds: 915,
    pickupSeeds: 42,
    comboMax: 4,
    stars: StarResult(cleared: false, star2: false, missions: [false]),
    bossLost: true,
  );

  Future<void> pump(WidgetTester tester, Size size, Widget child) async {
    tester.view
      ..physicalSize = size * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  screens.forEach((name, size) {
    testWidgets('월드맵 $name', (tester) async {
      await pump(
        tester,
        size,
        WorldMapScreen(
          config: config,
          progress: progress,
          onStage: (_) {},
          onUpgrades: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(Strings.totalStars(4, 45)), findsOneWidget);
      expect(find.text(Strings.worldLocked(8)), findsOneWidget);
    });

    testWidgets('업그레이드 $name', (tester) async {
      await pump(
        tester,
        size,
        UpgradeScreen(
          formulas: formulas,
          progress: progress,
          onBuy: (_) {},
          onBack: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(Strings.upgradeCost(10)), findsOneWidget);
    });

    testWidgets('결과 화면 + 보스 HUD $name', (tester) async {
      await pump(
        tester,
        size,
        Scaffold(
          body: LayoutBuilder(
            builder: (context, c) {
              final scale = hudScaleOf(c.biggest);
              return Stack(
                children: [
                  BossHud(
                    info: const BossHudInfo(
                      stageId: '2-5',
                      goalM: 2000,
                      mochiXM: 1200,
                      rivalXM: 1500,
                      meter: null,
                      rivalSide: 1,
                      lost: false,
                    ),
                    scale: scale,
                  ),
                  Center(
                    child: SingleChildScrollView(
                      child: ResultPanel(
                        result: result,
                        missionText: '대장보다 3초 이상 먼저 골인',
                        actions: ResultActions(
                          onRetry: () {},
                          onMap: () {},
                          onUpgrades: () {},
                          onAdDouble: () {},
                        ),
                        scale: scale,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(Strings.bossRivalWon), findsOneWidget);
      expect(
        find.textContaining(Strings.toBest(70)),
        findsOneWidget,
        reason: '1900−1830',
      );
      expect(find.text(Strings.adDouble(2)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });
  });
}
