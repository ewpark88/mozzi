import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_unlocks.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/app_theme.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/strings.dart';
import 'package:mozzi/ui/world_map/widgets/world_row.dart';

/// 월드맵 (GDD §4): 월드별로 스테이지를 길로 잇고, 잠금·별·보스를 표시한다.
/// 이어서 할 스테이지 위에서 모찌가 통통 튄다. 잠긴 월드는 해금 조건을 보여준다.
class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({
    required this.config,
    required this.progress,
    required this.onStage,
    required this.onUpgrades,
    this.onGallery,
    super.key,
  });

  final BalanceConfig config;
  final PlayerProgress progress;
  final ValueChanged<StageSpec> onStage;
  final VoidCallback onUpgrades;

  /// 개발용 갤러리 (dev flavor 에서만 넘긴다).
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    final unlocks = StageUnlocks(config.world);
    final stages = unlocks.mapStages();
    final next = unlocks.nextStage(progress);
    return Scaffold(
      backgroundColor: BackyardPalette.skyBottom,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = hudScaleOf(constraints.biggest);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Column(
                children: [
                  _Header(
                    stars: progress.totalStars,
                    maxStars: stages.length * 3,
                    seeds: progress.wallet.seeds,
                    onUpgrades: onUpgrades,
                    onGallery: onGallery,
                    scale: scale,
                  ),
                  SizedBox(height: 6 * scale),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var w = 1; w <= StageUnlocks.playableWorlds; w++)
                          WorldRow(
                            world: w,
                            name: config.zones[w - 1].name,
                            stages: [
                              for (final s in stages)
                                if (s.world == w) s,
                            ],
                            progress: progress,
                            unlocks: unlocks,
                            next: next,
                            onStage: onStage,
                            scale: scale,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stars,
    required this.maxStars,
    required this.seeds,
    required this.onUpgrades,
    required this.onGallery,
    required this.scale,
  });

  final int stars;
  final int maxStars;
  final int seeds;
  final VoidCallback onUpgrades;
  final VoidCallback? onGallery;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(
      fontSize: 18 * scale,
      fontWeight: FontWeight.bold,
      fontFamily: AppFonts.title,
      color: MochiPalette.outline,
    );
    return Row(
      children: [
        Text(Strings.appTitle, style: text.copyWith(fontSize: 22 * scale)),
        if (onGallery != null)
          TextButton(onPressed: onGallery, child: const Text(Strings.gallery)),
        const Spacer(),
        Text(Strings.totalStars(stars, maxStars), style: text),
        SizedBox(width: 16 * scale),
        Text(Strings.seedsWallet(seeds), style: text),
        SizedBox(width: 16 * scale),
        FilledButton(
          onPressed: onUpgrades,
          style: FilledButton.styleFrom(
            backgroundColor: MochiPalette.backPatch,
          ),
          child: Text(Strings.upgrades, style: TextStyle(fontSize: 15 * scale)),
        ),
      ],
    );
  }
}
