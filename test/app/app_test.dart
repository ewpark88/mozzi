import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/app/app.dart';
import 'package:mozzi/app/bootstrap.dart';
import 'package:mozzi/core/env/app_env.dart';

void main() {
  testWidgets('앱이 flavor 이름과 함께 기동한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvProvider.overrideWithValue(
            const AppEnv(flavor: Flavor.dev, useFakeServices: true),
          ),
        ],
        child: const MozziApp(),
      ),
    );
    expect(find.text('모찌 런처 (dev)'), findsOneWidget);
  });
}
