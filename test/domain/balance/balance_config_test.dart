import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

import '../../helpers/balance_fixture.dart';

void main() {
  Map<String, dynamic> rawDefaults() =>
      jsonDecode(File('assets/config/balance_defaults.json').readAsStringSync())
          as Map<String, dynamic>;

  test('앱 기본값(balance_defaults.json)을 읽는다 — GDD §5 업그레이드 표', () {
    final config = loadDefaultBalance();
    final launch = config.upgrade(UpgradeType.launch);
    expect(launch.baseCost, 10);
    expect(launch.costGrowth, 1.15);
    expect(launch.effect, 2.2);
    expect(config.upgrade(UpgradeType.coin).baseCost, 60);
    expect(config.baseLaunchSpeedMps, 15);
    expect(config.gravityMps2, 9.8);
    expect(config.seedsPerM, 0.5);
  });

  test('구역 6개가 GDD §4 순서·거리로 들어 있다', () {
    final zones = loadDefaultBalance().zones;
    expect(zones.map((z) => z.name), ['뒷마당', '공원', '도시 옥상', '구름 위', '우주', '달']);
    expect(zones.map((z) => z.startM), [0, 500, 2000, 6000, 15000, 40000]);
  });

  test('모든 업그레이드 키가 Remote Config 키와 같다 (GDD §10)', () {
    final raw = rawDefaults();
    for (final t in UpgradeType.values) {
      expect(raw.containsKey(t.configKey), isTrue, reason: t.configKey);
    }
  });

  test('키가 빠지면 어떤 키인지 알려준다', () {
    final raw = rawDefaults()..remove('upg_aero');
    expect(
      () => BalanceConfig.fromJson(raw),
      throwsA(
        isA<JsonFormatError>().having((e) => e.path, 'path', r'$.upg_aero'),
      ),
    );
  });

  test('타입이 틀리면 거부한다', () {
    final raw = rawDefaults()..['phys_g'] = '9.8';
    expect(() => BalanceConfig.fromJson(raw), throwsA(isA<JsonFormatError>()));
  });

  test('비행 조작 RC 키가 GDD §10 이름과 같다', () {
    final raw = rawDefaults();
    for (final k in [
      'boost_fuel_sec', 'boost_tap_sec', 'boost_lv0_fuel_sec', //
      'boost_cut_on_land', 'inflate_glide_ratio', 'inflate_decel_per_sec',
      'dive_speed_ratio', 'gesture_tap_max_sec', 'gesture_hold_sec',
      'gesture_swipe_min_px', 'gesture_swipe_max_sec',
    ]) {
      expect(raw.containsKey(k), isTrue, reason: k);
    }
    final c = loadDefaultBalance().controls;
    expect(c.boostLv0FuelSec, 0);
    expect(c.boostCutOnLand, isTrue);
    expect(c.gestureTapMaxSec, 0.18);
  });

  test('스테이지는 RC stage_table = {"stages": [...]} 형식 (GDD §4)', () {
    final table = rawDefaults()['stage_table'] as Map<String, dynamic>;
    final first =
        (table['stages'] as List<dynamic>).first as Map<String, dynamic>;
    expect(first['id'], '1-1');
    expect(first['world'], 1);
    expect(first['goal'], 25);
    final s = loadDefaultBalance().world.stage(3, 3);
    expect(s.id, '3-3');
    expect(s.targetM, 3800);
  });

  test('스테이지 id 가 world 와 어긋나면 거부한다', () {
    final raw = rawDefaults();
    final stages =
        (raw['stage_table'] as Map<String, dynamic>)['stages'] as List<dynamic>;
    (stages.first as Map<String, dynamic>)['id'] = '2-1';
    expect(
      () => BalanceConfig.fromJson(raw),
      throwsA(
        isA<JsonFormatError>().having((e) => e.path, 'path', endsWith('.id')),
      ),
    );
  });

  test('설정은 수정할 수 없다', () {
    final config = loadDefaultBalance();
    expect(config.zones.clear, throwsUnsupportedError);
    expect(
      () => config.upgrades.remove(UpgradeType.boost),
      throwsUnsupportedError,
    );
  });
}
