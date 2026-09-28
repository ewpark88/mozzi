// Claude Code PreToolUse 훅: 보호 파일 수정을 차단한다 (exit 2 = 차단 + 사유 전달).
// 보호 대상: 생성 파일, 빌드 산출물, 서명 키, 생성된 밸런스 JSON.
// 기획 원본(GDD·밸런스 시트)은 오류 수정 시 허용 — docs/SPEC_CHANGELOG.md 기록 필수.
import 'dart:io';

import 'format_on_edit.dart' show readToolFilePath;

const _blockedPatterns = <String>[
  '.g.dart',
  '/build/',
  'key.properties',
  '.jks',
  '.keystore',
  'google-services.json',
  'GoogleService-Info.plist',
  'balance_defaults.json',
  'test/fixtures/balance_sheet_expected.json',
];

Future<void> main() async {
  final path = (await readToolFilePath() ?? '').replaceAll(r'\', '/');
  for (final p in _blockedPatterns) {
    if (path.contains(p)) {
      stderr.writeln(
        '보호 파일($p)은 직접 수정할 수 없습니다. '
        '밸런스 JSON·fixture 는 tool/balance/export_balance.py 로 생성하고, '
        '서명 키는 사용자에게 요청하세요. (docs/CODING_RULES.md §10)',
      );
      exit(2);
    }
  }
}
