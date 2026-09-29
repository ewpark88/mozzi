# 작업 인수인계 (세션 재시작용)

> 마지막 갱신: 2026-09-29 · P8 완료 직후. **새 세션은 이 문서 → CLAUDE.md → DEV_PLAN 의 다음 Phase 순서로 읽고 시작한다.**

## 1. 지금 상태 한눈에

| 항목 | 상태 |
|---|---|
| 완료 Phase | P0 하네스 · P1 도메인 코어 · P2 비행 시뮬 · P3 당기기·게이지 · P4 비행 조작 3종 · P5 오브젝트·스테이지·★★★ · P6 메타 루프·월드맵·보스 · P7 2.5D 코드 렌더링 · P8 온보딩·표정·사운드 |
| 다음 Phase | **P9 외부 서비스 연동** — Firebase 프로젝트·AdMob 계정이 필요하므로 사용자 준비 먼저 확인 |
| 버전 | `0.8.0+9` (pubspec) |
| 브랜치 | `main` = `f6106c8` (P5 머지), CI green. Phase 브랜치 `feat/P{N}-*` 는 모두 main 에 fast-forward 머지됨 |
| 원격 | https://github.com/ewpark88/mozzi (gh CLI 없음 → PR 없이 로컬 ff 머지 후 push, CI 는 GitHub API 로 확인) |
| 품질 | `bash tool/verify.sh` 통과, 테스트 385개, lib 62개 파일 5,545줄, 파일당 300줄 이하 |
| 기준 문서 | GDD·시트·샘플 HTML 모두 스냅샷과 일치 (`spec_sync.py` 변경 없음) |
| 실기기 확인 | **아직 안 함** (연결된 Android 기기·에뮬레이터 없음). dev APK: `build/app/outputs/flutter-apk/app-dev-debug.apk` |

## 2. 사용자와 합의된 작업 방식 (반드시 지킬 것)

1. **모든 개발 근거 = GDD(`모찌 런처 게임 기획서 (GDD).md`) + 밸런스 시트(`모찌런처_밸런스시트.xlsx`)**, 손맛·렌더링 시각 기준 = `모찌 런처 2.5D.html`(사용자 샘플). 수치는 GDD/시트 우선, 샘플과 다르면 알린다.
2. **GDD 는 계속 갱신된다** → 매 프롬프트 훅이 `tool/spec/spec_sync.py --hook` 으로 변경을 알려준다. 알림이 오면 먼저 `/spec-sync` (diff 확인 → 시트·DEV_PLAN·코드 반영 → `--mark`).
3. **GDD 파일은 절대 직접 수정하지 않는다.** 사용자가 다른 원본에서 파일을 통째로 덮어써서 직접 수정이 세 번 모두 되돌아갔다. 오류·누락은 `docs/SPEC_CHANGELOG.md` “GDD 수정 제안”(현재 없음 — G1~G26 해결)에 적고 알린다.
4. **밸런스 시트는 직접 고친다** (GDD 수치 반영·오류 정정). 반드시 `tool/balance/xlsx_edit.ps1`(Excel COM)로 — openpyxl 로 저장하면 수식 캐시가 사라진다. 고치면 `export_balance.py` → verify → SPEC_CHANGELOG 기록.
5. **Phase 완료 시 Claude 가 커밋 → 브랜치 push → main ff 머지 → push → CI 확인**까지 한다 (사용자 지시). 태그·스토어 업로드는 요청 시에만.
6. 사용자는 “진행해”로 다음 단계를 지시한다. 미결 기획 사항은 GDD 우선 원칙으로 정하고 ADR·시트 값으로 되돌릴 수 있게 한 뒤 보고한다.
7. Phase 마다: `/phase-start P<N>` → 구현 → 화면 캡처로 시각 확인(아래 §6) → `/phase-verify P<N>` → 문서(DEV_PLAN·PROGRESS·DECISIONS·SPEC_CHANGELOG·CLAUDE 현재 Phase) → 버전 MINOR+BUILD 올림 → 머지.

## 3. 코드 지도 (lib/)

의존 방향 `ui → game → domain ← data`, `app` 조립, `domain`·`core` 순수 Dart (검사: `tool/check_architecture.dart`).

| 경로 | 내용 |
|---|---|
| `core/` | `PcmSynth`(효과음 PCM 합성), `SeededRng`(xorshift32), `roundHalfUp`(Excel ROUND), `JsonReader`(타입 검증·경로 오류), `Result`, `AppEnv`(flavor) |
| `domain/balance/` | `BalanceConfig`(JSON 전체) ← `LaunchSpec`(게이지·당기기), `FlightControlSpec`(조작 3종), `WorldConfig`(오브젝트·배치·스테이지·보스), `StageSpec`/`MissionSpec`; `BalanceFormulas`(GDD §5 공식), `PacingSimulator`(시트 「진행 시뮬」 재현), `UpgradeType`/`UpgradeLevels` |
| `domain/sim/` | `FlightSimulator`(고정 dt 1/60, 해석적 적분, 활공·부스터·급강하, `redirect`·`forceGlide`), `FlightParams`(레벨→물리), `FlightControls`, `landing.dart`(튐→미끄러짐), `FixedStepper`, `AccuracyGauge`, `LaunchController` |
| `domain/world/` | `ObjectKind`(12종)·`ObjectCategory`, `ChunkGenerator`(100m 결정론)·`WorldObject`·`ObjectField`, `CourseTweak`(2-5 코스 조정) |
| `domain/run/` | `RunSession`(한 판 = 시뮬+오브젝트+기록+골+보스, 게임·테스트 공용), `ObjectInteractor`(효과), `RunStats`(콤보·미션 기록), `StarRules`(★·★★·★★★ 15개 미션 타입), `RunResult`(판 결과·씨앗 합산), `boss/`(`BossRule`·`CatChase`·`PigeonRace`·`CrowThief`·`BossEase`) |
| `domain/economy/`, `progress/`, `services/` | `Wallet`, `UpgradeService`, `PlayerProgress`(세이브 v2: `StageRecord`·해금), `RunRecorder`(판 반영·광고 보너스·보스 완화), `StageUnlocks`(월드맵·해금), `Unlock`(보스 보상 키); 인터페이스 `SaveStore`·`AdService` |
| `data/` | `save/HiveSaveStore`, `fake/MemorySaveStore`·`FakeAdService` |
| `game/` | `MozziGame`(Flame, RunSession 구동), `RunSetup`(판 시작 조건), `RunHudBus`(HUD·보스 HUD·판 결과 알림), `PlayInput`(발사 전 당기기/비행 중 제스처, `ControlUnlocks`), `FlightGestureRecognizer`, `CameraRig`, `VirtualViewport`(가상 높이 540), components(모찌·지면·거리표지·게이지·오브젝트 레이어·골 깃발·고스트 깃발·보스·5레이어 패럴랙스), `RunFx`·`ParticleEffects`(가산 글로우·먼지 퍼프), `render/`(`shade`·`ShadedShapes`·`ObjectPainter`, `mochi/` 2.5D 몸·얼굴 9종·변형·Picture 캐시), `palette.dart`(모든 색·월드 조명 한 곳), `RunHudInfo` |
| `ui/` | `world_map/`(월드맵), `result/`(결과 화면·버튼), `upgrade/`(업그레이드) |
| `ui/play/` | `PlayScreen`(Listener 입력, HUD 조립, `PlayHooks` 로 진행 연결, 결과 화면), `BossHud`, `PlayHud`(거리·안내·판정), `StageHud`, `FlightHud`(연료·조작 안내), `GradePopup`, `DevPanel`(dev: 스테이지·레벨 선택), `hudScaleOf`; `ui/strings.dart` |
| `app/` | `bootstrap`(가로 고정·몰입, 밸런스 JSON·Hive 세이브 로드), `providers`(Riverpod·서비스), `progress_controller`(진행 상태 Notifier, 저장), `routes`(월드맵 → 플레이 → 업그레이드), `app.dart`(홈 = 월드맵) |

## 4. 핵심 결정 (자세한 내용 docs/DECISIONS.md)

| ADR | 요지 |
|---|---|
| 001 | forge2d 대신 자체 결정론 물리 |
| 008 | 페이싱 규칙 역산(씨앗 1개당 판당 씨앗 증가 최대, 최선 부족 시 중단, 광고 30% = ×1.3) — 시트 전 셀 재현 |
| 011 | 가로 고정 + 전 화면 비율 반응형 (가상 높이 540, HUD 짧은 변 배율 0.8~1.6) |
| 012 | 미터 시뮬(조작 없는 45° = 공식 d, 공기역학=유효중력, 바운스=반발계수 등비급수) + 샘플 체감 배율(`sim_time_scale`≈1.648, `cam_base_px_per_m`≈52.6) |
| 013 | 게이지: 구간 바깥=최소·안쪽=최대 보간(GREAT 1.03→1.13), 힘×배율 = **거리** 배율(`gauge_speed_exponent` 0.5) |
| 014 | 조작: 탭=부스터·홀드=부풀리기·아래 스와이프=급강하, 부스터 연료 = 공식 부스터 거리 예산(공중에서 다 쓰면 공식 일치) |
| 015 | RunSession 구조, 청크 거리 배율, 콤보는 먹은 씨앗에만, 미션 = 타입 문자열 + 파라미터 |
| 016 | RC 키·스테이지 데이터 형식 = GDD §10·§4 이름 |
| 019 | 효과음 = PCM 합성 + flutter_soloud, 폰트 Jua·Gowun Dodum, 온보딩 = 판 수 기준(무료 업그레이드 = 부스터 Lv1) |
| 018 | 2.5D = Canvas 그라데이션 + Picture 캐시(셰이더 없음), 저사양 = 털·안개 끔 |
| 017 | 판 씨앗 = 거리 씨앗 + 먹은 씨앗×볼주머니, 보스 시간은 실제 초·수치는 시트, 보스 패배 시 즉시 종료, 세이브 v2 모든 flavor Hive |

## 5. 밸런스 시트 구조 (시트 → `assets/config/balance_defaults.json` + `test/fixtures/balance_sheet_expected.json`)

| 시트 | 내용 | 코드 |
|---|---|---|
| 설정 | 업그레이드 5종, 물리·보상, 구역 6개, 체감(28~33행: 샘플 v/g·시간배율·카메라 배율·모찌 반지름), 게이지·당기기(34~52행), 비행 조작(54~68행, 키 = GDD §10) | `BalanceConfig`, `LaunchSpec`, `FlightControlSpec` |
| 업그레이드표·진행 시뮬 | 원본 수식/시뮬 결과 → fixture (테스트 정답) | `balance_formulas_test`, `pacing_simulator_test` |
| 스테이지 | (JSON `stage_table.stages[]`, GDD §4 형식) 보스 값 42~51행, 1-1~5-5 목표·보스·도달 판수(E~H 시뮬 생성)·★★★ 미션 JSON(I)·설명(J), 6-1 달(30행), ★★ 1.3(32행), 월드 해금 별(35~39행), 보스 값(42~45행) | `WorldConfig.stages`, `BossSpec` |
| 오브젝트 | 12종 효과(반지름·값1~3), 배치 설정(20~27행), 월드 1~3 비중·장애물 비율(31~34행) | `ObjectSpec`, `SpawnSpec`, `WorldSpawn` |

셀 위치 상수: `tool/balance/sheet_layout.py` (바꾸면 여기만).

## 6. 도구·명령과 환경 주의점

```bash
bash tool/verify.sh                                  # 품질 게이트 (format/analyze/architecture/balance/test + spec 정보)
PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py [--diff|--mark]   # 기준 문서 변경 추적
PYTHONIOENCODING=utf-8 python tool/balance/export_balance.py [--check] # 시트 → JSON·fixture
PYTHONIOENCODING=utf-8 python tool/balance/pacing_sim.py --compare     # 진행 시뮬·스테이지 판수 재현 확인 (--edits out.json → 시트 반영용)
powershell -ExecutionPolicy Bypass -File tool/balance/xlsx_edit.ps1 -EditsJson <json>  # [{sheet,cell,value}] Excel COM 편집
flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

- **화면 캡처로 시각 확인**(기기 없음): `test/zz_tmp_screenshot_test.dart` 를 임시로 만들어 `RepaintBoundary.toImage()` → PNG(`$TEMP/p2shots`) → Read 로 확인 → 파일 삭제. 글자는 테스트 폰트(Ahem)라 네모로 보인다. 이 방법으로 HUD 가림·연료 막대 미표시 등 결함 5건을 찾았다.
- **Bash heredoc 여러 개 + 따옴표**가 섞이면 파싱 오류가 난다 → 긴 수정은 scratchpad 에 `.py` 파일로 써서 실행.
- **PowerShell 5.1** 은 BOM 없는 스크립트를 ANSI 로 읽는다 → ps1 안에 한글 리터럴(파일명 등) 금지.
- **Excel 2007 COM**: 숫자 대입은 `InvokeMember('Value2')`(어댑터 타입 캐시 문제), `=` 로 시작하면 `Formula` 로 넣는다. 설명 글을 `=` 로 시작하지 말 것.
- 훅: 보호 파일 수정 차단(서명 키·생성 JSON·fixture), .dart 자동 포맷, 프롬프트마다 spec 변경 알림 (`.claude/settings.json`).
- 테스트 부동소수 경계(0.18초, 0.45 등)는 여유값 또는 `+1e-9` 를 둔다.

## 7. 열린 항목

| 항목 | 상태 |
|---|---|
| 실기기 확인 | P2~P5 전부 “사용자 확인 필요” — 60fps, 당김·게이지 손맛, 조작 임계값, 오브젝트 체감 |
| GDD 수정 제안 | 없음 (G1~G26 해결) |
| 보스 체감 | 고양이 6초·대장 16초·까마귀 초당 1.9% 는 시뮬 설계값 → 실기기 플레이로 시트 조정 |
| 온보딩 | 조작 해금(`ControlUnlocks`, 1-5 보스 클리어 보상), 1판 트램폴린 자동 배치 등은 P8 |
| 2.5D 렌더링 | P7 완료. 보스·월드맵·고스트 깃발은 아직 단색 — 아트 품질 확인 후 필요하면 개선 |

## 7-1. P9 시작 시 바로 할 일

1. **사용자 준비물 확인**: Firebase 프로젝트(dev/prod), AdMob 계정·앱 ID, Play Console 인앱 상품. 없으면 P9 착수 전 알린다.
2. `PYTHONIOENCODING=utf-8 python tool/spec/spec_sync.py` 로 GDD 변경 확인.
3. `git switch -c feat/P9-services` (main 에서). 서비스 인터페이스는 `domain/services/`(SaveStore·AdService·SoundService 있음), 가짜는 `data/fake/`.
