import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mozzi/core/audio/pcm_synth.dart';
import 'package:mozzi/domain/services/sound_service.dart';

/// 효과음 레시피 (GDD §3 사운드, 샘플 `SFX`·squeakStart·boostSound 을 그대로 옮김).
abstract final class SfxBank {
  /// 샘플 WebAudio 음량은 작게 잡혀 있어 PCM 으로 옮길 때 키운다.
  static const double masterGain = 2.5;

  /// 고무 소리 기본 음 (Hz). 당긴 정도 p 에서 240 + 520p Hz → 재생 속도로 맞춘다.
  static const double squeakBaseHz = 260;

  /// 씨앗 뽁 기본 음 (Hz). 콤보 n 이면 2^(min(n,14)/12) 배.
  static const double seedBaseHz = 880;
  static const int seedMaxSemitones = 14;

  /// 모든 효과음 WAV.
  static Map<Sfx, Uint8List> build() => {
    for (final s in Sfx.values) s: wav(s),
  };

  static Uint8List wav(Sfx s) => switch (s) {
    Sfx.squeak => (PcmSynth(
      durationSec: 1,
    )..vibrato(squeakBaseHz, 18, 12)).toWav(gain: masterGain),
    Sfx.release =>
      (PcmSynth(durationSec: .4)
            ..noise(.35, 700, 2600, vol: .16)
            ..tone(1700, 2700, .09, wave: Wave.square, vol: .045, delay: .03)
            ..tone(2200, 3000, .07, wave: Wave.square, vol: .035, delay: .12))
          .toWav(gain: masterGain),
    Sfx.seed =>
      (PcmSynth(durationSec: .1)
            ..tone(seedBaseHz, seedBaseHz * 1.5, .09, vol: .13))
          .toWav(gain: masterGain),
    Sfx.land => (PcmSynth(
      durationSec: .22,
    )..tone(340, 110, .2, vol: .22)).toWav(gain: masterGain),
    Sfx.tramp =>
      (PcmSynth(durationSec: .3)
            ..tone(170, 560, .26, wave: Wave.triangle, vol: .16)
            ..tone(340, 900, .2, vol: .05, delay: .02))
          .toWav(gain: masterGain),
    Sfx.pop =>
      (PcmSynth(durationSec: .1)
            ..noise(.09, 3000, 5000, vol: .18, q: .7, seed: 3)
            ..tone(900, 300, .08, wave: Wave.square, vol: .03))
          .toWav(gain: masterGain),
    Sfx.perfect => _perfect(),
    Sfx.dizzy =>
      (PcmSynth(durationSec: .36)
            ..tone(600, 200, .35, wave: Wave.sawtooth, vol: .04))
          .toWav(gain: masterGain),
    Sfx.boost => (PcmSynth(
      durationSec: 1,
    )..lowNoise(900)).toWav(gain: masterGain),
  };

  /// 도·미·솔·도 아르페지오 (샘플 perfect: 784Hz 기준 0·4·7·12 반음).
  static Uint8List _perfect() {
    final s = PcmSynth(durationSec: .32);
    const steps = [0, 4, 7, 12];
    for (var i = 0; i < steps.length; i++) {
      final f = 784 * math.pow(2, steps[i] / 12).toDouble();
      s.tone(f, f, .12, wave: Wave.triangle, vol: .09, delay: i * .06);
    }
    return s.toWav(gain: masterGain);
  }

  /// 콤보 [n] 번째 씨앗의 재생 속도 (음계 상승).
  static double seedPitch(int n) =>
      math.pow(2, math.min(n, seedMaxSemitones) / 12).toDouble();

  /// 당긴 정도 [p](0~1) 의 고무 소리 재생 속도·음량 (샘플 squeakSet).
  static (double, double) squeak(double p) => (
    (240 + p * 520) / squeakBaseHz,
    p > .02 ? (.035 + .03 * p) / .065 : 0,
  );

  /// 착지 음량: 세게 떨어질수록 크게 (샘플 land: min(.22, .06 + v/6000)).
  static double landVolume(double impactUnits) =>
      math.min(.22, .06 + impactUnits / 6000) / .22;
}
