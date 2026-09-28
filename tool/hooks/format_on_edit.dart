// Claude Code PostToolUse 훅: 편집된 .dart 파일을 즉시 dart format 한다.
// stdin 으로 훅 JSON({"tool_input":{"file_path":...}})을 받는다.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final path = await readToolFilePath();
  if (path == null || !path.endsWith('.dart')) return;
  if (path.endsWith('.g.dart') || !File(path).existsSync()) return;
  final result = await Process.run('dart', ['format', path], runInShell: true);
  if (result.exitCode != 0) stderr.write(result.stderr);
}

/// 훅 입력 JSON 에서 tool_input.file_path 를 꺼낸다. 없으면 null.
Future<String?> readToolFilePath() async {
  final raw = await stdin.transform(utf8.decoder).join();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final input = decoded['tool_input'];
    if (input is! Map<String, dynamic>) return null;
    final path = input['file_path'];
    return path is String ? path : null;
  } on FormatException {
    return null;
  }
}
