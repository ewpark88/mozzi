import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/progress_controller.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/progress/stage_unlocks.dart';
import 'package:mozzi/ui/dev/mochi_gallery_screen.dart';
import 'package:mozzi/ui/play/play_screen.dart';
import 'package:mozzi/ui/upgrade/upgrade_screen.dart';
import 'package:mozzi/ui/world_map/world_map_screen.dart';

/// 화면 흐름 (GDD §2·§4): 월드맵 → 플레이(결과 화면) → 재도전·다음·업그레이드·월드맵.
/// 화면(ui)은 값과 콜백만 받고, 진행 상태·서비스 연결은 여기서 한다.
class WorldMapRoute extends ConsumerWidget {
  const WorldMapRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => WorldMapScreen(
    config: ref.watch(balanceConfigProvider),
    progress: ref.watch(progressProvider),
    onStage: (stage) => unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlayRoute(stage: stage)),
      ),
    ),
    onUpgrades: () => unawaited(openUpgrades(context)),
    onGallery: ref.watch(appEnvProvider).isDev
        ? () => unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (c) =>
                    MochiGalleryScreen(onBack: () => Navigator.of(c).pop()),
              ),
            ),
          )
        : null,
  );
}

/// 업그레이드 화면을 연다 (닫히면 끝남).
Future<void> openUpgrades(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const UpgradeRoute()),
);

class PlayRoute extends ConsumerWidget {
  const PlayRoute({required this.stage, super.key});

  final StageSpec stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final config = ref.watch(balanceConfigProvider);
    final ctl = ref.read(progressProvider.notifier);
    final ads = ref.watch(adServiceProvider);
    return PlayScreen(
      formulas: ref.watch(balanceFormulasProvider),
      isDev: env.isDev,
      stage: stage,
      devStages: StageUnlocks(config.world).mapStages(),
      hooks: PlayHooks(
        setupFor: ctl.setupFor,
        onRunEnd: ctl.recordRun,
        nextStageOf: ctl.nextStageOf,
        onMap: () => Navigator.of(context).pop(),
        onUpgrades: () => openUpgrades(context),
        onAdDouble: ads.rewardedReady ? ctl.adDouble : null,
        adMultiplier: config.adRewardMultiplier,
      ),
    );
  }
}

class UpgradeRoute extends ConsumerWidget {
  const UpgradeRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => UpgradeScreen(
    formulas: ref.watch(balanceFormulasProvider),
    progress: ref.watch(progressProvider),
    onBuy: (t) => ref.read(progressProvider.notifier).buy(t),
    onBack: () => Navigator.of(context).pop(),
  );
}
