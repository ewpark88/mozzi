import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/core/env/app_env.dart';

/// 현재 실행 환경. main_*.dart 에서 override 된다.
final appEnvProvider = Provider<AppEnv>(
  (ref) => throw UnimplementedError('appEnvProvider는 bootstrap에서 주입해야 한다'),
);

/// 모든 flavor 진입점의 공통 시작 루틴. 서비스 초기화는 여기서만 한다.
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const MozziApp(),
    ),
  );
}
