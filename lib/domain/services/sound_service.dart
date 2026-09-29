import 'dart:typed_data';

/// 효과음 종류 (GDD §3 사운드, 샘플 SFX).
enum Sfx {
  /// 당길 때 고무 늘어나는 소리 (루프, 늘어날수록 음높이 상승).
  squeak,

  /// 발사: 휘익 + 찍!
  release,

  /// 씨앗 뽁 (콤보마다 음계 상승 = 재생 속도).
  seed,

  /// 착지 말랑한 뿅.
  land,

  /// 트램폴린 통.
  tramp,

  /// 풍선 팡.
  pop,

  /// PERFECT·신기록 팡파르.
  perfect,

  /// 어질 (장애물·세게 착지).
  dizzy,

  /// 부스터 분사 (루프).
  boost,
}

/// 효과음 재생 (ADR-019). 소리는 게임이 코드로 합성해 [load] 로 넘긴다.
/// 구현: flutter_soloud(`data/audio`), 무음(`data/fake`).
abstract interface class SoundService {
  /// 합성한 WAV 바이트를 불러온다. 실패해도 게임은 소리 없이 진행한다.
  Future<void> load(Map<Sfx, Uint8List> wavs);

  /// 한 번 재생. [pitch] 는 재생 속도 배율(음높이).
  void play(Sfx sfx, {double pitch = 1, double volume = 1});

  /// 루프 시작·조절·정지 (고무 소리, 부스터).
  void loopStart(Sfx sfx);
  void loopSet(Sfx sfx, {required double pitch, required double volume});
  void loopStop(Sfx sfx);
}
