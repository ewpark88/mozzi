import 'dart:typed_data';

import 'package:mozzi/domain/services/sound_service.dart';

/// 무음 효과음 (테스트). 무엇을 재생했는지 기록한다.
class SilentSoundService implements SoundService {
  final List<Sfx> played = [];
  final Set<Sfx> looping = {};
  int loaded = 0;

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async => loaded = wavs.length;

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) => played.add(sfx);

  @override
  void loopStart(Sfx sfx) => looping.add(sfx);

  @override
  void loopSet(Sfx sfx, {required double pitch, required double volume}) {}

  @override
  void loopStop(Sfx sfx) => looping.remove(sfx);
}
