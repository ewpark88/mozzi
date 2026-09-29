# 아키텍처

> 이 문서의 레이어 규칙은 `tool/check_architecture.dart`가 자동으로 검사한다 (verify 3단계).
> 규칙을 바꿀 때는 이 문서 → `tool/architecture/rules.dart` → `docs/DECISIONS.md` 순으로 함께 고친다.

## 1. 설계 목표
- **로직과 표현의 분리**: 한 판의 모든 규칙(발사, 비행, 충돌, 보상)은 순수 Dart로 돌아가고, Flame/Flutter는 그 상태를 그리고 입력을 전달만 한다.
  → 화면 없이 테스트로 한 판을 끝까지 재현하고, 밸런스 시트 값과 비교할 수 있다.
- **결정론**: 같은 시드 + 같은 입력 = 같은 결과. 고정 timestep(1/60초), 시드 RNG만 사용. (데일리 챌린지·리플레이 대비)
- **원격 조정**: 모든 밸런스 값은 `BalanceConfig` 하나로 들어오고, 기본값(JSON) → Remote Config 순으로 덮어쓴다.
- **교체 가능한 외부 서비스**: Remote Config, Analytics, 광고, 결제, 저장소는 domain 인터페이스 뒤에 두고 Fake 구현으로 먼저 개발한다.

## 2. 레이어와 의존 방향
```
            app  (조립: DI, 부트스트랩, 라우팅)
          ↙  ↓  ↘
        ui → game        data
          ↘   ↓         ↙
            domain  ←──┘
              ↓
             core
```
| 레이어 | 경로 | 역할 | import 가능 | 금지 |
|---|---|---|---|---|
| core | `lib/core/` | 공용 유틸: 결정론 RNG, Result, 로거 인터페이스, 환경값 | core | flutter, flame, riverpod, hive, dart:ui |
| domain | `lib/domain/` | 게임 규칙·시뮬·경제·진행·서비스 인터페이스 | core, domain | flutter, flame, riverpod, hive, dart:ui |
| data | `lib/data/` | domain 인터페이스 구현(Hive, Firebase, AdMob, IAP, Fake) | core, domain, data | game, ui |
| game | `lib/game/` | Flame 게임, 컴포넌트(렌더), 카메라, 패럴랙스, 입력 변환 | core, domain, game | data, ui |
| ui | `lib/ui/` | Flutter 화면·오버레이·HUD, 화면별 컨트롤러(Notifier) | core, domain, game, ui | data |
| app | `lib/app/` | ProviderScope 조립, 서비스 구현 주입, 라우팅, 테마 | 전부 | — |
| entry | `lib/main*.dart` | flavor 진입점 → `bootstrap()` 호출만 | app, core | 그 외 |

- `lib/` 바로 아래에는 `main*.dart`만 둘 수 있다. 새 최상위 폴더 금지.
- 모든 내부 import는 `package:mozzi/...` 형식 (상대 경로 금지).
- ui가 data 구현을 직접 쓰지 않는다. 필요한 서비스는 app에서 Provider로 주입받는다.

## 3. 폴더 구조 (목표 형태)
```
lib/
  main.dart / main_dev.dart / main_prod.dart
  app/
    bootstrap.dart          # 초기화 순서의 유일한 장소
    app.dart                # MaterialApp, 라우팅
    providers.dart          # 서비스 구현 → 인터페이스 바인딩
  core/
    env/app_env.dart        # flavor, Fake 사용 여부
    random/seeded_rng.dart  # 결정론 RNG
    result.dart
  domain/
    balance/  # BalanceConfig(+LaunchSpec·FlightControlSpec·WorldConfig·StageSpec), 공식, 페이싱 시뮬, 업그레이드
    sim/      # FlightSimulator(고정 dt·활공·부스터·급강하), FlightParams, landing, FixedStepper, AccuracyGauge, LaunchController
    world/    # ObjectKind, ChunkGenerator(100m 결정론)·WorldObject·ObjectField
    run/      # RunSession(한 판), ObjectInteractor(효과), RunStats(콤보·미션 기록), StarRules(★·★★·★★★)
    economy/  # Wallet, UpgradeService
    progress/ # PlayerProgress(세이브 모델)
    services/ # (P9) abstract: RemoteConfigService, AnalyticsService, AdService, IapService, SaveStore
  data/
    save/hive_save_store.dart
    fake/                   # Fake 구현 모음 (개발·테스트 기본)
    firebase/ ads/ iap/     # P9 에서 추가
  game/
    mozzi_game.dart         # FlameGame: 시뮬 tick → 컴포넌트 동기화
    components/             # MozziComponent, GroundComponent, ObjectComponent…
    viewport/               # 가로 고정 반응형 가상 화면 (높이 540, ADR-011)
    render/                 # 2.5D 코드 렌더링: 파츠 레이어, 셰이딩 7단계, 조명, 캐싱 (GDD §3 2.5D 아트 디렉션)
    camera/ parallax/ input/ effects/
shaders/                    # FragmentShader(.frag) — pubspec flutter.shaders 에 등록
  ui/
    <feature>/              # home, hud, result, upgrade, shop…
      <feature>_screen.dart
      <feature>_controller.dart
      widgets/
```
폴더는 실제 코드가 생길 때 만든다 (빈 폴더·빈 barrel 파일 금지).

## 4. 한 판의 데이터 흐름
```
입력(드래그/탭/홀드/스와이프)
  → game/input 이 도메인 명령(LaunchInput, FlightCommand)으로 변환
  → domain/run RunSession.step() = FlightSimulator.step(dt=1/60) + ObjectInteractor(오브젝트 효과) + RunStats + 골
      ← BalanceConfig, 업그레이드 레벨, 스테이지, 런 시드(청크 배치)
  → FlightState (위치·속도·연료·조작 상태) + RunStats (씨앗·콤보·적중·미션 기록) + 적중 목록(연출)
  → game 컴포넌트가 FlightState 를 그대로 렌더 / ui HUD 가 구독
  → 정지 시 RunResult → domain/economy 가 보상 계산 → PlayerProgress 갱신 → SaveStore 저장
```
- Flame `update(dt)`는 누적 시간을 고정 스텝으로 쪼개 `step()`을 호출한다 (가변 dt로 물리를 돌리지 않는다).
- 시뮬레이터는 Flame 좌표가 아니라 **미터 단위 월드 좌표**를 쓴다. 화면 변환은 game 레이어 책임.

## 5. 상태관리 (Riverpod)
- `flutter_riverpod` (코드 생성 없이). `Provider` / `NotifierProvider` / `AsyncNotifierProvider` 만 사용.
- 서비스 Provider는 `app/providers.dart`에서 flavor·`useFakeServices`에 따라 구현을 고른다.
- 게임 루프 내부(초당 60회) 상태는 Riverpod 에 넣지 않는다. HUD 가 필요한 값만 저빈도로 노출한다.

## 6. 설정·밸런스 흐름
```
모찌런처_밸런스시트.xlsx ──(tool/balance/export_balance.py)──▶ assets/config/balance_defaults.json
    ──(앱 시작)──▶ BalanceConfig.fromJson ──(P9: Remote Config 값으로 덮어쓰기)──▶ 앱 전체
```
- JSON 키 = Remote Config 키 (GDD §10). 키를 추가하면 엑셀 → 스크립트 → JSON 순서로 반영.
- verify 4단계가 JSON 과 엑셀의 불일치를 잡는다.

## 7. 외부 서비스
| 인터페이스 (domain/services) | Fake (data/fake) | 실제 (P9) |
|---|---|---|
| RemoteConfigService | 기본 JSON 그대로 | Firebase Remote Config |
| AnalyticsService | 콘솔 로그 + 메모리 기록 | Firebase Analytics |
| AdService | 즉시 보상 지급 / 스킵 | google_mobile_ads (테스트 ID) |
| IapService | 즉시 구매 성공 | in_app_purchase |
| SaveStore | 메모리 | Hive (P6) + Firestore 백업(v1.1) |
