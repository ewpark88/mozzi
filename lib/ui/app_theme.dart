import 'package:flutter/material.dart';
import 'package:mozzi/game/render/palette.dart';

/// OFL 폰트 (GDD §3 제작 원칙, ADR-019). pubspec `fonts` 의 family 이름.
abstract final class AppFonts {
  /// 제목·숫자·버튼: 둥글고 굵은 Jua.
  static const title = 'Jua';

  /// 본문·안내: 읽기 쉬운 Gowun Dodum.
  static const body = 'GowunDodum';
}

/// 앱 테마: 본문은 Gowun Dodum, 제목·버튼·굵은 글자는 Jua.
ThemeData appTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: MochiPalette.backPatch),
    fontFamily: AppFonts.body,
  );
  TextStyle? jua(TextStyle? s) => s?.copyWith(fontFamily: AppFonts.title);
  final t = base.textTheme;
  return base.copyWith(
    textTheme: t.copyWith(
      displayLarge: jua(t.displayLarge),
      displayMedium: jua(t.displayMedium),
      displaySmall: jua(t.displaySmall),
      headlineLarge: jua(t.headlineLarge),
      headlineMedium: jua(t.headlineMedium),
      headlineSmall: jua(t.headlineSmall),
      titleLarge: jua(t.titleLarge),
      titleMedium: jua(t.titleMedium),
      labelLarge: jua(t.labelLarge),
    ),
  );
}
