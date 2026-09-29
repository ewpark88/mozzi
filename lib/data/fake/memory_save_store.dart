import 'dart:convert';

import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/services/save_store.dart';

/// 메모리 세이브 (테스트·가짜 서비스). 실제 저장소처럼 JSON 을 거쳐 저장한다.
class MemorySaveStore implements SaveStore {
  MemorySaveStore([PlayerProgress? initial])
    : _json = initial == null ? null : jsonEncode(initial.toJson());

  String? _json;

  @override
  Future<PlayerProgress?> load() async {
    final text = _json;
    return text == null ? null : PlayerProgress.fromJson(jsonDecode(text));
  }

  @override
  Future<void> save(PlayerProgress progress) async =>
      _json = jsonEncode(progress.toJson());
}
