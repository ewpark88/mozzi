/// 오브젝트 분류 (시트 「오브젝트」 분류 열). 효과 처리 방식을 정한다.
enum ObjectCategory {
  /// 먹는 것 (씨앗).
  pickup,

  /// 위에서 닿으면 튕김 (트램폴린·빨랫줄). 급강하 배율 대상.
  bounce,

  /// 위로 띄움 (풍선·분수).
  lift,

  /// 가속 (비둘기 올라타기).
  boost,

  /// 영역 안에서 계속 힘 (상승기류).
  area,

  /// 일정 시간 활공 (빨간 우산).
  glide,

  /// 씨앗 폭발 (광고판).
  seeds,

  /// 장애물: 감속만, 비행은 계속 (GDD §4 배치 규칙).
  obstacle;

  static ObjectCategory parse(String key) => ObjectCategory.values.firstWhere(
    (c) => c.name == key,
    orElse: () => throw ArgumentError.value(key, 'category', '알 수 없는 분류'),
  );
}

/// 오브젝트 종류 (GDD §4 월드 테마). 키 = 시트·미션 JSON 의 obj 값.
enum ObjectKind {
  seed('seed'),
  tramp('tramp'),
  clothesline('clothesline'),
  balloon('balloon'),
  fountain('fountain'),
  pigeon('pigeon'),
  updraft('updraft'),
  umbrella('umbrella'),
  billboard('billboard'),
  branch('branch'),
  wire('wire'),
  crow('crow');

  const ObjectKind(this.key);

  final String key;

  /// 땅 위에 놓이는 오브젝트 (높이 0).
  bool get onGround => this == tramp || this == fountain || this == updraft;

  static ObjectKind? tryParse(String key) {
    for (final k in values) {
      if (k.key == key) return k;
    }
    return null;
  }
}
