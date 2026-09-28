import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozzi/core/env/app_env.dart';
import 'package:mozzi/domain/balance/balance_config.dart';
import 'package:mozzi/domain/balance/balance_formulas.dart';
import 'package:mozzi/domain/economy/upgrade_service.dart';

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

/// 번들 에셋에서 밸런스 기본값을 읽는다.
Future<BalanceConfig> loadBalanceDefaults(AssetBundle bundle) async =>
    BalanceConfig.fromJson(
      jsonDecode(await bundle.loadString(balanceDefaultsAsset)),
    );
