import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/core/env/app_env.dart';
import 'package:mozzi/data/fake/fake_ad_service.dart';
import 'package:mozzi/data/fake/silent_sound_service.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/economy/upgrade_service.dart';
import 'package:mozzi/domain/onboarding/onboarding.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/domain/progress/run_recorder.dart';
import 'package:mozzi/domain/services/ad_service.dart';
import 'package:mozzi/domain/services/save_store.dart';
import 'package:mozzi/domain/services/sound_service.dart';

/// 밸런스 기본값 에셋 경로 (← tool/balance/export_balance.py 가 생성).
const balanceDefaultsAsset = 'assets/config/balance_defaults.json';

/// 현재 실행 환경. bootstrap 에서 주입된다.
final appEnvProvider = Provider<AppEnv>(
  (ref) => throw UnimplementedError('appEnvProvider는 bootstrap에서 주입해야 한다'),
);

/// 밸런스 값. bootstrap 에서 에셋을 읽어 주입된다 (P9 에서 Remote Config 병합).
final balanceConfigProvider = Provider<BalanceConfig>(
  (ref) =>
      throw UnimplementedError('balanceConfigProvider는 bootstrap에서 주입해야 한다'),
);

final balanceFormulasProvider = Provider<BalanceFormulas>(
  (ref) => BalanceFormulas(ref.watch(balanceConfigProvider)),
);

final upgradeServiceProvider = Provider<UpgradeService>(
  (ref) => UpgradeService(ref.watch(balanceFormulasProvider)),
);

final runRecorderProvider = Provider<RunRecorder>(
  (ref) => RunRecorder(ref.watch(balanceConfigProvider)),
);

/// 세이브 저장소. bootstrap 에서 주입 (모든 flavor Hive, 테스트는 메모리 — ADR-017).
final saveStoreProvider = Provider<SaveStore>(
  (ref) => throw UnimplementedError('saveStoreProvider는 bootstrap에서 주입해야 한다'),
);

/// 앱 시작 시 불러온 진행 상태 (없으면 새 게임). bootstrap 에서 주입.
final initialProgressProvider = Provider<PlayerProgress>(
  (ref) => PlayerProgress.initial,
);

/// 광고. P9 전까지 모든 flavor 가짜 구현 (보상형 = 항상 시청 완료).
final adServiceProvider = Provider<AdService>((ref) => FakeAdService());

/// 효과음. bootstrap 에서 합성음을 불러온 flutter_soloud 구현으로 주입 (테스트는 무음).
final soundServiceProvider = Provider<SoundService>(
  (ref) => SilentSoundService(),
);

final onboardingProvider = Provider<Onboarding>(
  (ref) => Onboarding(ref.watch(balanceFormulasProvider)),
);

/// 번들 에셋에서 밸런스 기본값을 읽는다.
Future<BalanceConfig> loadBalanceDefaults(AssetBundle bundle) async =>
    BalanceConfig.fromJson(
      jsonDecode(await bundle.loadString(balanceDefaultsAsset)),
    );
