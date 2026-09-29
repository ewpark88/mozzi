import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mozzi/domain/balance/world_config.dart';
import 'package:mozzi/domain/world/chunk_generator.dart';
import 'package:mozzi/domain/world/object_kind.dart';
import 'package:mozzi/game/render/object_painter.dart';

/// 오브젝트를 그리는 쪽이 필요로 하는 값 (MozziGame 이 제공).
abstract interface class ObjectSource {
  ObjectField get objectField;
  WorldConfig get worldConfig;
  double get clockSec;

  /// 월드 림라이트 색.
  Color get rimColor;
}

/// 월드 오브젝트 (월드 레이어, 2.5D 셰이딩은 [ObjectPainter]).
/// 카메라에 보이는 범위만, 오브젝트 하나당 컴포넌트를 만들지 않고 한 번에 그린다.
/// 좌표: 월드 m, y 아래가 + 이므로 오브젝트 높이 yM 은 −y 로 그린다.
class ObjectLayer extends Component with HasGameReference {
  ObjectLayer(this.source);

  final ObjectSource source;
  final ObjectPainter _painter = ObjectPainter();

  /// 분수 물기둥 높이 (시각용, m × 거리 배율).
  static const double _fountainJetM = 6;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final field = source.objectField;
    _painter.rim = source.rimColor;
    for (final o in field.between(view.left - 10, view.right + 10)) {
      final used = field.isUsed(o.id);
      if (used && o.kind != ObjectKind.tramp && o.kind != ObjectKind.updraft) {
        continue;
      }
      final spec = source.worldConfig.object(o.kind);
      _painter.draw(
        canvas,
        o.kind,
        Offset(o.xM, -o.yM),
        spec.radiusM * o.scale,
        id: o.id,
        t: source.clockSec,
        areaHeightM: switch (o.kind) {
          ObjectKind.updraft => spec.p2 * o.scale,
          ObjectKind.fountain => _fountainJetM * o.scale,
          _ => 0,
        },
      );
    }
  }
}
