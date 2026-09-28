import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/app/providers.dart';
import 'package:mozzi/core/env/app_env.dart';
import 'package:mozzi/domain/balance/upgrade_type.dart';

import '../helpers/balance_fixture.dart';

void main() {
  testWidgets('앱이 flavor 이름과 함께 기동한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvProvider.overrideWithValue(
            const AppEnv(flavor: Flavor.dev, useFakeServices: true),
          ),
          balanceConfigProvider.overrideWithValue(loadDefaultBalance()),
        ],
        child: const MozziApp(),
      ),
    );
    expect(find.text('모찌 런처 (dev)'), findsOneWidget);
  });

  test('번들 에셋에서 밸런스 기본값을 읽는다 (pubspec assets 등록 확인)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final config = await loadBalanceDefaults(rootBundle);
    expect(config.upgrade(UpgradeType.launch).baseCost, 10);
  });

  test('Provider 로 공식과 업그레이드 서비스를 얻는다', () {
    final container = ProviderContainer(
      overrides: [
        balanceConfigProvider.overrideWithValue(loadDefaultBalance()),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container
          .read(upgradeServiceProvider)
          .formulas
          .upgradeCost(
            UpgradeType.boost,
            0,
          ),
      25,
    );
  });
}
