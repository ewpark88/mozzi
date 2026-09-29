/// 화면 문자열 모음 (CODING_RULES §6). P8 이후 l10n 으로 옮긴다.
abstract final class Strings {
  static const appTitle = '모찌 런처';
  static const pullHint = '화면 아무 곳이나 누른 채 뒤로 당겼다가 놓으세요';
  static const gradePerfect = 'PERFECT!';
  static const gradeGreat = 'GREAT';
  static const gradeGood = 'GOOD';
  static const gradeMiss = '아쉬워요';
  static String overPower(double power) => ' ${(power * 100).round()}%';
  static String devLaunch(String grade, double power, double mult) =>
      '$grade · 힘 ${(power * 100).round()}% · 거리 ×${mult.toStringAsFixed(3)}';
  static const retry = '다시 날리기';
  static const fuel = '연료';
  static String stageGoal(String id, double goalM) =>
      '$id · 목표 ${goalM.round()}m';
  static String stageMoon(String id) => '$id · 달 착륙';
  static String star3Mission(String text) => '★★★ $text';
  static String toGoal(double m) => '골까지 ${m.round()}m';
  static String seedsPicked(int n) => '씨앗 $n';
  static String combo(int n) => '콤보 $n';
  static const cleared = '클리어!';
  static const notCleared = '아쉬워요, 다시!';
  static const devStage = '스테이지';
  static const devFree = '자유';
  static const hintBoost = '탭: 부스터';
  static const hintInflate = '꾹: 볼 부풀리기';
  static const hintDive = '아래로 쓸기: 급강하';
  static String distance(double m) => '${m.toStringAsFixed(m < 100 ? 1 : 0)} m';
  static const devLevels = '개발용 레벨 (고무줄·공기역학·부스터·바운스)';
  static String devLevel(int lv) => 'Lv $lv';
  static String devFormula(double m) => '공식 ${m.toStringAsFixed(1)} m';
  static const devMyLevel = '내 레벨';

  // 결과 화면 (GDD §2 콤보와 착지)
  static const bossCaught = '고양이에게 잡혔어요!';
  static const bossRivalWon = '비둘기 대장이 먼저 골인했어요';
  static const bossMeterFull = '까마귀 대장이 씨앗을 다 훔쳐 갔어요';
  static String newRecord(double deltaM) => '신기록! +${deltaM.round()}m';
  static String toBest(double m) => '최고 기록까지 ${m.round()}m';
  static String seedsEarned(int n) => '씨앗 +$n';
  static String seedsBreakdown(int distance, int picked) =>
      '거리 $distance · 먹은 씨앗 $picked';
  static String comboMax(int n) => '최대 콤보 $n';
  static String adDouble(double mult) => '광고 보고 ${mult.round()}배 받기';
  static const adDone = '보너스 받음!';
  static const nextStage = '다음 스테이지';
  static const worldMap = '월드맵';
  static const upgrades = '업그레이드';

  // 보스 HUD (GDD §4 보스 스테이지 상세)
  static String catBehind(double m) => '고양이 ${m.round()}m 뒤';
  static const rival = '대장';
  static const mochi = '모찌';
  static String stolenMeter(double ratio) => '훔친 씨앗 ${(ratio * 100).round()}%';
  static String bossEase(double ratio) => '보스 완화 ${(ratio * 100).round()}%';

  // 월드맵 (GDD §4)
  static String worldTitle(int w, String name) => '월드 $w · $name';
  static String worldLocked(int stars) => '5번 클리어 + 별 $stars개';
  static String totalStars(int n, int max) => '★ $n / $max';
  static String seedsWallet(int n) => '씨앗 $n';
  static const stageBoss = '보스';

  // 업그레이드 (GDD §5)
  static String upgradeName(String key) => switch (key) {
    'upg_launch' => '고무줄',
    'upg_aero' => '공기역학',
    'upg_boost' => '부스터',
    'upg_bounce' => '바운스',
    _ => '볼주머니',
  };

  /// 업그레이드 효과 값 (시트 공식으로 계산한 값을 보여준다).
  static String upgradeValue(String key, double v) => switch (key) {
    'upg_launch' => '발사 ${v.toStringAsFixed(1)} m/s',
    'upg_boost' => '부스터 ${v.round()} m',
    _ => '×${v.toStringAsFixed(2)}',
  };
  static String upgradeLevel(int lv) => 'Lv $lv';
  static String upgradeCost(int cost) => '씨앗 $cost';
  static const back = '돌아가기';
}
