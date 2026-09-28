/// 시드 기반 결정론 난수 생성기 (xorshift32).
///
/// 같은 시드면 어느 기기에서나 같은 수열을 낸다. 청크 배치·랜덤 이벤트 등
/// 게임 규칙의 모든 난수는 `dart:math` `Random` 대신 이 클래스를 쓴다. (ARCHITECTURE §1 결정론)
class SeededRng {
  /// [seed] 가 0 이면 xorshift 가 멈추므로 고정 상수로 대체한다.
  SeededRng(int seed) : _state = _normalize(seed);

  static const int _mask32 = 0xFFFFFFFF;
  static const int _zeroSeedReplacement = 0x9E3779B9;

  int _state;

  static int _normalize(int seed) {
    final s = seed & _mask32;
    return s == 0 ? _zeroSeedReplacement : s;
  }

  /// 다음 32비트 부호 없는 정수 (0 ~ 2^32-1).
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask32;
    x ^= x >> 17;
    x ^= (x << 5) & _mask32;
    _state = x;
    return x;
  }

  /// [0, 1) 범위 실수.
  double nextDouble() => nextUint32() / 4294967296.0;

  /// [0, max) 범위 정수. [max] 는 1 이상.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', '1 이상이어야 한다');
    }
    return (nextDouble() * max).floor();
  }

  /// 확률 [probability] (0~1) 로 true.
  bool nextBool(double probability) => nextDouble() < probability;
}
