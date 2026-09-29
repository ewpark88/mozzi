import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/game/render/mochi/mochi_deform.dart';

/// GDD §3 말랑 표현·접지 그림자·애니메이션 입력값 → 몸 변형 (시각 전용).
void main() {
  group('당기기 (stretch)', () {
    test('안 당기면 변형 없음', () {
      final d = MochiDeform.of();
      expect(d.along, 1);
      expect(d.across, 1);
      expect(d.lean, 0);
    });

    test('당길수록 당긴 축으로 늘어나고 옆으로 가늘어진다 (부피 유지)', () {
      final half = MochiDeform.of(stretch: .5, stretchAngle: math.pi * .75);
      final full = MochiDeform.of(stretch: 1, stretchAngle: math.pi * .75);
      expect(full.along, greaterThan(half.along));
      expect(full.across, lessThan(half.across));
      // 샘플: sx = 1 + 150/125 = 2.2, sy = 1/√sx
      expect(full.along, closeTo(2.2, 1e-9));
      expect(full.along * full.across * full.across, closeTo(1, 1e-9));
      expect(full.axisAngle, math.pi * .75);
    });

    test('당긴 반대쪽(발사 방향)으로 살짝 기운다', () {
      final d = MochiDeform.of(stretch: 1, stretchAngle: math.pi * .75);
      expect(d.lean, closeTo(-math.pi * .25 * MochiDeform.leanRatio, 1e-9));
    });
  });

  group('비행 속도', () {
    test('빠를수록 진행 방향으로 늘어나되 최대 28%', () {
      final slow = MochiDeform.of(speedUnits: 30);
      final fast = MochiDeform.of(speedUnits: 2000, velocityAngle: .3);
      final max = MochiDeform.of(speedUnits: 1000000);
      expect(slow.along, 1, reason: '느리면 변형 없음');
      expect(fast.along, greaterThan(1));
      expect(fast.axisAngle, .3);
      expect(max.along, closeTo(1 + MochiDeform.flyStretchMax, 1e-9));
    });
  });

  group('찌그러짐·그림자', () {
    test('눌릴수록(+) 가로로 퍼지고 세로로 낮아지며 그림자가 넓어진다', () {
      final rest = MochiDeform.of();
      final squash = MochiDeform.of(squash: .35);
      expect(squash.scaleX, greaterThan(1));
      expect(squash.scaleY, lessThan(1));
      expect(squash.shadowWidth, greaterThan(rest.shadowWidth));
    });

    test('높이 날수록 그림자가 작고 연해진다', () {
      final ground = MochiDeform.of();
      final high = MochiDeform.of(heightUnits: 600);
      expect(high.shadowWidth, lessThan(ground.shadowWidth));
      expect(high.shadowAlpha, lessThan(ground.shadowAlpha));
      expect(high.shadowAlpha, greaterThan(0));
    });

    test('하이라이트는 늘어난 방향으로 길어진다', () {
      expect(MochiDeform.of().highlightStretch, 1);
      expect(
        MochiDeform.of(stretch: 1).highlightStretch,
        greaterThan(1.5),
      );
    });
  });

  test('시각 스프링은 흔들리다 제자리로 돌아온다 (볼 출렁임)', () {
    final s = VisualSpring(k: 90, damping: 8, rest: 1)..value = 1.4;
    var crossed = false;
    for (var i = 0; i < 600; i++) {
      s.step(1 / 60);
      if (s.value < 1) crossed = true;
    }
    expect(crossed, isTrue, reason: '출렁임 (한 번 넘어감)');
    expect(s.value, closeTo(1, 1e-3));
  });
}
