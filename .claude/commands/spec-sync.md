---
description: 바뀐 기획서(GDD)·밸런스 시트를 개발 계획·코드에 반영한다
---
기획서는 개발 중에도 계속 바뀐다. 아래 순서로 최신 기준 문서에 맞춘다.

1. `PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py --diff` 로 마지막 반영 이후 바뀐 GDD 절과 시트 셀을 확인한다.
2. 변경을 분류해 사용자에게 짧게 보고한다:
   - **이미 구현된 부분에 영향** → 수정 작업을 현재 Phase 에 추가 (코드·테스트 수정)
   - **앞으로의 Phase 에 영향** → `docs/DEV_PLAN.md` 해당 Phase 작업·DoD 수정
   - **수치 변경** → 시트 → `export_balance.py` → 테스트. GDD 에 새 수치/RC 키가 생겼는데 시트에 없으면 시트에 추가 (xlsx_edit.ps1)
   - **GDD 와 시트, GDD 내부, GDD 와 결정(ADR)이 서로 어긋남** → 문서를 고치고 `docs/SPEC_CHANGELOG.md` 기록. 기획 의도가 걸린 충돌은 사용자에게 묻는다
3. 반영이 끝나면 `python tool/spec/spec_sync.py --mark` 로 스냅샷을 갱신하고, `docs/PROGRESS.md` 에 “GDD 반영” 항목을 남긴다.
4. `bash tool/verify.sh` 통과를 확인한다.
