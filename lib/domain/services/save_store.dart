import 'package:mozzi/domain/progress/player_progress.dart';

/// 세이브 저장소 (ARCHITECTURE §7). 구현: Hive(`data/save`), 메모리(`data/fake`).
abstract interface class SaveStore {
  /// 저장된 진행 상태. 처음이면 null. 이전 스키마는 변환해서 돌려준다.
  Future<PlayerProgress?> load();

  Future<void> save(PlayerProgress progress);
}
