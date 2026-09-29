import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/audio/pcm_synth.dart';
import 'package:mozzi/domain/services/sound_service.dart';
import 'package:mozzi/game/audio/sfx_bank.dart';

/// GDD §3 제작 원칙: 효과음 코드 합성 — 결정론(같은 파라미터 = 같은 바이트).
void main() {
  Uint8List render(int seed) =>
      (PcmSynth(durationSec: .3)
            ..noise(.25, 700, 2600, seed: seed)
            ..tone(1700, 2700, .09, wave: Wave.square, vol: .05, delay: .03))
          .toWav();

  test('같은 파라미터·시드면 같은 바이트', () {
    expect(render(1), render(1));
  });

  test('노이즈 시드가 다르면 다른 소리', () {
    expect(render(1), isNot(render(2)));
  });

  test('16bit 모노 WAV 헤더와 길이', () {
    final wav = (PcmSynth(durationSec: .5)..tone(440, 440, .4)).toWav();
    final h = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(h.getUint16(22, Endian.little), 1, reason: '모노');
    expect(h.getUint32(24, Endian.little), PcmSynth.defaultRate);
    expect(h.getUint16(34, Endian.little), 16);
    final samples = (PcmSynth.defaultRate * .5).ceil();
    expect(wav.length, 44 + samples * 2);
  });

  test('엔벌로프: 음은 끝에서 사라지고 최대 음량을 넘지 않는다', () {
    final s = PcmSynth(durationSec: .2)..tone(440, 440, .2);
    expect(s.peak, lessThanOrEqualTo(.15 + 1e-9));
    expect(s.peak, greaterThan(.1));
  });

  group('효과음 목록 (GDD §3 사운드)', () {
    test('모든 효과음을 합성한다', () {
      final bank = SfxBank.build();
      expect(bank.keys, Sfx.values);
      for (final wav in bank.values) {
        expect(wav.length, greaterThan(44));
      }
    });

    test('씨앗 뽁: 콤보가 이어지면 음계 상승, 14반음에서 멈춤', () {
      expect(SfxBank.seedPitch(0), 1);
      expect(SfxBank.seedPitch(12), closeTo(2, 1e-9));
      expect(SfxBank.seedPitch(3), greaterThan(SfxBank.seedPitch(2)));
      expect(SfxBank.seedPitch(30), SfxBank.seedPitch(14));
    });

    test('고무 소리: 늘어날수록 음높이·음량 상승 (샘플 240 + 520p Hz)', () {
      final (p0, v0) = SfxBank.squeak(0);
      final (p1, v1) = SfxBank.squeak(1);
      expect(p0, closeTo(240 / SfxBank.squeakBaseHz, 1e-9));
      expect(p1, closeTo(760 / SfxBank.squeakBaseHz, 1e-9));
      expect(v0, 0, reason: '거의 안 당기면 무음');
      expect(v1, closeTo(1, 1e-9));
    });

    test('착지: 세게 떨어질수록 크게 (최대 1)', () {
      expect(SfxBank.landVolume(0), lessThan(SfxBank.landVolume(600)));
      expect(SfxBank.landVolume(1000000), 1);
    });
  });
}
