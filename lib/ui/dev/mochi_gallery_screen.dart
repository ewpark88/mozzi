import 'package:flutter/material.dart';
import 'package:mozzi/domain/character/mochi_expression.dart';
import 'package:mozzi/game/render/mochi/mochi_face.dart';
import 'package:mozzi/game/render/mochi/mochi_painter.dart';
import 'package:mozzi/game/render/palette.dart';
import 'package:mozzi/ui/play/hud_scale.dart';
import 'package:mozzi/ui/strings.dart';

/// 개발용 갤러리 (dev flavor 전용, DEV_PLAN P7): 표정 9종 × 월드 조명 비교.
/// 샘플 HTML 과 나란히 놓고 2.5D 품질을 반복 개선하는 용도.
class MochiGalleryScreen extends StatefulWidget {
  const MochiGalleryScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  /// 비교할 월드 조명 (뒷마당 아침·공원·도시 노을).
  static const List<WorldPalette> lights = [
    WorldPalette.backyard,
    WorldPalette.park,
    WorldPalette.city,
  ];

  @override
  State<MochiGalleryScreen> createState() => _MochiGalleryScreenState();
}

class _MochiGalleryScreenState extends State<MochiGalleryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();
  bool _lowSpec = false;
  bool _fly = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, c) {
        final scale = hudScaleOf(c.biggest);
        return SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(Strings.back),
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text(Strings.galleryFly),
                    selected: _fly,
                    onSelected: (v) => setState(() => _fly = v),
                  ),
                  SizedBox(width: 8 * scale),
                  FilterChip(
                    label: const Text(Strings.galleryLowSpec),
                    selected: _lowSpec,
                    onSelected: (v) => setState(() => _lowSpec = v),
                  ),
                  SizedBox(width: 8 * scale),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    for (final light in MochiGalleryScreen.lights)
                      Expanded(
                        child: Row(
                          children: [
                            for (final e in MochiExpression.values)
                              Expanded(
                                child: _Cell(
                                  expression: e,
                                  light: light,
                                  lowSpec: _lowSpec,
                                  fly: _fly,
                                  clock: _clock,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.expression,
    required this.light,
    required this.lowSpec,
    required this.fly,
    required this.clock,
  });

  final MochiExpression expression;
  final WorldPalette light;
  final bool lowSpec;
  final bool fly;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light.skyTop, light.skyBottom],
      ),
    ),
    child: CustomPaint(
      painter: MochiPreviewPainter(
        expression: expression,
        rim: light.rim,
        lowSpec: lowSpec,
        fly: fly,
        clock: clock,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

/// 갤러리 칸 하나: 모찌 몸 + 얼굴을 칸 크기에 맞춰 그린다.
class MochiPreviewPainter extends CustomPainter {
  MochiPreviewPainter({
    required this.expression,
    required this.rim,
    required this.lowSpec,
    required this.fly,
    required this.clock,
  }) : super(repaint: clock);

  final MochiExpression expression;
  final Color rim;
  final bool lowSpec;
  final bool fly;
  final Animation<double> clock;

  final MochiBodyPainter _body = MochiBodyPainter();
  final MochiFace _face = MochiFace();

  /// 샘플 단위 모찌가 칸에 들어가는 크기 (귀·발 포함 약 110).
  static const double _fitUnits = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.shortestSide / _fitUnits).clamp(0.1, 10.0);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(s);
    _body.paint(canvas, fly: fly, cheek: 1, rim: rim, lowSpec: lowSpec);
    _face.paint(canvas, expression, t: clock.value * 10);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MochiPreviewPainter old) =>
      old.expression != expression ||
      old.rim != rim ||
      old.lowSpec != lowSpec ||
      old.fly != fly;
}
