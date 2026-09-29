import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mozzi/domain/services/sound_service.dart';

/// flutter_soloud 효과음 재생 (ADR-019). 저지연, 루프 재생 중 음높이(재생 속도) 조절.
///
/// 초기화나 불러오기가 실패하면 로그만 남기고 소리 없이 동작한다 (게임은 계속).
class SoloudSoundService implements SoundService {
  final SoLoud _soloud = SoLoud.instance;
  final Map<Sfx, AudioSource> _sources = {};
  final Map<Sfx, SoundHandle> _loops = {};

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {
    try {
      if (!_soloud.isInitialized) await _soloud.init();
      for (final e in wavs.entries) {
        _sources[e.key] = await _soloud.loadMem('${e.key.name}.wav', e.value);
      }
    } on Object catch (e) {
      debugPrint('효과음 초기화 실패, 소리 없이 진행: $e');
      _sources.clear();
    }
  }

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) {
    final src = _sources[sfx];
    if (src == null) return;
    final h = _soloud.play(src, volume: volume);
    if (pitch != 1) _soloud.setRelativePlaySpeed(h, pitch);
  }

  @override
  void loopStart(Sfx sfx) {
    final src = _sources[sfx];
    if (src == null || _loops.containsKey(sfx)) return;
    _loops[sfx] = _soloud.play(src, volume: 0, looping: true);
  }

  @override
  void loopSet(Sfx sfx, {required double pitch, required double volume}) {
    final h = _loops[sfx];
    if (h == null) return;
    _soloud
      ..setRelativePlaySpeed(h, pitch)
      ..setVolume(h, volume);
  }

  @override
  void loopStop(Sfx sfx) {
    final h = _loops.remove(sfx);
    if (h != null) unawaited(_soloud.stop(h));
  }
}
