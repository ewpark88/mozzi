import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozzi/domain/progress/player_progress.dart';
import 'package:mozzi/ui/dev/mochi_gallery_screen.dart';
import 'package:mozzi/ui/strings.dart';
import 'package:mozzi/ui/world_map/world_map_screen.dart';

import '../helpers/balance_fixture.dart';

/// DEV_PLAN P7 개발용 갤러리: 표정 9종 × 월드 조명 3종.
void main() {
  Future<void> pump(WidgetTester tester, Size size, Widget w) async {
    tester.view
      ..physicalSize = size * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: w));
    await tester.pump();
  }

  for (final size in const [Size(915, 412), Size(568, 320), Size(1024, 768)]) {
    testWidgets('갤러리 ${size.width.toInt()}×${size.height.toInt()}', (
      tester,
    ) async {
      await pump(tester, size, MochiGalleryScreen(onBack: () {}));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(27));
      await tester.tap(find.text(Strings.galleryLowSpec));
      await tester.tap(find.text(Strings.galleryFly));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('월드맵의 갤러리 버튼은 dev 에서만 (콜백이 있을 때만)', (tester) async {
    final config = loadDefaultBalance();
    Widget map({VoidCallback? gallery}) => WorldMapScreen(
      config: config,
      progress: PlayerProgress.initial,
      onStage: (_) {},
      onUpgrades: () {},
      onGallery: gallery,
    );
    await pump(tester, const Size(915, 412), map());
    expect(find.text(Strings.gallery), findsNothing);
    await pump(tester, const Size(915, 412), map(gallery: () {}));
    expect(find.text(Strings.gallery), findsOneWidget);
  });
}
