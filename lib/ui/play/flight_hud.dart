import 'package:flutter/material.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/app_theme.dart';
import 'package:mozzi/ui/strings.dart';

/// 비행 중 HUD: 부스터 연료 게이지 + 조작 안내 (GDD §2 비행 중 조작 3종).
/// 연료가 없는 레벨(부스터 Lv0)이면 게이지를 숨긴다.
class FlightHud extends StatelessWidget {
  const FlightHud({
    required this.state,
    required this.scale,
    required this.showInflate,
    required this.showDive,
    super.key,
  });

  final FlightState state;
  final double scale;
  final bool showInflate;
  final bool showDive;

  @override
  Widget build(BuildContext context) {
    final flying = state.phase == FlightPhase.flying;
    return Padding(
      padding: EdgeInsets.all(10 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (state.fuelMaxSec > 0) FuelGauge(state: state, scale: scale),
          if (flying) ...[
            SizedBox(height: 6 * scale),
            _Hint(
              text: [
                Strings.hintBoost,
                if (showInflate) Strings.hintInflate,
                if (showDive) Strings.hintDive,
              ].join('  ·  '),
              scale: scale,
            ),
          ],
        ],
      ),
    );
  }
}

/// 부스터 연료 막대 (2.5D 샘플 drawFuel).
class FuelGauge extends StatelessWidget {
  const FuelGauge({required this.state, required this.scale, super.key});

  final FlightState state;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final ratio = state.fuelMaxSec > 0
        ? (state.fuelSec / state.fuelMaxSec).clamp(0.0, 1.0)
        : 0.0;
    final width = 150 * scale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Strings.fuel,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.title,
            color: MochiPalette.outline,
          ),
        ),
        SizedBox(width: 6 * scale),
        Container(
          width: width,
          height: 16 * scale,
          padding: EdgeInsets.all(3 * scale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: MochiPalette.outline, width: 2 * scale),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ratio,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: state.boosting || ratio > 0
                    ? FxPalette.fuel
                    : FxPalette.fuelEmpty,
                borderRadius: BorderRadius.circular(5 * scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12 * scale),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 4 * scale,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12 * scale, color: MochiPalette.outline),
      ),
    ),
  );
}
