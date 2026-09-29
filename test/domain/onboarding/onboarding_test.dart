import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/onboarding/onboarding.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/run_recorder.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/run/run_session.dart';
import 'package:mozzi/domain/world/object_kind.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §9 온보딩 (첫 15분) — 1~5판 시나리오 단계 전이.
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);
  final ob = Onboarding(formulas);
  final recorder = RunRecorder(config);

  PlayerProgress played(PlayerProgress p) => recorder.record(
    p,
    const RunResult(
      stageId: null,
      distanceM: 20,
      previousBestM: 0,
      distanceSeeds: 10,
      pickupSeeds: 0,
      comboMax: 0,
      stars: null,
      bossLost: false,
    ),
  );

  test('1~5판 시나리오', () {
    var p = PlayerProgress.initial;
    // 1판: 당기기만 + 트램폴린 자동 배치, 무료 업그레이드는 아직
    expect(ob.hintFor(p), OnboardingHint.pull);
    expect(ob.tutorialTrampM(p), isNotNull);
    expect(ob.freeUpgrade(p), isNull);

    p = played(p);
    // 1판 뒤: 첫 업그레이드 무료(부스터), 트램폴린은 1판만
    expect(ob.tutorialTrampM(p), isNull);
    expect(ob.freeUpgrade(p), UpgradeType.boost);
    expect(ob.hintFor(p), isNull, reason: '부스터 Lv0 은 연료가 없어 아직 안내 안 함');
    final seeds = p.wallet.seeds;
    p = ob.claimFreeUpgrade(p);
    expect(p.levels[UpgradeType.boost], 1);
    expect(p.wallet.seeds, seeds, reason: '씨앗 차감 없음');
    expect(ob.freeUpgrade(p), isNull, reason: '한 번만');
    expect(ob.claimFreeUpgrade(p), p);

    // 2판: 부스터 안내
    expect(ob.hintFor(p), OnboardingHint.boost);
    p = played(p);
    expect(ob.highlightAdOffer(p), isFalse);
    // 3판 결과: 광고 2배 처음 제안
    expect(ob.hintFor(p), isNull);
    p = played(p);
    expect(ob.highlightAdOffer(p), isTrue);
    // 4판
    expect(ob.hintFor(p), isNull);
    p = played(p);
    expect(ob.highlightAdOffer(p), isFalse);
    // 5판: 퍼펙트 릴리즈 안내
    expect(ob.hintFor(p), OnboardingHint.perfect);
    p = played(p);
    expect(ob.hintFor(p), isNull, reason: '6판부터 안내 없음');
  });

  test('1판 트램폴린은 조작 없이 날렸을 때 떨어지는 곳 앞에 놓인다', () {
    final x = ob.tutorialTrampM(PlayerProgress.initial)!;
    final expected = formulas.expectedDistanceM(PlayerProgress.initial.levels);
    expect(x, closeTo(expected * Onboarding.trampAtRatio, 1e-9));
    final run = RunSession(
      formulas: formulas,
      levels: PlayerProgress.initial.levels,
      stage: config.world.stage(1, 1),
      runSeed: 1,
      tutorialTrampM: x,
    );
    final near = run.field.near(x, 1).toList();
    expect(near.where((o) => o.kind == ObjectKind.tramp), isNotEmpty);
  });
}
