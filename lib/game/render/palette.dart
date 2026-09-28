import 'dart:ui';

/// GDD §3 캐릭터 컬러·셰이딩 색. 게임·UI 모두 이 값만 쓴다 (CODING_RULES §6).
abstract final class MochiPalette {
  static const body = Color(0xFFFFE8C7);
  static const backPatch = Color(0xFFF5A55C);
  static const blush = Color(0xFFFF9EAA);
  static const eye = Color(0xFF2B2B2B);
  static const outline = Color(0xFF6B4A2F);
  static const highlight = Color(0xFFFFF8EE);
  static const shade = Color(0xFFE8C9A0);
  static const occlusion = Color(0xFFC99A6B);
  static const rimLight = Color(0xFFBFE6F5);
}

/// 월드 1 뒷마당 플레이스홀더 색 (P7 에서 2.5D 셰이딩·구역 조명으로 교체).
abstract final class BackyardPalette {
  static const skyTop = Color(0xFF9ED8F0);
  static const skyBottom = Color(0xFFEAF7FC);
  static const far = Color(0xFFBFDCE8);
  static const mid = Color(0xFF9CCB9A);
  static const near = Color(0xFF6DB56A);
  static const grass = Color(0xFF7BC96F);
  static const grassDark = Color(0xFF5FAE55);
  static const soil = Color(0xFFC89B6D);
  static const soilDark = Color(0xFFB3865A);
  static const marker = Color(0xFF6B4A2F);
}
