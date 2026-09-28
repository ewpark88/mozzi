import 'package:flutter/material.dart';
import 'package:mozzi/domain/balance/stage_spec.dart';
import 'package:mozzi/domain/sim/flight_state.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/ui/play/grade_popup.dart';
import 'package:mozzi/ui/strings.dart';

/// 개발용 패널 (dev flavor 전용): 레벨 선택, 속도·고도·거리, 공식 거리 비교.
class DevPanel extends StatelessWidget {
  const DevPanel({
    required this.stages,
    required this.stage,
    required this.onStage,
    required this.state,
    required this.lastLaunch,
    required this.level,
    required this.formulaDistanceM,
    required this.onLevel,
    required this.scale,
    super.key,
  });

  static const List<int> levelChoices = [0, 10, 20, 40];

  /// 게임 화면을 가리지 않도록 폭 제한 (HUD 배율 1 기준 논리 px).
  static const double maxWidth = 300;

  /// 선택 가능한 스테이지 (MVP 월드 1~3).
  final List<StageSpec> stages;
  final StageSpec? stage;
  final ValueChanged<StageSpec?> onStage;
  final FlightState state;
  final LaunchDecision? lastLaunch;
  final int level;
  final double formulaDistanceM;
  final ValueChanged<int> onLevel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(fontSize: 12 * scale, color: Colors.black87);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth * scale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.all(8 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('${Strings.devStage} ', style: text),
                  DropdownButton<StageSpec?>(
                    value: stage,
                    isDense: true,
                    style: text,
                    items: [
                      DropdownMenuItem(
                        child: Text(Strings.devFree, style: text),
                      ),
                      for (final s in stages)
                        DropdownMenuItem(
                          value: s,
                          child: Text(s.id, style: text),
                        ),
                    ],
                    onChanged: onStage,
                  ),
                ],
              ),
              Text(Strings.devLevels, style: text),
              Wrap(
                spacing: 4 * scale,
                children: [
                  for (final lv in levelChoices)
                    ChoiceChip(
                      label: Text(Strings.devLevel(lv), style: text),
                      selected: lv == level,
                      onSelected: (_) => onLevel(lv),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              Text(
                'v ${state.vxMps.toStringAsFixed(1)} m/s · '
                'h ${state.yM.toStringAsFixed(1)} m · '
                '${state.phase.name} · 튐 ${state.bounces}',
                style: text,
              ),
              Text(Strings.devFormula(formulaDistanceM), style: text),
              if (lastLaunch case final d?)
                Text(
                  Strings.devLaunch(
                    gradeLabel(d.judgement.grade),
                    d.power,
                    d.distanceMultiplier,
                  ),
                  style: text,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
