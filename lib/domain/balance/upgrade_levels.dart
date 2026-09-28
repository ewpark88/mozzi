import 'package:meta/meta.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

/// 업그레이드 5종의 현재 레벨 (불변).
@immutable
class UpgradeLevels {
  /// 모든 레벨 0.
  const UpgradeLevels.zero() : _levels = const {};

  UpgradeLevels._(Map<UpgradeType, int> levels)
    : _levels = Map.unmodifiable(levels);

  /// 지정한 레벨만 채우고 나머지는 0.
  factory UpgradeLevels.of(Map<UpgradeType, int> levels) {
    for (final entry in levels.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(entry.value, entry.key.name, '레벨은 0 이상');
      }
    }
    return UpgradeLevels._(levels);
  }

  /// 모든 항목이 같은 레벨 (시트 「업그레이드표」의 “전 항목 동일 Lv” 열).
  factory UpgradeLevels.all(int level) =>
      UpgradeLevels.of({for (final t in UpgradeType.values) t: level});

  /// 세이브 JSON (`{"upg_launch": 3, ...}`) 에서 읽는다. 없는 키는 0.
  factory UpgradeLevels.fromJson(JsonReader json) => UpgradeLevels.of({
    for (final t in UpgradeType.values)
      if (json.has(t.configKey)) t: json.integer(t.configKey),
  });

  final Map<UpgradeType, int> _levels;

  int operator [](UpgradeType type) => _levels[type] ?? 0;

  /// [type] 을 1 올린 새 레벨.
  UpgradeLevels increment(UpgradeType type) =>
      UpgradeLevels._({..._levels, type: this[type] + 1});

  Map<String, int> toJson() => {
    for (final t in UpgradeType.values) t.configKey: this[t],
  };

  @override
  bool operator ==(Object other) =>
      other is UpgradeLevels &&
      UpgradeType.values.every((t) => this[t] == other[t]);

  @override
  int get hashCode => Object.hashAll(UpgradeType.values.map((t) => this[t]));

  @override
  String toString() =>
      'UpgradeLevels(${UpgradeType.values.map((t) => '${t.name}:${this[t]}').join(', ')})';
}
