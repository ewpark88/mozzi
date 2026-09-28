---
description: 현재 Phase 의 완료 조건(DoD)을 검증하고 진행 기록을 갱신한다
argument-hint: <Phase ID, 예: P1>
---
Phase $ARGUMENTS 의 완료를 검증한다.

0. `PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py` — Phase 도중 바뀐 GDD 가 있으면 먼저 반영(/spec-sync)한다.
1. `bash tool/verify.sh` 를 실행한다. 실패하면 원인을 고치고 다시 실행한다 (규칙을 끄거나 테스트를 지워서 통과시키지 않는다).
2. `docs/DEV_PLAN.md` 의 $ARGUMENTS DoD 항목을 하나씩 확인하고, 각 항목의 근거(테스트 이름, 명령 출력, 수동 확인 필요 여부)를 표로 보고한다.
3. 기기/에뮬레이터 확인이 필요한 항목은 "사용자 확인 필요"로 표시하고 확인 방법을 적는다.
4. 모두 충족되면:
   - `docs/DEV_PLAN.md` 의 해당 작업 체크박스와 상태를 갱신한다.
   - `docs/PROGRESS.md` 에 날짜·완료 항목·남은 이슈·결정사항을 추가한다.
   - `CLAUDE.md` 의 "현재 Phase" 줄을 다음 Phase 로 바꾼다.
5. 커밋은 사용자가 요청할 때만 한다 (Conventional Commits, docs/BUILD_RELEASE.md §2).
