/// 업그레이드 5종 (GDD §5 업그레이드 5종). 선언 순서 = 시트 열 순서 = 동점 시 우선순위.
enum UpgradeType {
  /// 고무줄: 초기 속도 +effect m/s.
  launch('upg_launch'),

  /// 공기역학: 비행거리 +effect 배율.
  aero('upg_aero'),

  /// 부스터: 추가 거리 phys_boost_k × Lv^effect m.
  boost('upg_boost'),

  /// 바운스: 거리 +effect 배율.
  bounce('upg_bounce'),

  /// 볼주머니: 씨앗 획득 +effect 배율.
  coin('upg_coin');

  const UpgradeType(this.configKey);

  /// Remote Config / balance_defaults.json 키.
  final String configKey;
}
