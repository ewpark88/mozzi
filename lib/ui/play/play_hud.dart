import 'package:flutter/material.dart';
import 'package:mozzi/domain/onboarding/onboarding.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/app_theme.dart';
import 'package:mozzi/ui/play/grade_popup.dart';
import 'package:mozzi/ui/strings.dart';

/// 비행 중 HUD: 현재 거리, 발사 안내, 판정 팝업. 정지 후에는 결과 화면(ResultPanel).
class PlayHud extends StatelessWidget {
  const PlayHud({
    required this.state,
    required this.pulling,
    required this.lastLaunch,
    required this.scale,
    this.hint,
    super.key,
  });

  final FlightState state;
  final bool pulling;
  final LaunchDecision? lastLaunch;
  final double scale;

  /// 이번 판 온보딩 안내 (GDD §9).
  final OnboardingHint? hint;

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
        if (_hintText() case final text?)
          Align(
            // 모찌(지면선 80%)를 가리지 않게 하늘 쪽에 둔다
            alignment: const Alignment(0, -0.45),
            child: _Pill(text: text, scale: scale),
          ),
        Align(
          alignment: const Alignment(-0.2, -0.1),
          child: GradePopup(decision: lastLaunch, scale: scale),
        ),
      ],
    );
  }
}

extension on PlayHud {
  /// 발사 전 = 당기기 안내(5판은 PERFECT 안내), 비행 중 2판 = 부스터 안내.
  String? _hintText() => switch (state.phase) {
    FlightPhase.ready when hint == OnboardingHint.perfect =>
      Strings.tutorialPerfect,
    FlightPhase.ready when !pulling => Strings.pullHint,
    FlightPhase.flying when hint == OnboardingHint.boost =>
      Strings.tutorialBoost,
    _ => null,
  };
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
          fontFamily: AppFonts.title,
          color: MochiPalette.outline,
        ),
      ),
    ),
  );
}
