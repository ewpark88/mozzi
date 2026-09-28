# 코드 작성 규칙

> 자동 검사: `analysis_options.yaml`(very_good_analysis + strict 모드), `tool/check_architecture.dart`, `dart format`.
> 자동으로 못 잡는 규칙은 리뷰(`/phase-verify`) 때 이 문서로 확인한다.

## 1. 네이밍
| 대상 | 규칙 | 예 |
|---|---|---|
| 파일 | `snake_case.dart`, 파일 하나 = 주요 타입 하나 | `flight_simulator.dart` |
| 클래스/enum | `UpperCamelCase`, 명사 | `FlightSimulator`, `UpgradeType` |
| 메서드/변수 | `lowerCamelCase`, 메서드는 동사 | `step()`, `costOf(level)` |
| 상수 | `lowerCamelCase` (`const`) | `const fixedDt = 1 / 60;` |
| Provider | `<대상>Provider` | `walletProvider` |
| 화면/컨트롤러 | `<feature>_screen.dart`, `<feature>_controller.dart` | `result_screen.dart` |
| Flame 컴포넌트 | `<대상>Component` | `MozziComponent` |
| 테스트 | 원본 경로 미러링 + `_test.dart` | `test/domain/sim/flight_simulator_test.dart` |

- 용어는 GDD 용어를 영어로 고정해서 쓴다: 씨앗=`seed`, 별사탕=`candy`, 황금 해바라기씨=`goldenSeed`, 고무줄=`launch`, 공기역학=`aero`, 부스터=`boost`, 바운스=`bounce`, 볼주머니=`coin`, 볼 부풀리기=`inflate`, 급강하=`dive`, 구역=`zone`, 청크=`chunk`, 한 판=`run`.
- 단위가 있는 값은 이름에 단위를 붙인다: `distanceM`, `speedMps`, `durationSec`.

## 2. 파일·함수 크기
- lib/ 파일 **300줄 이하** (자동 검사). 넘으면 책임을 나눈다.
- 함수는 40줄 이하를 목표로 한다. 중첩 3단계 이상이면 추출한다.
- 위젯 `build()`가 60줄을 넘으면 하위 위젯 클래스로 분리한다 (헬퍼 메서드가 아닌 클래스).

## 3. 수치·밸런스
- 밸런스 수치(비용, 효과, 확률, 속도, 배율, 광고 빈도)는 **코드에 쓰지 않는다**. `BalanceConfig`에서 읽는다.
- 밸런스가 아닌 고정 상수(고정 timestep, 청크 길이 100m 같은 구조 상수)는 해당 도메인 파일 상단 `const`로 이름 붙여 선언한다.
- 수치 비교 테스트는 허용오차를 명시한다 (`closeTo(871.59, 0.01)`).

## 4. 도메인 코드
- `lib/domain`, `lib/core`는 순수 Dart. Flutter·Flame·Riverpod·Hive import 금지 (자동 검사).
- 도메인 모델은 불변(immutable): `final` 필드 + `copyWith`. 컬렉션은 수정 불가 뷰로 노출.
- 시간·난수는 주입받는다 (`DateTime.now()`, `Random()` 직접 호출 금지 → `Clock`, `SeededRng`).
- 공개 클래스·메서드에는 `///` 문서 주석을 단다 (한 줄이라도 “왜/무엇”).

## 5. Flame(game) 코드
- 컴포넌트는 시뮬 상태를 읽어 그리기만 한다. 위치·속도를 컴포넌트가 직접 바꾸지 않는다.
- `update(dt)`에서 물리 계산 금지 → `FixedStepper`로 `FlightSimulator.step()` 호출.
- 매 프레임 객체 생성 금지(Paint, Vector2 등은 필드로 재사용). 화면 밖 청크 컴포넌트는 제거/풀링.

## 6. UI(Flutter) 코드
- 화면 로직은 `<feature>_controller.dart`(Notifier)에 두고, 위젯은 상태 표시와 이벤트 전달만 한다.
- 문자열은 P7 이전까지 `ui/strings.dart` 한 곳에 모은다 (이후 l10n 전환). 위젯에 문자열 리터럴 산재 금지.
- 색상·간격·글꼴은 `app/theme`에서 가져온다. GDD 캐릭터 컬러(#FFE8C7 등)는 테마 상수로 한 번만 정의.

## 7. 에러 처리·로그
- 예상 가능한 실패(광고 미로드, 결제 취소, 네트워크)는 예외 대신 `Result`/상태로 돌려준다.
- `catch (e)`로 삼키지 않는다. 잡으면 로그를 남기고 사용자에게 의미 있는 상태로 바꾼다.
- `print` 금지 → `core` 로거 인터페이스 사용 (release 빌드에서는 무음).

## 8. 테스트
| 레이어 | 필수 테스트 |
|---|---|
| domain | 단위 테스트 필수. 공식은 밸런스 시트 값과 비교, 시뮬은 시드 고정 재현성 테스트 |
| data | Fake 는 계약 테스트, Hive 는 저장→복원 왕복 테스트 |
| ui | 주요 화면 위젯 테스트 (컨트롤러는 단위 테스트) |
| game | 입력 → 도메인 명령 변환 테스트. 렌더링은 수동 확인 |
- 테스트 이름은 한국어 문장으로 “무엇이 어떻게 된다”를 쓴다.
- 버그를 고치면 그 버그를 재현하는 테스트를 먼저 추가한다.
- 테스트를 삭제·skip 해서 verify 를 통과시키지 않는다.

## 9. 의존성
- 새 패키지는 `docs/DECISIONS.md`에 사유·대안을 적은 뒤 `flutter pub add`로 추가한다.
- Phase 에 필요할 때만 추가한다 (예: Firebase·AdMob 은 P9).
- 버전은 caret(`^`)으로 두고 `pubspec.lock`은 커밋한다.

## 10. 보호 파일과 기준 문서 수정 절차
**훅이 수정을 차단하는 파일**
- 생성 파일: `assets/config/balance_defaults.json`, `test/fixtures/balance_sheet_expected.json`(둘 다 `export_balance.py`로 생성), `*.g.dart`, `build/`
- 비밀: `key.properties`, `*.jks`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist`

**기준 문서(GDD·밸런스 시트) — 오류 정정 시에만 수정**
- 모든 구현은 GDD 와 밸런스 시트를 근거로 한다. 코드 주석·테스트 이름·PR 설명에 참조 절을 남긴다.
- 문서 오류(계산 오류, 문서 간 불일치, 누락된 규칙, 오탈자)를 발견하면 코드로 우회하지 않고 문서를 함께 고친다.
- GDD(.md): 직접 편집. 변경한 절만 최소로 고친다.
- 밸런스 시트(.xlsx): **Excel COM 으로 편집·재계산·저장**한다 (`tool/balance/xlsx_edit.ps1`, P1 에서 추가).
  openpyxl 로 저장하면 수식 결과(캐시 값)가 사라져 export 가 깨지므로 openpyxl 은 읽기 전용으로만 쓴다.
  「진행 시뮬」처럼 Python 결과값이 붙여 넣어진 시트는 `tool/balance/pacing_sim.py`로 재생성해 반영한다.
- 수정 후: `export_balance.py` 실행 → verify → `docs/SPEC_CHANGELOG.md`에 기록(날짜, 문서·위치, 변경 전/후, 근거).
- 기획 의도(재미·수익 방향)가 바뀌는 수정은 먼저 사용자 승인을 받는다.

**기준 문서 변경 추적** — `tool/spec/spec_sync.py`
- `docs/spec_snapshot/` = 마지막으로 개발에 반영한 GDD·시트. 현재 문서와 비교해 바뀐 절/셀을 보여준다.
- 반영 절차는 `/spec-sync`. 반영 전에는 `--mark` 하지 않는다 (알림이 사라지므로).

## 11. 완료의 정의 (모든 작업 공통)
1. `bash tool/verify.sh` 통과 (format → analyze(info 도 실패) → architecture → balance sync → test)
2. 새 로직에 테스트 존재
3. 해당 Phase 문서 체크박스·PROGRESS 갱신
4. 규칙·계획에서 벗어난 결정은 DECISIONS.md 에 기록

## 12. 금지 패턴 요약
- 전역 가변 싱글톤, `static` 가변 상태
- `dynamic` 남용, `as` 강제 캐스팅으로 타입 우회 (JSON 파싱은 검증 후 변환)
- 위젯/컴포넌트 안의 게임 규칙 계산
- 주석 처리된 죽은 코드 커밋, `// ignore:` 남발 (필요 시 사유 주석 필수)
- 현재 Phase 범위 밖 기능의 “미리 만들어 두기”
