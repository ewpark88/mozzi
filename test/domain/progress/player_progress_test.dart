import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/upgrade_levels.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';
import 'package:mozzi/domain/economy/wallet.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/stage_record.dart';

void main() {
  final sample = PlayerProgress(
    levels: UpgradeLevels.of(const {
      UpgradeType.launch: 14,
      UpgradeType.coin: 3,
    }),
    wallet: const Wallet(seeds: 346, candy: 20),
    bestDistanceM: 577.4,
    totalRuns: 13,
    onboardingStep: 5,
  );

  test('JSON 문자열로 저장했다가 그대로 복원한다', () {
    final text = jsonEncode(sample.toJson());
    expect(PlayerProgress.fromJson(jsonDecode(text)), sample);
  });

  test('세이브에 스키마 버전과 Remote Config 키 이름이 들어간다', () {
    final json = sample.toJson();
    expect(json['schema'], PlayerProgress.schemaVersion);
    expect((json['levels']! as Map<String, int>)['upg_launch'], 14);
  });

  test('새 게임은 모두 0', () {
    final p = PlayerProgress.initial;
    expect(p.levels, const UpgradeLevels.zero());
    expect(p.wallet, Wallet.empty);
    expect(p.totalRuns, 0);
  });

  test('앱보다 새 스키마의 세이브는 거부한다', () {
    final json = sample.toJson()..['schema'] = PlayerProgress.schemaVersion + 1;
    expect(
      () => PlayerProgress.fromJson(json),
      throwsA(isA<UnsupportedSaveVersion>()),
    );
  });

  test('손상된 세이브는 JsonFormatError', () {
    expect(
      () => PlayerProgress.fromJson(const {'schema': 1}),
      throwsA(isA<JsonFormatError>()),
    );
  });

  test('copyWith 는 지정한 필드만 바꾼다', () {
    final p = sample.copyWith(totalRuns: 14);
    expect(p.totalRuns, 14);
    expect(p.levels, sample.levels);
    expect(p.wallet, sample.wallet);
  });

  test('v1 세이브는 v2 로 변환된다 (스테이지 기록·해금은 비어 있음)', () {
    final v1 = {
      'schema': 1,
      'levels': {'upg_launch': 4},
      'wallet': {'seeds': 30, 'candy': 0},
      'best_distance_m': 88.0,
      'total_runs': 6,
      'onboarding_step': 2,
    };
    final p = PlayerProgress.fromJson(v1);
    expect(p.totalRuns, 6);
    expect(p.wallet.seeds, 30);
    expect(p.levels[UpgradeType.launch], 4);
    expect(p.stages, isEmpty);
    expect(p.unlocks, isEmpty);
    expect(p.toJson()['schema'], 2);
  });

  test('v2 는 스테이지 기록·해금까지 저장했다가 복원한다', () {
    final p = sample.copyWith(
      stages: {'1-1': const StageRecord(star1: true, bestDistanceM: 31)},
      unlocks: {'slot_hat'},
    );
    expect(PlayerProgress.fromJson(jsonDecode(jsonEncode(p.toJson()))), p);
    expect(p.totalStars, 1);
  });

  group('UpgradeLevels', () {
    test('increment 는 새 객체를 돌려주고 원본은 그대로다', () {
      const zero = UpgradeLevels.zero();
      final one = zero.increment(UpgradeType.aero);
      expect(one[UpgradeType.aero], 1);
      expect(zero[UpgradeType.aero], 0);
    });

    test('음수 레벨은 거부한다', () {
      expect(
        () => UpgradeLevels.of(const {UpgradeType.boost: -1}),
        throwsArgumentError,
      );
    });

    test('세이브에 없는 업그레이드 키는 0 으로 읽는다 (구버전 호환)', () {
      final lv = UpgradeLevels.fromJson(JsonReader({'upg_launch': 2}));
      expect(lv[UpgradeType.launch], 2);
      expect(lv[UpgradeType.coin], 0);
    });
  });
}
