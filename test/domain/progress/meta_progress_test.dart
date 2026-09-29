import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/run_recorder.dart';
import 'package:mozzi/domain/progress/stage_record.dart';
import 'package:mozzi/domain/progress/stage_unlocks.dart';
import 'package:mozzi/domain/progress/unlock.dart';
import 'package:mozzi/domain/run/run_result.dart';
import 'package:mozzi/domain/run/star_rules.dart';

import '../../helpers/balance_fixture.dart';

/// GDD §2 결과 화면(실패해도 씨앗·광고 2배), §4 별·월드 해금·보스 완화·보스 보상.
void main() {
  final config = loadDefaultBalance();
  final formulas = BalanceFormulas(config);
  final recorder = RunRecorder(config);
  final unlocks = StageUnlocks(config.world);

  RunResult result(
    String id, {
    bool cleared = false,
    bool star2 = false,
    bool star3 = false,
    double distanceM = 100,
  }) => RunResult(
    stageId: id,
    distanceM: distanceM,
    previousBestM: 0,
    distanceSeeds: 50,
    pickupSeeds: 7,
    comboMax: 0,
    stars: StarResult(cleared: cleared, star2: star2, missions: [star3]),
    bossLost: false,
  );

  /// 스테이지를 [stars] 개 별로 클리어한 기록.
  PlayerProgress withStages(Map<String, int> stars) => PlayerProgress(
    stages: {
      for (final e in stars.entries)
        e.key: StageRecord(
          star1: e.value >= 1,
          star2: e.value >= 2,
          star3: e.value >= 3,
        ),
    },
  );

  group('판 보상 (ADR-017)', () {
    test('씨앗 = 거리 씨앗 + 먹은 씨앗, 광고는 합계 × 2', () {
      final r = result('1-1');
      expect(r.seeds, 57);
      expect(r.seedsWithAd(config.adRewardMultiplier), 114);
    });

    test('먹은 씨앗 값에는 볼주머니 배율을 곱해 사사오입', () {
      final lv = UpgradeLevels.of(const {UpgradeType.coin: 3}); // ×1.3
      expect(RunResult.pickupSeedsFor(10, lv, formulas), 13);
      expect(RunResult.pickupSeedsFor(1.15, lv, formulas), 1); // 1.495
    });

    test('실패해도 씨앗은 받고 판 수·최고 기록이 오른다', () {
      final p = recorder.record(PlayerProgress.initial, result('1-2'));
      expect(p.wallet.seeds, 57);
      expect(p.totalRuns, 1);
      expect(p.bestDistanceM, 100);
      expect(p.stage('1-2').cleared, isFalse);
      expect(p.stage('1-2').bestDistanceM, 100);
    });

    test('광고를 보면 2배', () {
      final p = recorder.record(
        PlayerProgress.initial,
        result('1-2'),
        watchedAd: true,
      );
      expect(p.wallet.seeds, 114);
    });
  });

  group('스테이지 기록', () {
    test('별은 판마다 모인다 (★★ 와 ★★★ 를 다른 판에서 달성해도 3개)', () {
      var p = recorder.record(
        PlayerProgress.initial,
        result('1-1', cleared: true, star2: true),
      );
      p = recorder.record(p, result('1-1', cleared: true, star3: true));
      expect(p.stage('1-1').stars, 3);
      expect(p.totalStars, 3);
    });

    test('최고 기록은 더 멀리 간 판만', () {
      var p = recorder.record(PlayerProgress.initial, result('1-3'));
      p = recorder.record(p, result('1-3', distanceM: 60));
      expect(p.stage('1-3').bestDistanceM, 100);
    });
  });

  group('보스 연속 실패와 보상', () {
    test('보스는 실패를 세고 클리어하면 0, 완화는 3연패부터 5%', () {
      var p = PlayerProgress.initial;
      for (var i = 0; i < 3; i++) {
        p = recorder.record(p, result('1-5'));
      }
      expect(p.stage('1-5').bossFails, 3);
      expect(recorder.bossEase(p, '1-5'), 0.05);
      p = recorder.record(p, result('1-5', cleared: true));
      expect(p.stage('1-5').bossFails, 0);
      expect(recorder.bossEase(p, '1-5'), 0);
    });

    test('보스가 아닌 스테이지는 실패를 세지 않는다', () {
      final p = recorder.record(PlayerProgress.initial, result('1-4'));
      expect(p.stage('1-4').bossFails, 0);
      expect(recorder.bossEase(p, '1-4'), 0);
    });

    test('1-5 클리어는 병아리·조작 2종, 2-5 는 모자 슬롯, 3-5 는 카피바라', () {
      var p = recorder.record(PlayerProgress.initial, result('1-5'));
      expect(p.unlocks, isEmpty, reason: '실패는 보상 없음');
      p = recorder.record(p, result('1-5', cleared: true));
      expect(p.unlocks, {
        Unlock.chick,
        Unlock.controlInflate,
        Unlock.controlDive,
      });
      p = recorder.record(p, result('2-5', cleared: true));
      p = recorder.record(p, result('3-5', cleared: true));
      expect(p.unlocks, containsAll([Unlock.hatSlot, Unlock.capybara]));
    });
  });

  group('월드·스테이지 해금 (GDD §4)', () {
    final world1 = {'1-1': 1, '1-2': 1, '1-3': 1, '1-4': 1, '1-5': 1};

    test('처음에는 1-1 만 열려 있다', () {
      final p = PlayerProgress.initial;
      final open = unlocks
          .mapStages()
          .where((s) => unlocks.isStageUnlocked(s, p))
          .map((s) => s.id);
      expect(open, ['1-1']);
      expect(unlocks.nextStage(p).id, '1-1');
    });

    test('앞 스테이지를 클리어하면 다음이 열린다', () {
      final p = withStages({'1-1': 1});
      expect(unlocks.isStageUnlocked(config.world.stage(1, 2), p), isTrue);
      expect(unlocks.isStageUnlocked(config.world.stage(1, 3), p), isFalse);
      expect(unlocks.nextStage(p).id, '1-2');
    });

    test('월드 2 = 1-5 클리어 + 별 8개', () {
      expect(unlocks.isWorldUnlocked(2, withStages(world1)), isFalse);
      final eight = withStages({...world1, '1-1': 3, '1-2': 2});
      expect(eight.totalStars, 8);
      expect(unlocks.isWorldUnlocked(2, eight), isTrue);
      final noBoss = withStages({
        '1-1': 3,
        '1-2': 3,
        '1-3': 3,
        '1-4': 3,
      });
      expect(unlocks.isWorldUnlocked(2, noBoss), isFalse);
    });

    test('월드 3 = 2-5 클리어 + 별 20개, 월드 4 이후는 P11 전까지 잠김', () {
      expect(unlocks.starsNeeded(3), 20);
      final all3 = withStages({
        for (var w = 1; w <= 3; w++)
          for (var s = 1; s <= 5; s++) '$w-$s': 3,
      });
      expect(unlocks.isWorldUnlocked(3, all3), isTrue);
      expect(unlocks.isWorldUnlocked(4, all3), isFalse);
      expect(unlocks.mapStages().map((s) => s.world).toSet(), {1, 2, 3});
    });
  });
}
