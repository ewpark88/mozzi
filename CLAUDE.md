# 모찌 런처 (mozzi) — 에이전트 작업 가이드

말랑한 햄스터 '모찌'를 당겨 달까지 날리는 하이브리드 캐주얼 게임. Flutter + Flame, Android 우선.
1인 개발, **개발계획표(docs/DEV_PLAN.md)의 Phase 순서대로만** 진행한다.

**현재 Phase: P4 — 비행 조작 3종** (P0~P3 완료. 진행 기록: docs/PROGRESS.md)

## 기준 문서 (모든 개발의 근거)
**모든 기능·수치는 아래 두 문서를 근거로 구현한다.** 구현 전에 해당 절을 읽고, 코드·테스트·PR 설명에 참조 절(예: `GDD §2`, `시트 「설정」`)을 남긴다.
| 문서 | 역할 |
|---|---|
| `모찌 런처 게임 기획서 (GDD).md` | 기능·규칙의 "무엇" |
| `모찌런처_밸런스시트.xlsx` | 모든 수치의 단일 원본 (→ `balance_defaults.json`) |
| `모찌 런처 2.5D.html` | 사용자가 만든 플레이 가능한 샘플: 2.5D 모찌 렌더링·표정 9종·게이지·합성음·연료 HUD. **손맛·연출·렌더링의 시각 기준** (P3·P7·P8). 수치가 GDD/시트와 다르면 GDD/시트가 우선이고, 차이는 사용자에게 알린다 |

두 문서가 서로 어긋나거나, 계산이 틀렸거나, 구현에 필요한 규칙이 빠져 있으면 **코드로 우회하지 말고 문서를 함께 고친다**:
1. 무엇이 왜 잘못됐는지 확인(재계산·시뮬 근거) → 2. 문서 수정(xlsx 는 `docs/CODING_RULES.md §10` 절차) →
3. `docs/SPEC_CHANGELOG.md`에 변경 전/후·근거 기록 → 4. JSON·fixture 재생성, 테스트 → 5. 사용자에게 보고.
기획 의도가 바뀌는 변경(재미·수익 방향)은 문서를 고치기 전에 사용자에게 먼저 묻는다.

**기획서는 개발 중에도 계속 바뀐다.** 항상 최신 GDD 에 맞춰 개발한다.
- 매 프롬프트마다 훅이 `tool/spec/spec_sync.py --hook` 을 실행해, 마지막 반영 이후 GDD·시트가 바뀌었으면 알려준다.
- 변경 알림을 받으면 하던 작업보다 먼저 `/spec-sync` 로 반영한다 (diff 확인 → DEV_PLAN·코드·시트 수정 → `--mark`).
- Phase 시작·종료 시에도 반드시 `spec_sync.py` 상태를 확인한다. GDD 를 고칠 때는 최소 범위로 고치고, 고친 뒤 바로 `--mark` 하지 말고 SPEC_CHANGELOG 기록 후 반영하며 결과를 사용자에게 알린다.
- 사용자가 GDD 를 수시로 갱신한다. 내 수정이 사용자 저장으로 되돌아가면 다시 덮어쓰지 말고 SPEC_CHANGELOG “GDD 수정 제안”으로 옮긴다.

## 작업 전에 반드시 읽을 문서
| 문서 | 언제 |
|---|---|
| `docs/DEV_PLAN.md` | 지금 무엇을 할 차례인지, 완료 조건(DoD) |
| `docs/ARCHITECTURE.md` | 코드를 어디에 둘지, 누가 누구를 import 할 수 있는지 |
| `docs/CODING_RULES.md` | 코드 작성 규칙 |
| `docs/BUILD_RELEASE.md` | 브랜치·커밋·버전·빌드·출시 |
| `docs/DECISIONS.md` | 과거 결정과 이유 (ADR) |

## 절대 규칙
1. 현재 Phase 범위 밖의 기능을 미리 만들지 않는다. 필요하면 DEV_PLAN 수정을 먼저 제안한다.
2. 레이어 의존 방향(`ui → game → domain ← data`, `app`이 조립)을 지킨다. `domain`/`core`는 순수 Dart.
3. 게임 규칙·물리·보상 계산은 `lib/domain/`에만 둔다. Flame 컴포넌트와 위젯은 상태를 그리기만 한다.
4. 밸런스 수치를 코드에 하드코딩하지 않는다. `BalanceConfig`(← `assets/config/balance_defaults.json` ← 엑셀)로만 읽는다.
5. 상태관리는 `flutter_riverpod` 하나만 쓴다.
6. 새 로직에는 테스트를 같이 쓴다. domain 코드는 단위 테스트 필수.
7. 완료라고 말하기 전에 `bash tool/verify.sh`(또는 `tool/verify.ps1`)를 통과시킨다. 린트를 끄거나 테스트를 지워서 통과시키지 않는다.
8. 새 패키지 추가·규칙 변경·계획 변경은 `docs/DECISIONS.md`에 ADR로 남긴다.
9. Phase 완료 시 커밋·push·main 머지는 Claude 가 한다 (사용자 지시 2026-09-28, verify·CI 통과 조건). 태그·스토어 업로드는 사용자가 요청할 때만.
10. 보호 파일(서명 키, 생성 파일, balance_defaults.json, 밸런스 fixture)은 훅이 차단한다. 우회하지 않는다.
11. GDD·밸런스 시트 수정은 오류 정정 목적일 때만, SPEC_CHANGELOG 기록과 함께 한다.

## 자주 쓰는 명령
```bash
bash tool/verify.sh                                   # 품질 게이트 (format/analyze/architecture/balance/test)
dart run tool/check_architecture.dart                 # 레이어 규칙만 검사
python tool/balance/export_balance.py                 # 엑셀 → balance_defaults.json + 테스트 fixture 재생성
python tool/balance/pacing_sim.py --compare           # 시트 「진행 시뮬」이 규칙(ADR-008)과 맞는지 확인
python tool/balance/pacing_sim.py --edits out.json    # 불일치 셀 편집 목록 → 아래로 시트에 반영
powershell -File tool/balance/xlsx_edit.ps1 -EditsJson out.json   # Excel COM 편집 (openpyxl 저장 금지)
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

## 슬래시 명령
- `/phase-start P<N>` — Phase 착수 (계획 확인 → 브랜치 → 세부 계획 승인 → 구현)
- `/phase-verify P<N>` — DoD 검증 및 PROGRESS/DEV_PLAN 갱신
- `/spec-sync` — 바뀐 GDD·밸런스 시트를 계획·코드에 반영
