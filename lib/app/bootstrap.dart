import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/core/env/app_env.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/data/save/hive_save_store.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/services/save_store.dart';

/// 모든 flavor 진입점의 공통 시작 루틴. 서비스 초기화 순서는 여기서만 정한다.
///
/// 0. 화면 방향·시스템 UI
/// 1. 밸런스 기본값 로드 (assets/config/balance_defaults.json)
/// 2. 세이브 로드 (Hive) · (P9) Remote Config · Analytics · 광고 초기화
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  // 가로 고정 (ADR-011). 좌·우 가로 모두 허용, 몰입 모드.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final balance = await loadBalanceDefaults(rootBundle);
  await Hive.initFlutter();
  final store = await HiveSaveStore.open();
  final progress = await _loadProgress(store);
  runApp(
    ProviderScope(
      overrides: [
        appEnvProvider.overrideWithValue(env),
        balanceConfigProvider.overrideWithValue(balance),
        saveStoreProvider.overrideWithValue(store),
        initialProgressProvider.overrideWithValue(progress),
      ],
      child: const MozziApp(),
    ),
  );
}

/// 세이브를 읽는다. 없으면 새 게임. 손상됐거나 앱보다 새 버전이면 로그를 남기고 새 게임
/// (다음 저장 때 덮어씀 — v1.1 Firestore 백업 전까지의 한계).
Future<PlayerProgress> _loadProgress(SaveStore store) async {
  try {
    return await store.load() ?? PlayerProgress.initial;
  } on JsonFormatError catch (e) {
    debugPrint('세이브 손상, 새 게임으로 시작: $e');
  } on UnsupportedSaveVersion catch (e) {
    debugPrint('세이브 버전이 앱보다 새로움, 새 게임으로 시작: $e');
  }
  return PlayerProgress.initial;
}
