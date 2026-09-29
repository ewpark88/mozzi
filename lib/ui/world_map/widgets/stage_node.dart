import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/progress/stage_record.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/app_theme.dart';
import 'package:mozzi/ui/strings.dart';

/// 월드맵의 스테이지 칸: 번호, 별 3개, 보스 표시. 잠기면 회색·자물쇠.
class StageNode extends StatelessWidget {
  const StageNode({
    required this.stage,
    required this.record,
    required this.unlocked,
    required this.onTap,
    required this.scale,
    super.key,
  });

  final StageSpec stage;
  final StageRecord record;
  final bool unlocked;
  final VoidCallback onTap;
  final double scale;

  static double sizeFor(double scale) => 46 * scale;

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(scale);
    final fill = !unlocked
        ? BossPalette.mapNodeLocked
        : record.cleared
        ? BossPalette.mapNodeCleared
        : BossPalette.mapNode;
    final text = TextStyle(
      fontSize: 13 * scale,
      fontWeight: FontWeight.bold,
      fontFamily: AppFonts.title,
      color: MochiPalette.outline,
    );
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: stage.boss
                      ? BossPalette.mapBoss
                      : MochiPalette.outline,
                  width: (stage.boss ? 4 : 2) * scale,
                ),
              ),
              child: unlocked
                  ? Text(stage.id, style: text)
                  : Icon(Icons.lock_rounded, size: 18 * scale),
            ),
            Text(
              stage.boss && !record.cleared
                  ? Strings.stageBoss
                  : [
                      record.star1,
                      record.star2,
                      record.star3,
                    ].map((s) => s ? '★' : '☆').join(),
              style: text.copyWith(
                fontSize: 11 * scale,
                color: stage.boss && !record.cleared
                    ? BossPalette.mapBoss
                    : BossPalette.star,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 월드맵의 모찌: 이어서 할 스테이지 위에서 통통 튄다 (GDD §4 월드맵).
class MapMochi extends StatefulWidget {
  const MapMochi({required this.size, super.key});

  final double size;

  @override
  State<MapMochi> createState() => _MapMochiState();
}

class _MapMochiState extends State<MapMochi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _bounce,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        -widget.size * 0.25 * Curves.easeOut.transform(_bounce.value),
      ),
      child: child,
    ),
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: MochiPalette.body,
        shape: BoxShape.circle,
        border: Border.all(color: MochiPalette.outline, width: 2),
      ),
    ),
  );
}
