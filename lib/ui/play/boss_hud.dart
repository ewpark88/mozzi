import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mozzi/game/boss_hud_info.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/strings.dart';

/// 보스 HUD (GDD §4 보스 스테이지 상세), 거리 표시 아래:
/// - 2-5: 0~2,000m 진행 바에 모찌·대장 위치
/// - 3-5: 훔친 씨앗 게이지
/// - 1-5: 고양이와의 거리
/// 보스가 화면 밖이면 화면 가장자리에 방향 표시.
class BossHud extends StatelessWidget {
  const BossHud({required this.info, required this.scale, super.key});

  final BossHudInfo? info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final b = info;
    if (b == null) return const SizedBox.shrink();
    final text = TextStyle(
      fontSize: 13 * scale,
      fontWeight: FontWeight.bold,
      color: MochiPalette.outline,
    );
    final rival = b.rivalXM;
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 58 * scale),
            child: switch (b.stageId) {
              '2-5' => _RaceBar(info: b, scale: scale, text: text),
              '3-5' => _Meter(ratio: b.meter ?? 0, scale: scale, text: text),
              _ when rival != null && rival > 0 => Text(
                Strings.catBehind(math.max(0, b.mochiXM - rival)),
                style: text,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
        if (b.rivalSide != 0 && !b.lost)
          Align(
            alignment: Alignment(b.rivalSide.toDouble(), -0.2),
            child: Padding(
              padding: EdgeInsets.all(8 * scale),
              child: Icon(
                b.rivalSide < 0
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 28 * scale,
                color: BossPalette.lost,
              ),
            ),
          ),
      ],
    );
  }
}

class _RaceBar extends StatelessWidget {
  const _RaceBar({required this.info, required this.scale, required this.text});

  final BossHudInfo info;
  final double scale;
  final TextStyle text;

  @override
  Widget build(BuildContext context) {
    final width = 260 * scale;
    double at(double xM) => (xM / info.goalM).clamp(0, 1) * width;
    Widget marker(double xM, String label, Color color) => Positioned(
      left: at(xM) - 20 * scale,
      top: 0,
      width: 40 * scale,
      child: Column(
        children: [
          Text(
            label,
            style: text.copyWith(fontSize: 10 * scale, color: color),
          ),
          Icon(Icons.circle, size: 10 * scale, color: color),
        ],
      ),
    );
    return SizedBox(
      width: width,
      height: 34 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 3 * scale,
            height: 4 * scale,
            child: const ColoredBox(color: BossPalette.meterBack),
          ),
          if (info.rivalXM case final r?)
            marker(r, Strings.rival, BossPalette.lost),
          marker(info.mochiXM, Strings.mochi, MochiPalette.backPatch),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.ratio, required this.scale, required this.text});

  final double ratio;
  final double scale;
  final TextStyle text;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(Strings.stolenMeter(ratio), style: text),
      SizedBox(
        width: 200 * scale,
        height: 10 * scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5 * scale),
          child: LinearProgressIndicator(
            value: ratio,
            color: BossPalette.meter,
            backgroundColor: BossPalette.meterBack,
          ),
        ),
      ),
    ],
  );
}
