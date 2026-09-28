import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:mozzi/domain/sim/accuracy_gauge.dart';
import 'package:mozzi/domain/sim/launch_controller.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/game/viewport/virtual_viewport.dart';

/// 게이지를 그리는 데 필요한 값 (MozziGame 이 제공).
abstract interface class GaugeSource {
  LaunchController get launchController;
  VirtualViewport get viewport;

  /// 누적 실제 시간 (초). 반짝임·깜빡임·떨림용.
  double get clockSec;
}

/// 정확도 게이지 (GDD §2): 색 구간 트랙, PERFECT 반짝임, 바늘, 힘 바(100% 표시), 범례.
/// 과충전이면 빨간 막 깜빡임·테두리/바늘/힘 바 빨강·떨림. 2.5D 샘플 drawGauge 기준.
/// 당기는 동안만 보인다. 좌표는 샘플 가상 px × 화면 배율.
class GaugeComponent extends Component {
  GaugeComponent(this.source);

  final GaugeSource source;

  // 샘플 drawGauge 치수 (가상 px)
  static const double _w = 220;
  static const double _h = 20;
  static const double _aboveGround = 200;
  static const double _xShift = 20;

  static const List<(GaugeGrade, Color, Color)> _bands = [
    (GaugeGrade.miss, GaugePalette.miss, GaugePalette.missDark),
    (GaugeGrade.good, GaugePalette.good, GaugePalette.goodDark),
    (GaugeGrade.great, GaugePalette.great, GaugePalette.greatDark),
    (GaugeGrade.perfect, GaugePalette.perfect, GaugePalette.perfectDark),
  ];

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Map<String, TextPainter> _text = {};
  double _textScale = 0;

  double _bandMaxOff(GaugeGrade g) {
    final spec = source.launchController.spec;
    return switch (g) {
      GaugeGrade.perfect => spec.perfectOff,
      GaugeGrade.great => spec.greatOff,
      GaugeGrade.good => spec.goodOff,
      GaugeGrade.miss => 1,
    };
  }

  @override
  void render(Canvas canvas) {
    final ctl = source.launchController;
    if (ctl.phase != PullPhase.pulling) return;
    final vp = source.viewport;
    final s = vp.scale;
    final t = source.clockSec;
    final over = ctl.isOvercharged;
    final shake = over ? math.sin(t * 70) * 1.6 * (ctl.power - 1) / 0.1 : 0.0;
    final x =
        vp.screenWidth * VirtualViewport.focusXRatio +
        (_xShift - _w / 2) * s +
        shake * s;
    final y =
        vp.screenHeight * VirtualViewport.groundLineRatio - _aboveGround * s;
    final w = _w * s;
    final h = _h * s;

    // 패널
    _fill.color = over ? GaugePalette.panelWarn : GaugePalette.panel;
    _stroke
      ..color = over ? GaugePalette.warn : MochiPalette.outline
      ..strokeWidth = (over ? 3 : 2.5) * s;
    final panel = RRect.fromLTRBR(
      x - 12 * s,
      y - 32 * s,
      x + w + 12 * s,
      y + h + 40 * s,
      Radius.circular(12 * s),
    );
    canvas
      ..drawRRect(panel, _fill)
      ..drawRRect(panel, _stroke);

    // 트랙: 가운데로 갈수록 좋은 구간
    final track = RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(10 * s));
    canvas
      ..save()
      ..clipRRect(track);
    for (final (grade, color, _) in _bands) {
      final half = w / 2 * _bandMaxOff(grade);
      _fill.color = color;
      canvas.drawRect(
        Rect.fromLTRB(x + w / 2 - half, y, x + w / 2 + half, y + h),
        _fill,
      );
    }
    final pz = w / 2 * _bandMaxOff(GaugeGrade.perfect);
    final shine = (math.sin(t * 6) + 1) / 2;
    _fill.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: 0.25 + 0.35 * shine);
    canvas.drawRect(
      Rect.fromLTWH(x + w / 2 - pz, y + 2 * s, pz * 2, 5 * s),
      _fill,
    );
    if (over) {
      _fill.color = GaugePalette.warn.withValues(
        alpha: math.sin(t * 20) > 0 ? 0.32 : 0.18,
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), _fill);
    }
    canvas.restore();
    _stroke
      ..color = over ? GaugePalette.warn : MochiPalette.outline
      ..strokeWidth = 1.5 * s;
    canvas.drawRRect(track, _stroke);

    // 바늘
    final needle = ctl.gauge.needle;
    final band = ctl.gauge.judge(needle).grade;
    final dark = _bands.firstWhere((b) => b.$1 == band).$3;
    final nx = x + w * needle;
    _fill.color = over ? GaugePalette.warn : dark;
    final needleRect = RRect.fromLTRBR(
      nx - 3.5 * s,
      y - 8 * s,
      nx + 3.5 * s,
      y + h + 8 * s,
      Radius.circular(3.5 * s),
    );
    _stroke
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2 * s;
    canvas
      ..drawRRect(needleRect, _fill)
      ..drawRRect(needleRect, _stroke)
      ..drawPath(
        Path()
          ..moveTo(nx - 7 * s, y - 13 * s)
          ..lineTo(nx + 7 * s, y - 13 * s)
          ..lineTo(nx, y - 5 * s)
          ..close(),
        _fill,
      );

    _renderPowerBar(canvas, x, y + h + 12 * s, w, s, t);
    _renderLegend(canvas, x, y + h + 26 * s, s, over, maxWidth: w);
  }

  void _renderPowerBar(
    Canvas canvas,
    double x,
    double py,
    double w,
    double s,
    double t,
  ) {
    final ctl = source.launchController;
    final maxPower = ctl.spec.maxPower;
    final p100 = w / maxPower;
    final fill = w * ctl.power / maxPower;
    _fill.color = const Color(0x14000000);
    canvas.drawRRect(
      RRect.fromLTRBR(x, py, x + w, py + 7 * s, Radius.circular(3.5 * s)),
      _fill,
    );
    // 셰이더에도 Paint 색의 알파가 곱해지므로 불투명으로 되돌린 뒤 그라데이션을 건다
    _fill
      ..color = const Color(0xFFFFFFFF)
      ..shader = const LinearGradient(
        colors: [GaugePalette.powerLow, GaugePalette.powerFull],
      ).createShader(Rect.fromLTWH(x, py, p100, 7 * s));
    canvas.drawRRect(
      RRect.fromLTRBR(
        x,
        py,
        x + math.min(fill, p100),
        py + 7 * s,
        Radius.circular(3.5 * s),
      ),
      _fill,
    );
    _fill.shader = null;
    if (fill > p100) {
      _fill.color = math.sin(t * 20) > 0
          ? GaugePalette.warn
          : GaugePalette.warnDeep;
      canvas.drawRect(Rect.fromLTRB(x + p100, py, x + fill, py + 7 * s), _fill);
    }
    _stroke
      ..color = MochiPalette.outline
      ..strokeWidth = 1.5 * s;
    canvas.drawLine(
      Offset(x + p100, py - 3 * s),
      Offset(x + p100, py + 10 * s),
      _stroke,
    );
  }

  /// 범례: PERFECT ×배율 · GREAT · GOOD (게이지 아래, GDD §2). 과충전이면 “과충전!”.
  void _renderLegend(
    Canvas canvas,
    double x,
    double ly,
    double s,
    bool over, {
    required double maxWidth,
  }) {
    if (_textScale != s) {
      _text.clear();
      _textScale = s;
    }
    final spec = source.launchController.spec;
    final items = over
        ? [('과충전!', GaugePalette.warn)]
        : [
            ('PERFECT ×${spec.perfectMult}', GaugePalette.perfectDark),
            ('GREAT', GaugePalette.greatDark),
            ('GOOD', GaugePalette.goodDark),
          ];
    final painters = [
      for (final (label, color) in items)
        _text.putIfAbsent(label, () {
          return TextPainter(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: color,
                fontSize: 11.5 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
        }),
    ];
    final gap = 10 * s;
    final total =
        painters.fold<double>(0, (sum, tp) => sum + tp.width) +
        gap * (painters.length - 1);
    // 글꼴·화면에 따라 넘치면 패널 폭에 맞게 줄인다
    final fit = total > maxWidth ? maxWidth / total : 1.0;
    canvas
      ..save()
      ..translate(x, ly)
      ..scale(fit);
    var cx = 0.0;
    for (final tp in painters) {
      tp.paint(canvas, Offset(cx, 0));
      cx += tp.width + gap;
    }
    canvas.restore();
  }
}
