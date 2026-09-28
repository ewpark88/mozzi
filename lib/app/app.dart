import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/providers.dart';

/// 앱 루트 위젯. 라우팅·테마는 P6에서 확장한다 (docs/DEV_PLAN.md).
class MozziApp extends ConsumerWidget {
  const MozziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    return MaterialApp(
      title: '모찌 런처',
      debugShowCheckedModeBanner: env.isDev,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF5A55C)),
      ),
      home: Scaffold(
        body: Center(child: Text('모찌 런처 (${env.flavor.name})')),
      ),
    );
  }
}
