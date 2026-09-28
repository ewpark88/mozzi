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
}
