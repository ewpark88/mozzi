import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mozzi/core/result.dart';
import 'package:mozzi/data/fake/fake_ad_service.dart';
import 'package:mozzi/data/fake/memory_save_store.dart';
import 'package:mozzi/data/save/hive_save_store.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_record.dart';
import 'package:mozzi/domain/services/ad_service.dart';
import 'package:mozzi/domain/services/save_store.dart';

/// 세이브 저장소 계약: 저장 → 복원이 같다 (Hive·메모리 공통).
void main() {
  final sample = PlayerProgress(
    levels: UpgradeLevels.all(3),
    wallet: const Wallet(seeds: 120, candy: 5),
    bestDistanceM: 812.5,
    totalRuns: 9,
    stages: const {
      '1-1': StageRecord(star1: true, star3: true, bestDistanceM: 40),
      '1-5': StageRecord(bestDistanceM: 320, bossFails: 4),
    },
    unlocks: const {'char_chick'},
  );

  Future<void> contract(SaveStore store) async {
    expect(await store.load(), isNull, reason: '처음에는 비어 있음');
    await store.save(sample);
    expect(await store.load(), sample);
    await store.save(sample.copyWith(totalRuns: 10));
    expect((await store.load())!.totalRuns, 10);
  }

  test('메모리 저장소: 저장 → 복원', () => contract(MemorySaveStore()));

  group('Hive 저장소', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('mozzi_hive');
      Hive.init(dir.path);
    });
    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('저장 → 복원', () async => contract(await HiveSaveStore.open()));

    test('앱을 다시 열어도 남아 있다', () async {
      await (await HiveSaveStore.open()).save(sample);
      await Hive.close();
      Hive.init(dir.path);
      expect(await (await HiveSaveStore.open()).load(), sample);
    });
  });

  test('가짜 광고: 기본은 끝까지 본 것, 실패도 흉내 낸다', () async {
    final ads = FakeAdService();
    expect(ads.rewardedReady, isTrue);
    expect((await ads.showRewarded()).isOk, isTrue);
    ads.result = const Err(AdError.dismissed);
    expect((await ads.showRewarded()).isOk, isFalse);
    expect(ads.shown, 2);
  });
}
