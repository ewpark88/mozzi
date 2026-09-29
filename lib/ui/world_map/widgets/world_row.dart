import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_unlocks.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/strings.dart';
import 'package:mozzi/ui/world_map/widgets/stage_node.dart';

/// 월드 하나: 제목 + 스테이지 5개를 잇는 길. 잠겨 있으면 해금 조건.
class WorldRow extends StatelessWidget {
  const WorldRow({
    required this.world,
    required this.name,
    required this.stages,
    required this.progress,
    required this.unlocks,
    required this.next,
    required this.onStage,
    required this.scale,
    super.key,
  });

  final int world;
  final String name;
  final List<StageSpec> stages;
  final PlayerProgress progress;
  final StageUnlocks unlocks;

  /// 이어서 할 스테이지 (모찌 위치).
  final StageSpec next;
  final ValueChanged<StageSpec> onStage;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final open = unlocks.isWorldUnlocked(world, progress);
    final text = TextStyle(
      fontSize: 15 * scale,
      fontWeight: FontWeight.bold,
      color: MochiPalette.outline,
    );
    final mochiAt = stages.indexWhere((s) => s.id == next.id);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: open ? 0.7 : 0.35),
          borderRadius: BorderRadius.circular(14 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(8 * scale),
          child: Row(
            children: [
              SizedBox(
                width: 150 * scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Strings.worldTitle(world, name), style: text),
                    if (!open)
                      Text(
                        Strings.worldLocked(unlocks.starsNeeded(world)),
                        style: text.copyWith(fontSize: 12 * scale),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => _Path(
                    width: c.maxWidth,
                    stages: stages,
                    progress: progress,
                    unlocks: unlocks,
                    mochiAt: mochiAt,
                    onStage: onStage,
                    scale: scale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Path extends StatelessWidget {
  const _Path({
    required this.width,
    required this.stages,
    required this.progress,
    required this.unlocks,
    required this.mochiAt,
    required this.onStage,
    required this.scale,
  });

  final double width;
  final List<StageSpec> stages;
  final PlayerProgress progress;
  final StageUnlocks unlocks;

  /// 모찌가 있는 스테이지 순번 (이 월드가 아니면 −1).
  final int mochiAt;
  final ValueChanged<StageSpec> onStage;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final node = StageNode.sizeFor(scale);
    final gap = stages.length > 1 ? (width - node) / (stages.length - 1) : 0.0;
    return SizedBox(
      height: node * 1.9 + 18 * scale,
      child: Stack(
        children: [
          Positioned(
            left: node / 2,
            right: node / 2,
            top: node * 0.9 + node / 2 - 3 * scale,
            height: 6 * scale,
            child: const ColoredBox(color: BossPalette.mapPath),
          ),
          for (var i = 0; i < stages.length; i++)
            Positioned(
              left: i * gap,
              top: node * 0.9,
              child: StageNode(
                stage: stages[i],
                record: progress.stage(stages[i].id),
                unlocked: unlocks.isStageUnlocked(stages[i], progress),
                onTap: () => onStage(stages[i]),
                scale: scale,
              ),
            ),
          if (mochiAt >= 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              left: mochiAt * gap + node * 0.2,
              top: 0,
              child: MapMochi(size: node * 0.6),
            ),
        ],
      ),
    );
  }
}
