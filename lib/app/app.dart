import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/app/routes.dart';
import 'package:mozzi/ui/strings.dart';

/// 앱 루트 위젯. 첫 화면 = 월드맵 (화면 흐름은 routes.dart).
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
      home: const WorldMapRoute(),
    );
  }
}
