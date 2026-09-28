---
description: 개발계획표의 Phase를 시작한다 (예: /phase-start P1)
argument-hint: <Phase ID, 예: P1>
---
Phase $ARGUMENTS 를 시작한다. 아래 순서를 반드시 지킨다.

0. `PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py` 로 기준 문서 변경을 확인한다. 바뀌었으면 먼저 `/spec-sync` 절차로 반영한다.
1. `docs/DEV_PLAN.md` 에서 $ARGUMENTS 섹션(목표, 작업 체크리스트, 산출물, DoD, GDD 참조 절)을 읽는다.
2. 참조된 GDD 절(`모찌 런처 게임 기획서 (GDD).md`)과 필요 시 밸런스 시트 값을 확인한다.
3. `docs/ARCHITECTURE.md`, `docs/CODING_RULES.md` 를 다시 확인하고, 이번 Phase에서 만들 파일을 레이어별로 나열한다.
4. 선행 Phase 의 DoD 가 `docs/PROGRESS.md` 에 완료로 기록돼 있는지 확인한다. 아니면 멈추고 보고한다.
5. `git switch -c feat/$ARGUMENTS-<short-name>` 브랜치를 만든다 (main 에서 분기).
6. 세부 구현 계획(파일 목록, 테스트 목록, 계획표와 달라지는 점)을 사용자에게 제시하고 승인을 받은 뒤 구현한다.
   - 계획표와 달라지는 결정이 있으면 `docs/DECISIONS.md` 에 ADR 로 추가한다.
