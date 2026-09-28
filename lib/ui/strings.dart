/// 화면 문자열 모음 (CODING_RULES §6). P8 이후 l10n 으로 옮긴다.
abstract final class Strings {
  static const appTitle = '모찌 런처';
  static const tapToLaunch = '화면을 탭하면 발사! (개발용: 45° · 힘 100%)';
  static const retry = '다시 날리기';
  static String distance(double m) => '${m.toStringAsFixed(m < 100 ? 1 : 0)} m';
  static const devLevels = '개발용 레벨 (고무줄·공기역학·바운스)';
  static String devLevel(int lv) => 'Lv $lv';
  static String devFormula(double m) => '공식 ${m.toStringAsFixed(1)} m';
}
