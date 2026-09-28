import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/core/env/app_env.dart';

/// 모든 flavor 진입점의 공통 시작 루틴. 서비스 초기화 순서는 여기서만 정한다.
///
/// 1. 밸런스 기본값 로드 (assets/config/balance_defaults.json)
/// 2. (P6) 세이브 로드 · (P9) Remote Config · Analytics · 광고 초기화
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  final balance = await loadBalanceDefaults(rootBundle);
  runApp(
    ProviderScope(
      overrides: [
        appEnvProvider.overrideWithValue(env),
        balanceConfigProvider.overrideWithValue(balance),
      ],
      child: const MozziApp(),
    ),
  );
}
