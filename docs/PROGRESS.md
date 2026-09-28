# 진행 기록

매 Phase 종료 시(`/phase-verify`) 최신 항목을 위에 추가한다.
형식: 날짜 · Phase · 버전 · 완료 항목 · 남은 이슈 · 결정(ADR 번호)

---

## 2026-09-28 · P1 도메인 코어 · 0.1.0+2
**완료**
- 밸런스: BalanceConfig(JSON 검증), UpgradeType/Levels, BalanceFormulas(GDD §5 공식), PacingSimulator(ADR-008)
- 경제·진행: Wallet, UpgradeService, PlayerProgress(세이브 스키마 v1)
- core: SeededRng(xorshift32), roundHalfUp(Excel ROUND), JsonReader, Result
- app: 밸런스 기본값 에셋 로드 → Riverpod Provider 주입
- 하네스: 시트 결과값 fixture 자동 생성·동기화 검사, 시트 생성기 `pacing_sim.py`, Excel COM 편집기 `xlsx_edit.ps1`
- 검증: verify 통과, 테스트 136개 — 업그레이드표 81레벨·진행 시뮬 300판×3시나리오가 시트와 완전 일치

**기준 문서 수정** (SPEC_CHANGELOG)
- 시트 「진행 시뮬」 A2 설명: 광고 30% 모델(×1.3 기대값)·구매 규칙·반올림 명시 (수치 변경 없음)
- GDD §10 물리 = 자체 결정론 물리(ADR-001 반영), 오탈자 4건

**GDD 개정 반영** (사용자 수정: 2.5D 코드 렌더링, 외부 에셋 0원)
- DEV_PLAN: P7 “2.5D 코드 렌더링” 신설, 이후 Phase 번호 +1 (P8 온보딩·사운드 합성, P9 외부 서비스, P10 출시 준비), P2 패럴랙스 5레이어
- ARCHITECTURE: `game/render/`, `shaders/` 추가

**GDD 개정 반영 2** (사용자 수정: §2 정확도 게이지, §10 게이지 RC 키) → DEV_PLAN P3 재작성, Q6 추가
- 사용자 편집기 저장으로 GDD 오탈자·물리 표기 수정이 되돌아가 재적용함

**GDD 개정 반영 3** (월드 6 × 스테이지 5, 별·해금·보스·월드맵·무한 모드)
- 시트 「스테이지」 신설(목표 거리·★★ 1.3·해금 별 + 시뮬 도달 판수), JSON·fixture·테스트 확장
- GDD 주장 검증: 월드 2~5 판수 일치, 1-1 만 조작 없이 4판(PERFECT 전제 1판) → 제안 G5
- DEV_PLAN P5(스테이지 골·별) / P6(월드맵·해금·보스·세이브 v2) / P11 / v1.1(무한 모드) 수정, Q7·Q8 추가
- 시트 「설정」 A26 주석 오류 수정 (거리 기준 → 씨앗 기준)

**하네스 추가**: `tool/spec/spec_sync.py` + UserPromptSubmit 훅 — GDD·시트가 바뀌면 매 프롬프트에서 감지, `/spec-sync` 로 반영
- GDD 직접 수정은 사용자 편집과 충돌해 두 번 되돌아감 → 편집 중에는 SPEC_CHANGELOG 의 “GDD 수정 제안”(G1~G9)으로 모아 둔다

**남은 이슈**
- P2 시작 시 결정: 화면 방향(Q1), 시뮬 시간·거리 스케일(Q2)
- P3 시작 시: 게이지 값 시트 추가, 게이지 배율과 페이싱 기준 관계(Q6)
- GDD 수정 제안 G1~G9 적용 (사용자 편집 종료 후)

**결정**: ADR-008(페이싱 규칙), ADR-009(2.5D 코드 렌더링), ADR-010(meta 의존)

---

## 2026-09-28 · P0 하네스·스캐폴딩 · 0.0.1+1
**완료**
- Flutter 3.44.0 프로젝트 생성 (`com.repo.mozzi`), Android flavor dev/prod, 서명 설정 골격
- 문서: CLAUDE.md, ARCHITECTURE, CODING_RULES, BUILD_RELEASE, DEV_PLAN, DECISIONS, PROGRESS
- 하네스: verify(sh/ps1), 아키텍처 검사기+테스트, 밸런스 엑셀→JSON export/check, Claude 훅(보호 파일 차단·자동 포맷), `/phase-start`·`/phase-verify`
- CI/CD: ci.yml, release.yml
- 검증: verify 통과(테스트 7개), 아키텍처 위반 주입 시 exit 1 확인, 보호 파일 훅 exit 2 확인, dev 디버그 APK 빌드 성공

**추가 (같은 날)**: GitHub 원격(ewpark88/mozzi) push, CI 첫 실행 성공 → P0 DoD 전부 충족

**결정**: ADR-001 ~ ADR-007
