import 'package:mozzi/core/json/json_reader.dart';

/// ★★★ 미션 하나 (GDD §4 미션 타입 정의). [params] 는 타입별 값 (n, obj, sec, ratio …).
class MissionSpec {
  const MissionSpec({required this.type, required this.params});

  factory MissionSpec.fromJson(JsonReader r) => MissionSpec(
    type: r.string('type'),
    params: r.raw(),
  );

  final String type;
  final Map<String, Object?> params;

  int intParam(String key) {
    final v = params[key];
    if (v is int) return v;
    if (v is double) return v.round();
    throw ArgumentError('미션 $type: $key 없음');
  }

  double numParam(String key) {
    final v = params[key];
    if (v is num) return v.toDouble();
    throw ArgumentError('미션 $type: $key 없음');
  }

  String stringParam(String key) {
    final v = params[key];
    if (v is String) return v;
    throw ArgumentError('미션 $type: $key 없음');
  }
}

/// 스테이지 (GDD §4, 시트 「스테이지」 한 행). JSON 은 GDD §4 스테이지 데이터 형식
/// (`{"id": "3-3", "world": 3, "goal": 3800, "boss": false, "star3": [...]}`).
class StageSpec {
  const StageSpec({
    required this.world,
    required this.stage,
    required this.targetM,
    required this.boss,
    required this.star3,
    required this.star3Text,
  });

  factory StageSpec.fromJson(JsonReader r) {
    final world = r.integer('world');
    final id = r.string('id');
    final parts = id.split('-');
    final stage = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (stage == null || parts[0] != '$world') {
      throw JsonFormatError('${r.path}.id', '"$id" 가 world $world 와 맞지 않음');
    }
    return StageSpec(
      world: world,
      stage: stage,
      targetM: r.isNull('goal') ? null : r.number('goal'),
      boss: r.boolean('boss'),
      star3: r.objectList('star3').map(MissionSpec.fromJson).toList(),
      star3Text: r.string('star3_text'),
    );
  }

  final int world;
  final int stage;

  /// 목표 거리 (골 깃발, JSON `goal`). 6-1 달은 null.
  final double? targetM;
  final bool boss;

  /// ★★★ 미션 (모두 만족해야 함).
  final List<MissionSpec> star3;
  final String star3Text;

  /// "1-1" 형식 ID.
  String get id => '$world-$stage';
}
