import 'package:flutter/material.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/play/grade_popup.dart';
import 'package:mozzi/ui/strings.dart';

/// 비행 중 HUD: 현재 거리, 발사 안내, 판정 팝업. 정지 후에는 결과 화면(ResultPanel).
class PlayHud extends StatelessWidget {
  const PlayHud({
    required this.state,
    required this.pulling,
    required this.lastLaunch,
    required this.scale,
    super.key,
  });

  final FlightState state;
  final bool pulling;
  final LaunchDecision? lastLaunch;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 8 * scale),
            child: _DistanceBadge(meters: state.distanceM, scale: scale),
          ),
        ),
        if (state.phase == FlightPhase.ready && !pulling)
          Align(
            // 모찌(지면선 80%)를 가리지 않게 하늘 쪽에 둔다
            alignment: const Alignment(0, -0.45),
            child: _Pill(text: Strings.pullHint, scale: scale),
          ),
        Align(
          alignment: const Alignment(-0.2, -0.1),
          child: GradePopup(decision: lastLaunch, scale: scale),
        ),
      ],
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.meters, required this.scale});

  final double meters;
  final double scale;

  @override
  Widget build(BuildContext context) => _Pill(
    text: Strings.distance(meters),
    scale: scale,
    fontSize: 26,
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.scale, this.fontSize = 16});

  final String text;
  final double scale;
  final double fontSize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(40 * scale),
      border: Border.all(color: MochiPalette.outline, width: 2 * scale),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 6 * scale,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize * scale,
          fontWeight: FontWeight.bold,
          color: MochiPalette.outline,
        ),
      ),
    ),
  );
}
