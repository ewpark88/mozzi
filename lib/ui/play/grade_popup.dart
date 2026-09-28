import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/strings.dart';

/// 판정 이름 (GDD §2 판정 표).
String gradeLabel(GaugeGrade g) => switch (g) {
  GaugeGrade.perfect => Strings.gradePerfect,
  GaugeGrade.great => Strings.gradeGreat,
  GaugeGrade.good => Strings.gradeGood,
  GaugeGrade.miss => Strings.gradeMiss,
};

Color gradeColor(GaugeGrade g) => switch (g) {
  GaugeGrade.perfect => GaugePalette.perfectDark,
  GaugeGrade.great => GaugePalette.greatDark,
  GaugeGrade.good => GaugePalette.goodDark,
  GaugeGrade.miss => GaugePalette.missDark,
};

/// 발사 순간 판정 팝업: 떠오르며 사라진다 (샘플 texts, 1.1초). 과충전이면 힘 % 를 붙인다.
class GradePopup extends StatefulWidget {
  const GradePopup({required this.decision, required this.scale, super.key});

  final LaunchDecision? decision;
  final double scale;

  static const Duration duration = Duration(milliseconds: 1100);

  @override
  State<GradePopup> createState() => _GradePopupState();
}

class _GradePopupState extends State<GradePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: GradePopup.duration);
  }

  @override
  void didUpdateWidget(GradePopup old) {
    super.didUpdateWidget(old);
    if (widget.decision != null && widget.decision != old.decision) {
      unawaited(_anim.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.decision;
    if (d == null) return const SizedBox.shrink();
    final grade = d.judgement.grade;
    final text =
        gradeLabel(grade) + (d.power > 1 ? Strings.overPower(d.power) : '');
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        if (!_anim.isAnimating && t >= 1) return const SizedBox.shrink();
        return Opacity(
          opacity: (1 - t).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -40 * widget.scale * t),
            child: Text(
              text,
              style: TextStyle(
                fontSize:
                    (grade == GaugeGrade.perfect ? 34 : 26) * widget.scale,
                fontWeight: FontWeight.w900,
                color: gradeColor(grade),
                shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
              ),
            ),
          ),
        );
      },
    );
  }
}
