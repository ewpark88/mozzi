# 개발계획표

> 기준 문서: `모찌 런처 게임 기획서 (GDD).md` (2026-09-26), `모찌런처_밸런스시트.xlsx`
> 진행 방법: `/phase-start P<N>` → 세부 계획 승인 → 구현 → `/phase-verify P<N>` → PR 머지 → 다음 Phase.
> 규칙: 앞 Phase 의 DoD 를 모두 충족해야 다음 Phase 를 시작한다. 계획 변경은 이 문서 수정 + ADR.

상태 표기: ⬜ 대기 · 🟨 진행 중 · ✅ 완료 · ⏸ 보류

## 요약 일정 (MVP ≈ 4~5주, GDD §11 “MVP 3~4주 + 출시 준비”)

| Phase | 이름 | GDD 참조 | 예상 | 버전 | 상태 |
|---|---|---|---|---|---|
| P0 | 하네스·스캐폴딩 | §10 | 1일 | 0.0.x | ✅ |
| P1 | 도메인 코어 (밸런스·경제·페이싱) | §5, 밸런스 시트 | 2일 | 0.1.0 | ⬜ |
| P2 | 비행 시뮬레이터 + 게임 월드 기반 | §2, §4 배치 규칙 | 3일 | 0.2.0 | ⬜ |
| P3 | 당기기 & 발사 (퍼펙트 릴리즈) | §2 당기기, §3 표정/사운드 | 2일 | 0.3.0 | ⬜ |
| P4 | 비행 조작 3종 | §2 비행 중 조작 | 3일 | 0.4.0 | ⬜ |
| P5 | 오브젝트·청크 생성·구역 1~3·콤보 | §2 콤보, §4 | 3일 | 0.5.0 | ⬜ |
| P6 | 메타 루프 (결과·업그레이드·저장) | §2 착지, §5 | 3일 | 0.6.0 | ⬜ |
| P7 | 온보딩·캐릭터 연출·사운드 | §3, §9 | 3일 | 0.7.0 | ⬜ |
| P8 | 외부 서비스 연동 (RC·분석·광고·IAP) | §7, §10 | 3일 | 0.8.0 | ⬜ |
| P9 | MVP 출시 준비 (소프트런칭) | §11 | 2일 | 0.9.0 | ⬜ |
| — | **MVP 게이트**: D1 ≥ 35%, 평균 세션 ≥ 5분, 보상형 ≥ 2회/DAU | §11 | | | |
| P10~P14 | v1.0 콘텐츠 | §4~§7 | +4주 | 1.0.0 | ⬜ |
| — | **v1.0 게이트**: D7 ≥ 12% | | | | |
| v1.1 | 햄스터 마을·데일리 챌린지·도감 | §6 | +3주 | 1.1.0 | ⬜ |
| v1.2 | 프레스티지·토너먼트·시즌패스·GIF 공유 | §6, §8 | +4주 | 1.2.0 | ⬜ |

---

## P0 하네스·스캐폴딩 ✅
**목표**: 코드가 규칙대로만 쌓이도록 구조·자동 검사·빌드 파이프라인을 먼저 고정한다.
- [x] Flutter 프로젝트 생성 (`com.repo.mozzi`, android/ios)
- [x] Android flavor dev/prod, 릴리즈 서명 설정(key.properties), `main_dev/main_prod`
- [x] 의존성: flame, flutter_riverpod, hive_ce(+flutter), very_good_analysis, mocktail
- [x] 문서: CLAUDE.md, ARCHITECTURE, CODING_RULES, BUILD_RELEASE, DEV_PLAN, PROGRESS, DECISIONS
- [x] 하네스: `tool/verify.{sh,ps1}`, `tool/check_architecture.dart`(+테스트), 밸런스 export/check 스크립트
- [x] Claude 훅: 보호 파일 수정 차단, .dart 자동 포맷 / 명령: `/phase-start`, `/phase-verify`
- [x] GitHub Actions: ci.yml, release.yml
- [ ] GitHub 원격 저장소 연결 후 CI green 확인 (사용자 원격 생성 후)

**DoD**: verify 통과 ✅ · dev 디버그 APK 빌드 ✅ · 아키텍처 위반 검출 확인 ✅ · CI green ⬜

---

## P1 도메인 코어 ⬜
**목표**: 밸런스 시트의 모든 공식을 순수 Dart 로 옮기고, 시트의 결과값과 테스트로 일치시킨다. 이후 모든 Phase 가 이 코어를 쓴다.

**작업**
- [ ] `core/random/seeded_rng.dart` — 시드 기반 결정론 RNG (xorshift 등, 플랫폼 무관 동일 결과)
- [ ] `domain/balance/balance_config.dart` — JSON(`balance_defaults.json`) ↔ 불변 모델, 누락/타입 오류 시 명확한 예외
- [ ] `domain/balance/upgrade_type.dart` — 5종 enum(launch, aero, boost, bounce, coin) + RC 키 매핑
- [ ] `domain/balance/formulas.dart`
  - 비용 `cost(Lv) = round(base × growth^Lv)`
  - 발사 속도 `v = phys_v0 + effect_launch × Lv`
  - 기대 거리 `d = (v²/g × (1 + 0.06·Lv_aero) + k × Lv_boost^1.3) × (1 + 0.04·Lv_bounce)`
  - 씨앗 `floor(d × coin_per_m × (1 + 0.1·Lv_coin))` (진행 시뮬: 23m → 11개로 검증)
- [ ] `domain/economy/wallet.dart` — 씨앗/별사탕 잔액, 음수 불가, 부족 시 실패 결과
- [ ] `domain/economy/upgrade_service.dart` — 레벨 조회·구매 가능 여부·구매 처리
- [ ] `domain/progress/player_progress.dart` — 세이브 모델(업그레이드 레벨, 지갑, 최고 기록, 판 수, 온보딩 단계) + JSON 직렬화 + 스키마 버전
- [ ] `domain/balance/pacing_simulator.dart` — 탐욕적 구매(씨앗 1개당 거리 증가 최대) 헤드리스 페이싱 시뮬, 광고 0%/30%/100% 시나리오
- [ ] 앱 시작 시 `balance_defaults.json` 로드 → `balanceConfigProvider` (app 레이어)

**테스트 (밸런스 시트 = 정답)**
- 업그레이드표: Lv0/1/10/20/40 비용 5종 (예: 고무줄 Lv10 = 40, 볼주머니 Lv20 = 11,403)
- 전 항목 동일 Lv 거리: Lv0 22.96m, Lv10 871.59m, Lv40 15,860.2m (±0.01)
- 페이싱: 구역 도달 판수 광고X 13/20/29/45/113, 광고100% 9/13/17/26/60 (±1판; 차이가 나면 원인 분석 후 ADR)
- 지갑·구매·세이브 JSON 왕복

**DoD**: 위 테스트 전부 통과 · domain 에 flutter/flame import 0 · 공개 API 문서 주석
**리스크**: 시트의 반올림/탐욕 기준이 명시돼 있지 않음 → 시트 결과와 다르면 차이를 표로 보고하고 사용자 결정.

---

## P2 비행 시뮬레이터 + 게임 월드 기반 ⬜
**목표**: 발사 입력(각도·속도)을 받아 날아가서 착지·미끄러짐·정지까지 가는 결정론 시뮬레이터와, 이를 화면에 보여주는 최소 Flame 게임.

**선결 결정 (Phase 시작 시 사용자 확인)**
- 화면 방향: **가로 고정 권장**(레퍼런스 Burrito Bison/Learn to Fly, 수평 거리감) vs 세로
- 시간·거리 스케일: 공식상 Lv0 비행은 23m(실시간 약 2초)인데 GDD 1판은 평균 40초 → **표시 거리(m)와 시뮬 단위의 분리/시간 배율** 방식을 ADR 로 결정

**작업**
- [ ] `domain/sim/flight_state.dart`, `launch_input.dart`, `flight_phase.dart`(ready/flying/sliding/stopped)
- [ ] `domain/sim/flight_simulator.dart` — 고정 dt=1/60, 중력·공기저항(aero 레벨로 감소)·지면 충돌·반발(bounce 레벨)·마찰 미끄러짐·정지 판정
- [ ] 보정: 기준 발사(45°, 최대 힘, 조작 없음)의 시뮬 거리 ≈ P1 공식 거리 (Lv 조합 10가지, ±5%)
- [ ] `game/mozzi_game.dart` — FixedStepper 로 시뮬 구동, 상태 → 컴포넌트 동기화
- [ ] `game/components/` — 모찌(플레이스홀더 원+볼), 지면, 거리 표지
- [ ] `game/camera` — 모찌 추적 + 속도에 따른 줌 아웃
- [ ] `game/parallax` — 원경/중경/근경 3레이어 (단색 플레이스홀더)
- [ ] 디버그 오버레이(dev 전용): 속도·고도·거리·fps

**DoD**: 시뮬 결정론 테스트(같은 입력 2회 = 동일 궤적) · 공식 보정 테스트 · 실기기에서 발사→정지 60fps
**리스크**: 보정 실패 시 공식 쪽(밸런스)과 시뮬 쪽 중 무엇을 맞출지 → 페이싱은 공식 기준 유지, 시뮬 파라미터로 맞춘다.

---

## P3 당기기 & 발사 ⬜
**목표**: “첫 1초부터 손맛” — 드래그로 늘어나는 모찌와 퍼펙트 릴리즈.
- [ ] `domain/sim/launch_rules.dart` — 드래그 벡터 → 각도(범위 제한)·힘(0~1), 힘 → 초기 속도(고무줄 Lv)
- [ ] 힘 게이지 최적 구간 좌우 이동(시간 함수, 결정론), 구간 내 릴리즈 = 퍼펙트(+15%, RC 값)
- [ ] `game/input/pull_input.dart` — 터치 → LaunchInput 변환 (시작점 기준 반대 방향 발사)
- [ ] 모찌 늘어남(stretch 0~1) 스케일 변형, 궤적 미리보기 점선(짧게)
- [ ] 힘 게이지 UI(HUD), 퍼펙트 이펙트, 햅틱(HapticFeedback)
- [ ] 고무 늘어나는 소리 음높이(오디오 패키지 결정은 P7 — 여기서는 훅 포인트만)
**DoD**: 입력→각도/힘 변환 테스트, 퍼펙트 판정 경계 테스트 · 실기기 손맛 확인(사용자)

---

## P4 비행 조작 3종 ⬜
| 조작 | 입력 | 도메인 규칙 |
|---|---|---|
| 부스터 | 탭 | 연료 소모 가속, 연료량 = 부스터 Lv 기반 (공식의 boost 거리와 보정) |
| 볼 부풀리기 | 홀드 | 낙하 속도 제한(활공) + 수평 감속 |
| 급강하 | 아래 스와이프 | 급하강, 바운스 오브젝트 적중 시 큰 튕김, 타이밍 퍼펙트 보너스 |
- [ ] `domain/sim/flight_command.dart` + 시뮬 반영, 조작별 해금 플래그(온보딩: 부풀리기·급강하는 공원 도달 후)
- [ ] `game/input/flight_input.dart` — 탭/홀드/스와이프 제스처 분리(오인식 방지 임계값)
- [ ] HUD: 연료 게이지, 조작 버튼 힌트
**DoD**: 조작별 시뮬 단위 테스트(연료 소진, 활공 낙하속도 상한, 급강하 바운스) · 제스처 분리 테스트

---

## P5 오브젝트·청크 생성·구역 1~3·콤보 ⬜
- [ ] `domain/world/zone_def.dart` — 6구역 정의(거리 경계는 JSON), MVP 는 1~3구역 콘텐츠
- [ ] `domain/world/chunk_generator.dart` — 100m 청크, (런 시드, 청크 번호) → 배치, 장애물 비율 구역별 0→30%
- [ ] 오브젝트: 씨앗, 트램폴린, 빨랫줄(뒷마당) / 풍선, 분수, 나뭇가지, 비둘기(공원) / 실외기 상승기류, 빨간 우산, 전선, 까마귀, 광고판(도시)
- [ ] 충돌 판정(원 vs 원/AABB)과 효과 — 장애물은 감속만, 비행 종료 없음
- [ ] 콤보: 비착지 연속 적중마다 씨앗 배율 ×1.1, 착지 시 초기화
- [ ] 청크 컴포넌트 생성/제거(화면 밖), 다음 구역 원경 100m 전 미리보기
**DoD**: 같은 시드=같은 배치 테스트 · 장애물 비율 통계 테스트 · 콤보 테스트 · 실기기 60fps(청크 풀링)

---

## P6 메타 루프 ⬜
- [ ] 착지 → 미끄러짐 → 정지 → `RunResult`(거리, 최고기록 대비 +N m, 씨앗, 콤보 최대)
- [ ] 결과 화면: 거리·신기록 연출·획득 씨앗·“2배 받기” 버튼(AdService Fake)
- [ ] 고스트 깃발: 직전 최고 기록 지점 표시
- [ ] 업그레이드 화면: 5종 카드(레벨·비용·다음 효과), 구매 가능 강조
- [ ] 홈 화면 → 발사 → 결과 → 업그레이드 → 재도전 흐름(라우팅)
- [ ] `data/save/hive_save_store.dart` — PlayerProgress 저장/복원, 스키마 버전 마이그레이션 자리
**DoD**: 한 판 루프 위젯 테스트 · 저장→재시작→복원 테스트 · 실기기 10판 연속 플레이(사용자)

---

## P7 온보딩·캐릭터 연출·사운드 ⬜
- [ ] 온보딩 스크립트(GDD §9): 1판 당기기만+트램폴린 자동배치 / 2판 부스터+첫 업그레이드 무료 / 3판 황금씨앗 확정+광고 2배 제안 / 5판 퍼펙트 릴리즈 / 공원 도달 시 부풀리기·급강하 해금
- [ ] 표정 9종 상태 머신(domain 에서 표정 상태 결정 → game 이 표시). 아트는 플레이스홀더 스프라이트, Rive 도입 여부는 아트 준비 시 ADR
- [ ] 사운드: 고무 늘어남(음높이), 발사 휘익+찍, 씨앗 뽁(콤보 음계 상승), 착지 뿅 — 오디오 패키지 ADR
- [ ] 문자열 `ui/strings.dart` 정리
**DoD**: 온보딩 단계 전이 테스트(1~5판 시나리오) · 표정 전이 테스트

---

## P8 외부 서비스 연동 ⬜ (사전: Firebase 프로젝트·AdMob 계정 필요)
- [ ] Firebase 프로젝트 dev/prod 분리, `google-services.json`은 flavor 별 배치(git 제외, CI Secrets)
- [ ] Remote Config: 기본값 = balance_defaults.json, 가져오기 실패 시 기본값, GDD §10 키 전체
- [ ] Analytics 이벤트 명세(`docs/ANALYTICS.md` 작성): run_start, run_end(거리·씨앗·퍼펙트), upgrade_buy, zone_reach, ad_offer/ad_watch, iap_purchase, tutorial_step
- [ ] 광고: 보상형(결과 2배), 전면(첫 5판 제외, 3~4판마다 — RC `ad_interstitial_*`), 테스트 ID
- [ ] IAP: 광고 제거(₩5,900, 전면 제거 + 별사탕 300), 구매 복원
- [ ] Fake ↔ 실제 구현 전환은 `config/*.json`만으로
**DoD**: 각 서비스 계약 테스트(Fake/실제 동일 테스트) · dev 빌드 실기기에서 테스트 광고·테스트 결제 확인

---

## P9 MVP 출시 준비 ⬜
- [ ] 앱 아이콘·스플래시(flutter_launcher_icons / native_splash — ADR)
- [ ] 업로드 키 생성, Play Console 앱 등록, 데이터 보안 양식, 개인정보처리방침
- [ ] 성능: 저사양 기기 60fps, 메모리 누수 점검, 앱 크기 확인
- [ ] 크래시 수집(Firebase Crashlytics — ADR)
- [ ] release.yml 에 Play internal 트랙 자동 업로드 추가
- [ ] 소프트런칭 KPI 대시보드(D1, 세션 길이, 보상형 시청/DAU)
**DoD**: 태그 → internal 트랙 배포 성공 · BUILD_RELEASE §8 체크리스트 전부 체크

---

## v1.0 (P10~P14) — MVP 게이트 통과 후 세부 계획 작성
| Phase | 내용 | GDD |
|---|---|---|
| P10 | 구역 4~6 (구름·우주·달), 저중력·블랙홀·엔딩 연출 | §4 |
| P11 | 캐릭터 라인업(병아리·카피바라…), 스킨 슬롯 4개 | §3 |
| P12 | 장착 아이템 5종 + 조각 레벨업 | §6 |
| P13 | 랜덤 이벤트(황금 씨앗·보물상자·UFO·친구 구조) | §4 |
| P14 | 미션·업적·7일 출석, 상점·별사탕·뽑기, 스타터팩(15분) | §6, §7 |

## v1.1 / v1.2 — v1.0 게이트 통과 후 세부 계획 작성
- v1.1: 햄스터 마을(Idle), 데일리 챌린지(고정 시드), 도감, Firestore 백업, Play Games 리더보드
- v1.2: 프레스티지 스킬 트리·화성, 주간 토너먼트, 시즌패스, 리플레이 GIF 공유, 씨앗 러시

## 미해결 질문 (해당 Phase 시작 시 확정)
| # | 질문 | 결정 시점 |
|---|---|---|
| Q1 | 화면 방향 가로/세로 | P2 |
| Q2 | 시뮬 시간·거리 스케일 (Lv0 23m vs 1판 40초) | P2 |
| Q3 | 캐릭터 아트 소스(외주/생성)와 Rive 도입 시점 | P7 |
| Q4 | 오디오 패키지(flame_audio 등) | P7 |
| Q5 | Firebase/AdMob 계정 준비 일정 | P8 이전 |
