import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/services/save_store.dart';

/// Hive 세이브 (ADR-005). 진행 상태를 JSON 문자열 하나로 저장한다.
///
/// Hive 초기화(`Hive.initFlutter`)는 앱 시작 시 app 층에서 한다.
class HiveSaveStore implements SaveStore {
  HiveSaveStore(this._box);

  /// [boxName] 상자를 연다.
  static Future<HiveSaveStore> open({String boxName = defaultBox}) async =>
      HiveSaveStore(await Hive.openBox<String>(boxName));

  static const String defaultBox = 'mozzi_save';
  static const String _key = 'progress';

  final Box<String> _box;

  @override
  Future<PlayerProgress?> load() async {
    final text = _box.get(_key);
    if (text == null) return null;
    return PlayerProgress.fromJson(jsonDecode(text));
  }

  @override
  Future<void> save(PlayerProgress progress) =>
      _box.put(_key, jsonEncode(progress.toJson()));
}
