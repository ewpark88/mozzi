/// 해금 키 (세이브 `unlocks`). 보스 클리어 보상 (GDD §4 보스 스테이지 상세).
///
/// P6 에서는 해금 기록만 한다. 병아리·모자 슬롯·카피바라의 실제 기능은 P12,
/// 조작 해금은 바로 적용된다 (볼 부풀리기·급강하).
abstract final class Unlock {
  static const String controlInflate = 'control_inflate';
  static const String controlDive = 'control_dive';
  static const String chick = 'char_chick';
  static const String hatSlot = 'slot_hat';
  static const String capybara = 'char_capybara';

  /// 보스 스테이지 ID → 클리어 보상.
  static const Map<String, List<String>> bossRewards = {
    '1-5': [chick, controlInflate, controlDive],
    '2-5': [hatSlot],
    '3-5': [capybara],
  };
}
