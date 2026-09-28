import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/core/math/round_half_up.dart';
import 'package:mozzi/core/random/seeded_rng.dart';

void main() {
  group('roundHalfUp', () {
    test('.5 는 올린다 (Excel ROUND 와 같음, 은행가 반올림 아님)', () {
      expect(roundHalfUp(11.5), 12);
      expect(roundHalfUp(62.5), 63);
      expect(roundHalfUp(12.5), 13);
    });
    test('.5 미만은 내린다', () {
      expect(roundHalfUp(11.48), 11);
      expect(roundHalfUp(0.4), 0);
    });
  });

  group('SeededRng', () {
    test('같은 시드는 같은 수열을 낸다', () {
      final a = SeededRng(42);
      final b = SeededRng(42);
      expect(
        List.generate(100, (_) => a.nextUint32()),
        List.generate(100, (_) => b.nextUint32()),
      );
    });

    test('다른 시드는 다른 수열을 낸다', () {
      expect(SeededRng(1).nextUint32(), isNot(SeededRng(2).nextUint32()));
    });

    test('수열이 고정돼 있다 (기기·버전이 바뀌어도 데일리 챌린지 배치가 같아야 함)', () {
      final rng = SeededRng(2026);
      expect(List.generate(3, (_) => rng.nextUint32()), [
        _xorshift(2026),
        _xorshift(_xorshift(2026)),
        _xorshift(_xorshift(_xorshift(2026))),
      ]);
    });

    test('시드 0 도 멈추지 않는다', () {
      final rng = SeededRng(0);
      expect(rng.nextUint32(), isNot(0));
    });

    test('nextDouble 은 [0,1), nextInt 는 [0,max)', () {
      final rng = SeededRng(7);
      for (var i = 0; i < 10000; i++) {
        expect(rng.nextDouble(), inInclusiveRange(0, 0.9999999999));
        expect(rng.nextInt(6), inInclusiveRange(0, 5));
      }
      expect(() => rng.nextInt(0), throwsArgumentError);
    });

    test('nextBool 확률이 대략 맞다', () {
      final rng = SeededRng(99);
      final hits = List.generate(
        10000,
        (_) => rng.nextBool(0.3),
      ).where((b) => b);
      expect(hits.length, inInclusiveRange(2800, 3200));
    });
  });

  group('JsonReader', () {
    test('타입이 맞으면 읽는다', () {
      final r = JsonReader({
        'a': 1,
        'b': 2.5,
        's': 'x',
        'o': {'n': 3},
      });
      expect(r.integer('a'), 1);
      expect(r.number('a'), 1.0);
      expect(r.number('b'), 2.5);
      expect(r.string('s'), 'x');
      expect(r.object('o').integer('n'), 3);
    });

    test('키 누락·타입 오류는 경로가 담긴 JsonFormatError', () {
      final r = JsonReader({
        'o': {'n': 'x'},
      });
      expect(
        () => r.integer('missing'),
        throwsA(
          isA<JsonFormatError>().having((e) => e.path, 'path', r'$.missing'),
        ),
      );
      expect(
        () => r.object('o').integer('n'),
        throwsA(isA<JsonFormatError>().having((e) => e.path, 'path', r'$.o.n')),
      );
      expect(() => JsonReader([1, 2]), throwsA(isA<JsonFormatError>()));
    });
  });
}

/// 테스트용 참조 구현 (xorshift32 13/17/5).
int _xorshift(int x) {
  var v = x;
  v ^= (v << 13) & 0xFFFFFFFF;
  v ^= v >> 17;
  v ^= (v << 5) & 0xFFFFFFFF;
  return v;
}
