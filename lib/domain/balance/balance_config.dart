import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

/// 업그레이드 한 종의 밸런스 값 (시트 「설정」 업그레이드 표 한 행).
class UpgradeSpec {
  const UpgradeSpec({
    required this.baseCost,
    required this.costGrowth,
    required this.effect,
  });

  factory UpgradeSpec.fromJson(JsonReader json) => UpgradeSpec(
    baseCost: json.number('base'),
    costGrowth: json.number('growth'),
    effect: json.number('effect'),
  );

  /// Lv0 → Lv1 비용 (씨앗).
  final double baseCost;

  /// 레벨당 비용 증가율.
  final double costGrowth;

  /// Lv당 효과. 의미는 [UpgradeType] 별로 다르다.
  final double effect;
}

/// 구역 정의 (GDD §4 구역 구성, 시트 「설정」 구역 표).
class ZoneSpec {
  const ZoneSpec({
    required this.id,
    required this.name,
    required this.startM,
    required this.targetRunsNoAd,
  });

  factory ZoneSpec.fromJson(JsonReader json) => ZoneSpec(
    id: json.integer('id'),
    name: json.string('name'),
    startM: json.number('start_m'),
    targetRunsNoAd: json.integer('target_runs_no_ad'),
  );

  final int id;
  final String name;

  /// 구역 시작 거리 (m).
  final double startM;

  /// 광고를 보지 않을 때 목표 도달 판수 (설계 의도).
  final int targetRunsNoAd;
}

/// 게임 전체 밸런스 값. `assets/config/balance_defaults.json`(← 밸런스 시트)에서 만들고,
/// P9 부터 Remote Config 값으로 덮어쓴다. 밸런스 수치는 이 객체로만 읽는다. (CODING_RULES §3)
class BalanceConfig {
  BalanceConfig({
    required Map<UpgradeType, UpgradeSpec> upgrades,
    required this.baseLaunchSpeedMps,
    required this.gravityMps2,
    required this.boostDistanceK,
    required this.seedsPerM,
    required this.runDurationSec,
    required this.simTimeScale,
    required this.cameraBasePxPerM,
    required List<ZoneSpec> zones,
  }) : upgrades = Map.unmodifiable(upgrades),
       zones = List.unmodifiable(zones) {
    final missing = UpgradeType.values.where((t) => !upgrades.containsKey(t));
    if (missing.isNotEmpty) {
      throw ArgumentError('업그레이드 설정 누락: ${missing.map((t) => t.name)}');
    }
  }

  /// JSON 을 읽는다. 키 누락·타입 오류는 [JsonFormatError].
  factory BalanceConfig.fromJson(Object? json) {
    final r = JsonReader(json);
    return BalanceConfig(
      upgrades: {
        for (final t in UpgradeType.values)
          t: UpgradeSpec.fromJson(r.object(t.configKey)),
      },
      baseLaunchSpeedMps: r.number('phys_v0'),
      gravityMps2: r.number('phys_g'),
      boostDistanceK: r.number('phys_boost_k'),
      seedsPerM: r.number('coin_per_m'),
      runDurationSec: r.number('run_sec'),
      simTimeScale: r.number('sim_time_scale'),
      cameraBasePxPerM: r.number('cam_base_px_per_m'),
      zones: r.objectList('zones').map(ZoneSpec.fromJson).toList(),
    );
  }

  final Map<UpgradeType, UpgradeSpec> upgrades;

  /// `phys_v0` 고무줄 Lv0 발사 속도 (m/s).
  final double baseLaunchSpeedMps;

  /// `phys_g` 중력 (m/s²).
  final double gravityMps2;

  /// `phys_boost_k` 부스터 거리 계수 (m).
  final double boostDistanceK;

  /// `coin_per_m` 1m 당 씨앗.
  final double seedsPerM;

  /// `run_sec` 1판 평균 시간 (초, 페이싱 환산용).
  final double runDurationSec;

  /// `sim_time_scale` 시뮬 재생 배율. 시뮬은 실제 미터·중력으로 계산하고 이 배율로
  /// 빨리 재생해 2.5D 샘플과 같은 체감을 낸다 (ADR-012).
  final double simTimeScale;

  /// `cam_base_px_per_m` 가상 화면(높이 540) 기준 Lv0 카메라 배율 (px/m).
  final double cameraBasePxPerM;

  /// 구역 목록 (시작 거리 오름차순).
  final List<ZoneSpec> zones;

  UpgradeSpec upgrade(UpgradeType type) => upgrades[type]!;
}
