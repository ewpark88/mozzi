import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/ui/play/play_screen.dart';
import 'package:mozzi/ui/strings.dart';

/// 앱 루트 위젯. 라우팅(월드맵·결과·업그레이드)은 P6 에서 확장한다 (docs/DEV_PLAN.md).
class MozziApp extends ConsumerWidget {
  const MozziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: env.isDev,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF5A55C)),
      ),
      home: PlayScreen(
        formulas: ref.watch(balanceFormulasProvider),
        isDev: env.isDev,
      ),
    );
  }
}
