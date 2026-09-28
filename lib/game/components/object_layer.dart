import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/render/palette.dart';

/// 오브젝트를 그리는 쪽이 필요로 하는 값 (MozziGame 이 제공).
abstract interface class ObjectSource {
  ObjectField get objectField;
  WorldConfig get worldConfig;
  double get clockSec;
}

/// 월드 오브젝트 (월드 레이어, 플레이스홀더 코드 도형 — P7 에서 2.5D 셰이딩).
/// 카메라에 보이는 범위만, 오브젝트 하나당 컴포넌트를 만들지 않고 한 번에 그린다.
/// 좌표: 월드 m, y 아래가 + 이므로 오브젝트 높이 yM 은 −y 로 그린다.
class ObjectLayer extends Component with HasGameReference {
  ObjectLayer(this.source);

  final ObjectSource source;
  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final field = source.objectField;
    for (final o in field.between(view.left - 10, view.right + 10)) {
      final used = field.isUsed(o.id);
      if (used && o.kind != ObjectKind.tramp && o.kind != ObjectKind.updraft) {
        continue;
      }
      final r = source.worldConfig.object(o.kind).radiusM * o.scale;
      _draw(canvas, o, r);
    }
  }

  void _draw(Canvas c, WorldObject o, double r) {
    final x = o.xM;
    final y = -o.yM;
    final t = source.clockSec;
    switch (o.kind) {
      case ObjectKind.seed:
        _fill.color = ObjectPalette.seed;
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: r * 1.4, height: r * 2),
          _fill,
        );
      case ObjectKind.tramp:
        _fill.color = ObjectPalette.trampLeg;
        c
          ..drawRect(
            Rect.fromLTWH(x - r * 0.9, -r * 0.35, r * 0.12, r * 0.35),
            _fill,
          )
          ..drawRect(
            Rect.fromLTWH(x + r * 0.78, -r * 0.35, r * 0.12, r * 0.35),
            _fill,
          );
        _fill.color = ObjectPalette.tramp;
        c.drawRRect(
          RRect.fromLTRBR(
            x - r,
            -r * 0.45,
            x + r,
            -r * 0.3,
            Radius.circular(r * 0.1),
          ),
          _fill,
        );
      case ObjectKind.clothesline:
        _line
          ..color = ObjectPalette.clothesline
          ..strokeWidth = r * 0.08;
        c.drawLine(Offset(x - r, y), Offset(x + r, y + r * 0.15), _line);
        _fill.color = ObjectPalette.cloth;
        c.drawRect(Rect.fromLTWH(x - r * 0.3, y, r * 0.5, r * 0.6), _fill);
      case ObjectKind.balloon:
        final by = y + math.sin(t * 2 + o.id) * r * 0.2;
        _line
          ..color = ObjectPalette.string
          ..strokeWidth = r * 0.05;
        c.drawLine(Offset(x, by + r), Offset(x, by + r * 2.4), _line);
        _fill.color = o.id.isEven
            ? ObjectPalette.balloonRed
            : ObjectPalette.balloonYellow;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, by),
            width: r * 1.8,
            height: r * 2.2,
          ),
          _fill,
        );
      case ObjectKind.fountain:
        _fill.color = ObjectPalette.water.withValues(alpha: 0.55);
        final h = 6 * o.scale;
        c.drawRect(Rect.fromLTWH(x - r * 0.35, -h, r * 0.7, h), _fill);
        _fill.color = ObjectPalette.stone;
        c.drawRect(Rect.fromLTWH(x - r, -r * 0.3, r * 2, r * 0.3), _fill);
      case ObjectKind.pigeon:
        _fill.color = ObjectPalette.pigeon;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: r * 2.2,
            height: r * 1.4,
          ),
          _fill,
        );
      case ObjectKind.updraft:
        final spec = source.worldConfig.object(o.kind);
        _fill.color = ObjectPalette.updraft.withValues(
          alpha: 0.18 + 0.08 * math.sin(t * 5),
        );
        c.drawRect(
          Rect.fromLTWH(x - r, -spec.p2 * o.scale, r * 2, spec.p2 * o.scale),
          _fill,
        );
      case ObjectKind.umbrella:
        _fill.color = ObjectPalette.umbrella;
        c.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: r),
          math.pi,
          math.pi,
          true,
          _fill,
        );
      case ObjectKind.billboard:
        _fill.color = ObjectPalette.billboard;
        c.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.2),
          _fill,
        );
      case ObjectKind.branch:
        _line
          ..color = ObjectPalette.branch
          ..strokeWidth = r * 0.25;
        c.drawLine(
          Offset(x - r, y + r * 0.3),
          Offset(x + r, y - r * 0.3),
          _line,
        );
      case ObjectKind.wire:
        _line
          ..color = ObjectPalette.wire
          ..strokeWidth = r * 0.15;
        c.drawLine(Offset(x - r * 2, y), Offset(x + r * 2, y + r * 0.3), _line);
      case ObjectKind.crow:
        _fill.color = ObjectPalette.crow;
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.3),
          _fill,
        );
    }
  }
}
