import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/rules.dart';

void main() {
  group('layerOf', () {
    test('레이어 폴더와 진입점을 구분한다', () {
      expect(layerOf('lib/domain/sim/flight.dart'), 'domain');
      expect(layerOf('lib/main_dev.dart'), 'entry');
      expect(layerOf('lib/random.dart'), isNull);
      expect(layerOf('lib/utils/x.dart'), isNull);
    });
  });

  group('checkFile', () {
    test('허용된 의존은 통과한다', () {
      expect(
        checkFile(
          'lib/domain/a.dart',
          "import 'package:mozzi/core/env/app_env.dart';",
        ),
        isEmpty,
      );
      expect(
        checkFile('lib/ui/a.dart', "import 'package:mozzi/game/g.dart';"),
        isEmpty,
      );
    });

    test('domain 에서 flutter/flame import 는 위반이다', () {
      expect(
        checkFile(
          'lib/domain/a.dart',
          "import 'package:flutter/material.dart';",
        ),
        hasLength(1),
      );
      expect(
        checkFile('lib/domain/a.dart', "import 'package:flame/game.dart';"),
        hasLength(1),
      );
    });

    test('역방향 레이어 의존은 위반이다', () {
      expect(
        checkFile('lib/domain/a.dart', "import 'package:mozzi/data/x.dart';"),
        hasLength(1),
      );
      expect(
        checkFile('lib/game/a.dart', "import 'package:mozzi/ui/x.dart';"),
        hasLength(1),
      );
      expect(
        checkFile('lib/data/a.dart', "import 'package:mozzi/game/x.dart';"),
        hasLength(1),
      );
    });

    test('상대 경로 import 는 위반이다', () {
      expect(
        checkFile('lib/game/a.dart', "import '../domain/x.dart';"),
        hasLength(1),
      );
    });

    test('300줄 초과 파일은 위반이다', () {
      final long = List.filled(maxLines + 1, '// x').join('\n');
      expect(checkFile('lib/core/a.dart', long), hasLength(1));
    });
  });
}
