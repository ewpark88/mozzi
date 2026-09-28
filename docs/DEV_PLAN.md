# 개발계획표

> 기준 문서: `모찌 런처 게임 기획서 (GDD).md` (2026-09-26), `모찌런처_밸런스시트.xlsx`
> 진행 방법: `/phase-start P<N>` → 세부 계획 승인 → 구현 → `/phase-verify P<N>` → PR 머지 → 다음 Phase.
> 규칙: 앞 Phase 의 DoD 를 모두 충족해야 다음 Phase 를 시작한다. 계획 변경은 이 문서 수정 + ADR.

상태 표기: ⬜ 대기 · 🟨 진행 중 · ✅ 완료 · ⏸ 보류

## 요약 일정 (MVP ≈ 5~6주, GDD §11 “MVP 3~4주” + 2.5D 코드 렌더링 + 출시 준비)

| Phase | 이름 | GDD 참조 | 예상 | 버전 | 상태 |
|---|---|---|---|---|---|
| P0 | 하네스·스캐폴딩 | §10 | 1일 | 0.0.x | ✅ |
| P1 | 도메인 코어 (밸런스·경제·페이싱) | §5, 밸런스 시트 | 2일 | 0.1.0 | ✅ |
| P2 | 비행 시뮬레이터 + 게임 월드 기반 | §2, §4 배치 규칙 | 3일 | 0.2.0 | ✅ |
| P3 | 당기기 & 정확도 게이지 | §2 당기기와 정확도 게이지 | 3일 | 0.3.0 | ✅ |
| P4 | 비행 조작 3종 | §2 비행 중 조작 | 3일 | 0.4.0 | ⬜ |
| P5 | 오브젝트·청크·스테이지 골·월드 1~3 | §2 콤보, §4 | 4일 | 0.5.0 | ⬜ |
| P6 | 메타 루프·월드맵 (결과·클리어·해금·보스·저장) | §2 착지, §4, §5 | 4일 | 0.6.0 | ⬜ |
| P7 | 2.5D 코드 렌더링 (캐릭터·오브젝트·배경) | §1 아트, §3 2.5D 아트 디렉션 | 4일 | 0.7.0 | ⬜ |
| P8 | 온보딩·표정·사운드 합성 | §3, §9 | 3일 | 0.8.0 | ⬜ |
| P9 | 외부 서비스 연동 (RC·분석·광고·IAP) | §7, §10 | 3일 | 0.9.0 | ⬜ |
| P10 | MVP 출시 준비 (소프트런칭) | §11 | 2일 | 0.10.0 | ⬜ |
| — | **MVP 게이트**: D1 ≥ 35%, 평균 세션 ≥ 5분, 보상형 ≥ 2회/DAU | §11 | | | |
| P11~P15 | v1.0 콘텐츠 | §4~§7 | +4주 | 1.0.0 | ⬜ |
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
- [x] GitHub 원격 저장소 연결(ewpark88/mozzi) 후 CI green 확인

**DoD**: verify 통과 ✅ · dev 디버그 APK 빌드 ✅ · 아키텍처 위반 검출 확인 ✅ · CI green ✅

---

## P1 도메인 코어 ✅
**목표**: 밸런스 시트의 모든 공식을 순수 Dart 로 옮기고, 시트의 결과값과 테스트로 일치시킨다. 이후 모든 Phase 가 이 코어를 쓴다.

**작업**
- [x] `core/random/seeded_rng.dart` — xorshift32 결정론 RNG / `core/math/round_half_up.dart` — Excel ROUND 동일 반올림
- [x] `core/json/json_reader.dart` — 타입 검증 JSON 리더(오류 경로 표시) / `core/result.dart` — Ok/Err
- [x] `domain/balance/balance_config.dart` — JSON ↔ 불변 모델(UpgradeSpec, ZoneSpec), 누락/타입 오류 시 `JsonFormatError`
- [x] `domain/balance/upgrade_type.dart`, `upgrade_levels.dart` — 5종 enum + RC 키, 불변 레벨 맵
- [x] `domain/balance/balance_formulas.dart` — 비용 `ROUND(base × growth^Lv)`, 발사 속도, 공기역학·부스터·바운스·볼주머니, 기대 거리, 씨앗 `ROUND(d × coin_per_m × 볼주머니 × 광고)`
- [x] `domain/economy/wallet.dart` — 씨앗/별사탕, 음수 불가, 부족 시 `Err`
- [x] `domain/economy/upgrade_service.dart` — 견적·구매
- [x] `domain/progress/player_progress.dart` — 세이브 모델 + JSON + 스키마 버전(1), 새 버전 세이브 거부
- [x] `domain/balance/pacing_simulator.dart` — ADR-008 규칙, 광고 ×1 / ×1.3 / ×2, 구역 도달 판수
- [x] `tool/balance/pacing_sim.py` — 시트 「진행 시뮬」 생성기(300판 전 셀 재현), `xlsx_edit.ps1` — Excel COM 편집기
- [x] `export_balance.py` 확장 — 「업그레이드표」·「진행 시뮬」 → `test/fixtures/balance_sheet_expected.json` + `--check`
- [x] 앱 시작 시 `balance_defaults.json` 로드 → `balanceConfigProvider`, `balanceFormulasProvider`, `upgradeServiceProvider`

**테스트 (밸런스 시트 = 정답)** — 136개 통과
- 업그레이드표 Lv0~80 전 행: 비용 5종 정확히 일치, 속도·배율·부스터·거리 ±1e-6
- 페이싱: 300판 × 광고X(거리·씨앗·레벨) / 광고30%(거리) / 광고100%(거리·씨앗) **완전 일치**, 구역 도달 판수 13/20/29/45/113 · 11/16/23/36/88 · 9/13/17/26/60
- 변이 검증: 구매 기준을 “거리 증가”로 바꾸면 291판 불일치로 실패함을 확인 (테스트가 실제로 규칙을 지킴)
- 지갑·구매·세이브 JSON 왕복, 설정 오류 경로, RNG 고정 수열

**DoD**: 테스트 전부 통과 ✅ · domain 에 flutter/flame import 0 (architecture OK) ✅ · 공개 API 문서 주석 ✅
**해결된 리스크**: 시트에 없던 반올림·탐욕 기준을 역산해 ADR-008 과 시트 설명(A2)에 명시함 (SPEC_CHANGELOG).

---

## P2 비행 시뮬레이터 + 게임 월드 기반 ✅
**목표**: 발사 입력(각도·속도)을 받아 날아가서 착지·미끄러짐·정지까지 가는 결정론 시뮬레이터와, 이를 화면에 보여주는 최소 Flame 게임.

**결정**: Q1 가로 고정 + 전 화면 비율 반응형(ADR-011) · Q2 미터 시뮬(공식 일치) + 샘플 체감 배율(ADR-012)

**작업**
- [x] `domain/sim/flight_params.dart` — 레벨 → 발사 속도·유효 중력(공기역학)·반발 계수(바운스)
- [x] `domain/sim/flight_state.dart`, `flight_simulator.dart` — 고정 dt 1/60, 해석적 적분 + 정확한 착지 시각, 튐 → 미끄러짐 → 정지
- [x] `domain/sim/fixed_stepper.dart` — 실제 시간 × `sim_time_scale` → 고정 스텝, 긴 멈춤 상한
- [x] 시트 「설정」 체감 값 `sim_time_scale`·`cam_base_px_per_m` (수식), BalanceConfig 반영
- [x] `game/mozzi_game.dart` — 고정 스텝 구동, 상태 → 컴포넌트 동기화, HUD 알림 0.1초 간격
- [x] `game/viewport/virtual_viewport.dart` — 가상 높이 540, 너비 가변 / `game/camera/camera_rig.dart` — 고도·속도 줌아웃, 부드러운 추적
- [x] `game/components/` — 모찌 플레이스홀더(GDD 팔레트, 착지 찌그러짐 스프링), 지면, 거리 표지(줌별 간격), 5레이어 패럴랙스(하늘·원경·중경·근경 + 전경 풀잎)
- [x] `ui/play/` — 플레이 화면(탭 발사·재도전), 반응형 HUD 배율, dev 패널(레벨 선택·속도·고도·공식 거리)
- [x] 가로 고정: SystemChrome + AndroidManifest `sensorLandscape` + iOS Info.plist

**테스트**: 공식 보정 125조합(±0.1%) · Lv0 22.96m · 각도 sin2θ · 속도 배율 제곱 · 결정론 · 30/60fps 동일 · 가상 뷰포트 5비율 · 카메라 줌 · 6개 화면 크기 레이아웃 · 탭→비행→정지 기록 = 공식 거리

**DoD**: 결정론 ✅ · 공식 보정 ✅ · 화면 캡처로 16:9·21:9·4:3·작은 폰 배치 확인 ✅ · **실기기 60fps 확인 — 사용자 확인 필요** (연결된 기기·에뮬레이터 없음)

---

## P3 당기기 & 정확도 게이지 ✅ (GDD §2 당기기와 정확도 게이지)
**목표**: “첫 1초부터 손맛” — 드래그로 늘어나는 모찌와, 힘(0~110%) × 정확도 게이지의 고위험 고보상 선택.

**결정**: G11·Q6 → ADR-013 (GREAT 1.03→1.13 구간 보간, 힘×배율 = 거리 배율, `gauge_speed_exponent` 로 조정 가능)

**작업**
- [x] 시트 「설정」 게이지·당기기 18개 값 → JSON → `LaunchSpec` (SPEC_CHANGELOG)
- [x] `domain/sim/accuracy_gauge.dart` — 바늘 왕복(실제 시간, 반사), 속도 `0.45 + 1.35p` / `1.8(1 + 9(p−1))`, 판정·배율 보간
- [x] `domain/sim/launch_controller.dart` — 누른 지점 기준 드래그(최대 150 가상 px), 힘 0~110%, 8% 미만 취소, 발사 각 0°~85°, 발사 결정
- [x] 입력: Listener(누르는 즉시 시작, 샘플 pointerdown 과 같음) → `MozziGame.pullStart/Move/End` (화면 px → 가상 px)
- [x] 모찌 늘어남(당긴 쪽으로 절반 따라감·방향으로 늘어남), 과충전 떨림
- [x] 게이지 (Flame): 색 구간 트랙·PERFECT 반짝임·바늘 구간색·힘 바(100% 표시)·범례, 과충전 빨간 막·테두리·떨림·“과충전!”
- [x] 판정 팝업(PERFECT!/GREAT/GOOD/아쉬워요 + 과충전 %), PERFECT 반짝이 파티클, 햅틱(발사·과충전 진입)
- [x] 고무 소리 음높이 훅: `LaunchController.stretch` (0~1) 노출 → P8 합성음에서 사용

**테스트**: 바늘 속도 표 5개 · 판정 구간/배율/대칭/연속 · 바늘 반사·결정론 · 당김 상한·각도·취소 · 110%+PERFECT = 거리 ×1.265, 100%+PERFECT = ×1.15 · 드래그 → 판정 팝업 → 발사 → 재도전 위젯 테스트 · 약한 당김 취소
**화면 확인**: 당기기·과충전·발사 캡처로 힘 바 미표시(셰이더 알파)·범례 넘침 발견 → 수정

**DoD**: 자동 테스트 ✅ · **실기기 손맛 확인 — 사용자 확인 필요**

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

## P5 오브젝트·청크·스테이지 골·월드 1~3 ⬜ (GDD §2 콤보, §4 스테이지 구조·월드 테마·배치 규칙)
- [ ] `domain/world/stage_def.dart` — 스테이지(월드·번호·목표 거리·보스) ← `balance_defaults.json` `stages` (시트 「스테이지」)
- [ ] `domain/world/world_def.dart` — 월드 6개 테마(거리 범위·신규 오브젝트·장애물·기믹), MVP 는 월드 1~3 콘텐츠
- [ ] `domain/world/chunk_generator.dart` — 100m 청크, (런 시드, 청크 번호) → 배치, 장애물 비율 월드별 0→30%
- [ ] 오브젝트: 씨앗, 트램폴린, 빨랫줄(뒷마당) / 풍선, 분수, 나뭇가지, 비둘기(공원) / 실외기 상승기류, 빨간 우산, 전선, 까마귀, 광고판(도시)
- [ ] 충돌 판정(원 vs 원/AABB)과 효과 — 장애물은 감속만, 비행 종료 없음
- [ ] 콤보: 비착지 연속 적중마다 씨앗 배율 ×1.1, 착지 시 초기화
- [ ] 스테이지 골: 목표 거리 골 깃발 통과 = 클리어(비행은 계속), 별 판정 ★ 도달 / ★★ 목표 × `stage_star2_ratio`(1.3) / ★★★ 스테이지 미션(미션 정의는 GDD 확정 후 — Q8)
- [ ] 청크 컴포넌트 생성/제거(화면 밖), 다음 월드 원경 100m 전 미리보기
**DoD**: 같은 시드=같은 배치 테스트 · 장애물 비율 통계 테스트 · 콤보 테스트 · 클리어/별 판정 경계 테스트 · 실기기 60fps(청크 풀링)

---

## P6 메타 루프·월드맵 ⬜ (GDD §2 콤보와 착지, §4 스테이지 구조, §5)
- [ ] 착지 → 미끄러짐 → 정지 → `RunResult`(거리, 최고기록 대비 +N m, 씨앗, 콤보 최대, 클리어 여부, 별)
- [ ] 클리어 연출: 골 테이프 끊김·폭죽·뿌듯 표정·보상 상자 / 실패해도 씨앗 지급
- [ ] 결과 화면: 거리·신기록·획득 씨앗·별·“2배 받기” 버튼(AdService Fake)
- [ ] 고스트 깃발: 해당 스테이지 직전 최고 기록 지점
- [ ] 월드맵: 스테이지를 길로 잇는 지도, 클리어 시 모찌가 다음 칸으로 통통 이동, 잠금 표시
- [ ] 월드 해금: 이전 월드 5번 클리어 + 별 개수(`world_unlock_stars` 8/20/32/45/60)
- [ ] 보스 스테이지(1-5·2-5·3-5): 규칙 변형 — 1-5 고양이 피해 달리기, 3-5 까마귀 대장, 2-5 규칙은 GDD 확정 필요(Q7). 클리어 보상 = 캐릭터/슬롯 해금
- [ ] 업그레이드 화면: 5종 카드(레벨·비용·다음 효과), 구매 가능 강조
- [ ] `PlayerProgress` 스키마 v2: 스테이지별 별·최고 기록·현재 위치 (v1 세이브 변환)
- [ ] `data/save/hive_save_store.dart` — 저장/복원
**DoD**: 한 판 루프 위젯 테스트 · 해금 조건 테스트 · v1→v2 세이브 변환 테스트 · 저장→재시작→복원 테스트 · 실기기 1-1~1-5 플레이(사용자)

---

## P7 2.5D 코드 렌더링 ⬜ (GDD §1 아트 스타일, §3 2.5D 아트 디렉션, §10 캐릭터 렌더링)
**목표**: 외부 에셋 없이 “손에 쥐고 싶은 말랑한 장난감” 질감의 모찌·오브젝트·배경을 코드로 그린다. 게임플레이는 2D 그대로.
**시각 기준**: `모찌 런처 2.5D.html` (drawMochi·lit·radial·softSpot·drawFace·spring) — 이 샘플 이상의 품질을 Flame 으로 재현
- [ ] `game/render/parts/` — 파츠 레이어(몸통, 볼, 귀, 발, 눈, 입), 입력값 `stretch`·`stretchAngle`·`speed`·`squash`·`cheek`·`boost`·`expr`·`lightColor`
- [ ] 셰이딩 7단계: 접지 그림자 → 베이스 컬러 → 면 그라데이션(좌상단 45° 광원) → 앰비언트 오클루전 → 림라이트 → 스페큘러 → 털 질감(저사양 끔)
- [ ] `shaders/*.frag` FragmentShader (그라데이션·림라이트·스페큘러), 셰이더 미지원/저사양 시 Canvas 대체 경로
- [ ] 말랑 표현: 찌그러짐↔그림자 넓이, 하이라이트 늘어남, 볼 스프링 출렁임 (시각 전용 스프링 — 게임 판정에 영향 없음)
- [ ] 외곽선 3~4px 같은 계열 진한 색, GDD 팔레트·셰이딩 색은 `app/theme` 상수 한 곳
- [ ] 오브젝트(트램폴린·풍선·씨앗 등) 같은 셰이딩 규칙, 풍선 스페큘러 강 / 씨앗 광택 약
- [ ] 배경 5레이어 대기 원근(멀수록 흐리고 채도↓ 밝게), 전경 풀잎, 구역별 조명 색(뒷마당 아침·공원·도시 노을)
- [ ] 이펙트: 가산 블렌딩 글로우 반짝이, 먼지 퍼프 (Flame 파티클)
- [ ] 성능: 표정·스킨별 셰이딩 결과 캐싱(Picture/Image), 저사양 모드 설정(RC 기본값 키 추가 시 엑셀→JSON)
- [ ] 샘플 화면(dev 전용 갤러리): 표정 9종 × 구역 조명 비교 — 품질 반복 개선용
**DoD**: 렌더 입력값 → 파츠 변형 계산 단위 테스트 · 셰이더 로드 실패 시 대체 경로 테스트 · 보급형 실기기 60fps · 사용자 아트 품질 확인

---

## P8 온보딩·표정·사운드 합성 ⬜ (GDD §3 표정·사운드·제작 원칙, §9)
- [ ] 온보딩 스크립트(GDD §9): 1판 당기기만+트램폴린 자동배치 / 2판 부스터+첫 업그레이드 무료 / 3판 황금씨앗 확정+광고 2배 제안 / 5판 퍼펙트 릴리즈 / 공원 도달 시 부풀리기·급강하 해금
- [ ] 표정 9종 상태 머신(domain 에서 표정 상태 결정 → game/render `expr` 입력)
- [ ] 효과음 코드 합성(참고: 샘플 HTML 의 squeakStart/Set/Stop·boostSound·tone·noise) (고무 늘어남 음높이, 발사 휘익+찍, 씨앗 뽁 콤보 음계 상승, 착지 뿅) — 합성·재생 방식 ADR, BGM 은 CC0 만
- [ ] 폰트 OFL(Jua / Gowun Dodum) 적용, 문자열 `ui/strings.dart` 정리
**DoD**: 온보딩 단계 전이 테스트(1~5판 시나리오) · 표정 전이 테스트 · 합성음 생성 결정론 테스트

---

## P9 외부 서비스 연동 ⬜ (사전: Firebase 프로젝트·AdMob 계정 필요)
- [ ] Firebase 프로젝트 dev/prod 분리, `google-services.json`은 flavor 별 배치(git 제외, CI Secrets)
- [ ] Remote Config: 기본값 = balance_defaults.json, 가져오기 실패 시 기본값, GDD §10 키 전체
- [ ] Analytics 이벤트 명세(`docs/ANALYTICS.md` 작성): run_start, run_end(거리·씨앗·퍼펙트), upgrade_buy, zone_reach, ad_offer/ad_watch, iap_purchase, tutorial_step
- [ ] 광고: 보상형(결과 2배), 전면(첫 5판 제외, 3~4판마다 — RC `ad_interstitial_*`), 테스트 ID
- [ ] IAP: 광고 제거(₩5,900, 전면 제거 + 별사탕 300), 구매 복원
- [ ] Fake ↔ 실제 구현 전환은 `config/*.json`만으로
**DoD**: 각 서비스 계약 테스트(Fake/실제 동일 테스트) · dev 빌드 실기기에서 테스트 광고·테스트 결제 확인

---

## P10 MVP 출시 준비 ⬜
- [ ] 앱 아이콘·스플래시(flutter_launcher_icons / native_splash — ADR)
- [ ] 업로드 키 생성, Play Console 앱 등록, 데이터 보안 양식, 개인정보처리방침
- [ ] 성능: 저사양 기기 60fps, 메모리 누수 점검, 앱 크기 확인
- [ ] 크래시 수집(Firebase Crashlytics — ADR)
- [ ] release.yml 에 Play internal 트랙 자동 업로드 추가
- [ ] 소프트런칭 KPI 대시보드(D1, 세션 길이, 보상형 시청/DAU)
**DoD**: 태그 → internal 트랙 배포 성공 · BUILD_RELEASE §8 체크리스트 전부 체크

---

## v1.0 (P11~P15) — MVP 게이트 통과 후 세부 계획 작성
| Phase | 내용 | GDD |
|---|---|---|
| P11 | 월드 4~6 (구름·우주·달) 스테이지·보스 4-5·5-5, 저중력·블랙홀·달 착륙 엔딩 | §4 |
| P12 | 캐릭터 라인업(병아리·카피바라…), 스킨 슬롯 4개 | §3 |
| P13 | 장착 아이템 5종 + 조각 레벨업 | §6 |
| P14 | 랜덤 이벤트(황금 씨앗·보물상자·UFO·친구 구조) | §4 |
| P15 | 미션·업적·7일 출석, 상점·별사탕·뽑기, 스타터팩(15분) | §6, §7 |

## v1.1 / v1.2 — v1.0 게이트 통과 후 세부 계획 작성
- v1.1: 햄스터 마을(Idle), 무한 모드(월드 클리어 후) + 데일리 챌린지(고정 시드), 도감, Firestore 백업, Play Games 리더보드
- v1.2: 프레스티지 스킬 트리·화성, 주간 토너먼트, 시즌패스, 리플레이 GIF 공유, 씨앗 러시

## 미해결 질문 (해당 Phase 시작 시 확정)
| # | 질문 | 결정 시점 |
|---|---|---|
| Q1 | ~~화면 방향~~ → 가로 고정 + 반응형 (ADR-011) | ✅ |
| Q2 | ~~시뮬 시간·거리 스케일~~ → 미터 시뮬 + 샘플 체감 배율 (ADR-012) | ✅ |
| Q3 | ~~캐릭터 아트 소스~~ → GDD 개정으로 해결: 전부 코드 렌더링(ADR-009) | — |
| Q4 | 합성 효과음 재생 방식(flame_audio + 런타임 생성 WAV 등) | P8 |
| Q5 | Firebase/AdMob 계정 준비 일정 | P9 이전 |
| Q6 | ~~게이지 배율과 페이싱 기준~~ → 힘×배율 = 거리 배율, 기준 = 100%·1.0 (ADR-013) | ✅ |
| Q7 | 보스 2-5 규칙 (GDD 예시에 없음), MVP 보스 범위(1-5·2-5·3-5) | P6 |
| Q8 | ★★★ 스테이지별 미션 목록 (GDD 예시만 있음 → 시트 「스테이지」에 미션 열 추가 필요) | P5 |
