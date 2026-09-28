import 'dart:convert';
import 'dart:io';

import 'package:mozzi/domain/balance/balance_config.dart';

/// 앱과 같은 밸런스 기본값 (assets/config/balance_defaults.json).
BalanceConfig loadDefaultBalance() => BalanceConfig.fromJson(
  jsonDecode(File('assets/config/balance_defaults.json').readAsStringSync()),
);

/// 밸런스 시트 결과값 (test/fixtures/balance_sheet_expected.json ← export_balance.py).
/// 도메인 코드가 시트와 같은 결과를 내는지 비교하는 정답지다.
class SheetFixture {
  SheetFixture._(this._json);

  factory SheetFixture.load() => SheetFixture._(
    jsonDecode(
          File('test/fixtures/balance_sheet_expected.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> _json;

  List<UpgradeTableRow> get upgradeTable => [
    for (final row in _json['upgrade_table'] as List<dynamic>)
      UpgradeTableRow(row as Map<String, dynamic>),
  ];

  List<PacingRow> get pacingRuns => [
    for (final row in _json['pacing_runs'] as List<dynamic>)
      PacingRow(row as Map<String, dynamic>),
  ];

  Map<String, dynamic> get _stageReach =>
      _json['stage_reach'] as Map<String, dynamic>;

  /// 「스테이지」 시트 1-1 ~ 5-5 목표 거리 (m).
  List<double> get stageTargetsM => [
    for (final v in _stageReach['target_m'] as List<dynamic>)
      (v as num).toDouble(),
  ];

  /// 「스테이지」 시트 스테이지별 누적 도달 판수. 시나리오 키: none, ad100.
  List<int> stageReach(String scenario) => [
    for (final v in _stageReach[scenario] as List<dynamic>) v as int,
  ];

  /// 시나리오 키(none, ad30, ad100) → 구역 1~6 도달 판수.
  List<int> zoneReach(String scenario) => [
    for (final v
        in (_json['zone_reach'] as Map<String, dynamic>)[scenario]
            as List<dynamic>)
      v as int,
  ];
}

/// 「업그레이드표」 한 행.
class UpgradeTableRow {
  UpgradeTableRow(this._row);

  final Map<String, dynamic> _row;

  int get level => _row['lv'] as int;
  List<int> get costs => [
    for (final c in _row['costs'] as List<dynamic>) c as int,
  ];
  double _d(String key) => (_row[key] as num).toDouble();
  double get launchSpeed => _d('launch_speed');
  double get aeroMult => _d('aero_mult');
  double get boostM => _d('boost_m');
  double get bounceMult => _d('bounce_mult');
  double get coinMult => _d('coin_mult');
  double get distanceAllSameLv => _d('distance_all_same_lv');
}

/// 「진행 시뮬」 한 판.
class PacingRow {
  PacingRow(this._row);

  final Map<String, dynamic> _row;

  int get run => _row['run'] as int;
  int distance(String scenario) =>
      (_row['distance'] as Map<String, dynamic>)[scenario] as int;
  int seeds(String scenario) =>
      (_row['seeds'] as Map<String, dynamic>)[scenario] as int;

  /// 광고X 시나리오의 판 종료 후 레벨 (launch, aero, boost, bounce, coin).
  List<int> get levelsNone => [
    for (final v in _row['levels_none'] as List<dynamic>) v as int,
  ];
}
