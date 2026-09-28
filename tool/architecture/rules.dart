/// 아키텍처 규칙 정의와 검사 로직. 규칙 설명은 docs/ARCHITECTURE.md §2.
///
/// 규칙을 바꾸려면 ARCHITECTURE.md와 DECISIONS.md를 먼저 수정한다.
library;

/// lib/ 아래 최상위 폴더(레이어)가 import 할 수 있는 레이어 목록.
const Map<String, Set<String>> allowedLayerDeps = {
  'core': {'core'},
  'domain': {'core', 'domain'},
  'data': {'core', 'domain', 'data'},
  'game': {'core', 'domain', 'game'},
  'ui': {'core', 'domain', 'game', 'ui'},
  'app': {'core', 'domain', 'data', 'game', 'ui', 'app'},
  // lib/main*.dart 진입점
  'entry': {'app', 'core'},
};

/// 순수 Dart 레이어. 아래 [impurePrefixes] import 가 금지된다.
const Set<String> pureLayers = {'core', 'domain'};
const List<String> impurePrefixes = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:flame',
  'package:hive',
  'dart:ui',
];

/// lib/ 파일 한 개의 최대 줄 수.
const int maxLines = 300;

final RegExp _importRe = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// [relPath]는 'lib/domain/x.dart' 형식(슬래시 구분). 위반 메시지 목록을 돌려준다.
List<String> checkFile(String relPath, String content) {
  final layer = layerOf(relPath);
  if (layer == null) {
    return ['$relPath: 허용되지 않은 위치 (lib/<layer>/ 또는 lib/main*.dart 만 가능)'];
  }

  final violations = <String>[];
  final lineCount = '\n'.allMatches(content.trimRight()).length + 1;
  if (lineCount > maxLines) {
    violations.add('$relPath: $lineCount줄 > $maxLines줄 — 파일을 분리하라');
  }

  for (final m in _importRe.allMatches(content)) {
    final uri = m.group(1)!;
    if (uri.startsWith('package:mozzi/')) {
      final target = uri.substring('package:mozzi/'.length).split('/').first;
      if (!allowedLayerDeps[layer]!.contains(target)) {
        violations.add('$relPath: $layer → $target 의존 금지 ($uri)');
      }
    } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
      violations.add('$relPath: 상대 경로 import 금지, package:mozzi/ 사용 ($uri)');
    }
    if (pureLayers.contains(layer) && impurePrefixes.any(uri.startsWith)) {
      violations.add('$relPath: $layer 는 순수 Dart 레이어 — $uri import 금지');
    }
  }
  return violations;
}

/// 파일 경로로 레이어 이름을 구한다. 알 수 없는 위치면 null.
String? layerOf(String relPath) {
  final parts = relPath.split('/');
  if (parts.length < 2 || parts.first != 'lib') return null;
  if (parts.length == 2) {
    return RegExp(r'^main(_\w+)?\.dart$').hasMatch(parts[1]) ? 'entry' : null;
  }
  final layer = parts[1];
  return allowedLayerDeps.containsKey(layer) && layer != 'entry' ? layer : null;
}
