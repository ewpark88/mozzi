#!/usr/bin/env bash
# 품질 게이트. 작업 완료 선언·커밋·PR 전 반드시 통과해야 한다. (docs/CODING_RULES.md §11)
# 사용법: bash tool/verify.sh        (CI 도 동일 스크립트 사용)
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s ==\n' "$1"; }

step "1/5 format"
dart format --output=none --set-exit-if-changed lib test tool

step "2/5 analyze"
flutter analyze --fatal-infos --fatal-warnings

step "3/5 architecture"
dart run tool/check_architecture.dart

step "4/5 balance sync"
if command -v python >/dev/null 2>&1 && python -c "import openpyxl" 2>/dev/null; then
  PYTHONIOENCODING=utf-8 python tool/balance/export_balance.py --check
else
  echo "skip (python/openpyxl 없음)"
fi

step "5/5 test"
flutter test

step "info: spec sync (경고만)"
if command -v python >/dev/null 2>&1 && python -c "import openpyxl" 2>/dev/null; then
  PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py || true
fi

printf '\nverify PASSED\n'
