# 모찌 런처 (mozzi) — 에이전트 작업 가이드

말랑한 햄스터 '모찌'를 당겨 달까지 날리는 하이브리드 캐주얼 게임. Flutter + Flame, Android 우선.
1인 개발, **개발계획표(docs/DEV_PLAN.md)의 Phase 순서대로만** 진행한다.

**현재 Phase: P1 — 도메인 코어** (P0 완료. 진행 기록: docs/PROGRESS.md)

## 작업 전에 반드시 읽을 문서
| 문서 | 언제 |
|---|---|
| `모찌 런처 게임 기획서 (GDD).md` | 기능의 "무엇"을 정할 때 (원본, 수정 금지) |
| `모찌런처_밸런스시트.xlsx` | 수치가 필요할 때 (원본, 수정 금지) |
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
9. 커밋·push·태그·스토어 업로드는 사용자가 요청할 때만 한다.
10. 보호 파일(기획 원본, 서명 키, 생성 파일, balance_defaults.json)은 훅이 차단한다. 우회하지 않는다.

## 자주 쓰는 명령
```bash
bash tool/verify.sh                                   # 품질 게이트 (format/analyze/architecture/balance/test)
dart run tool/check_architecture.dart                 # 레이어 규칙만 검사
python tool/balance/export_balance.py                 # 엑셀 → balance_defaults.json 재생성
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

## 슬래시 명령
- `/phase-start P<N>` — Phase 착수 (계획 확인 → 브랜치 → 세부 계획 승인 → 구현)
- `/phase-verify P<N>` — DoD 검증 및 PROGRESS/DEV_PLAN 갱신
