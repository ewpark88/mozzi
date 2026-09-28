# 결정 기록 (ADR)

형식: 번호 · 날짜 · 상태(제안/채택/대체됨) · 맥락 · 결정 · 결과(트레이드오프).
새 결정은 아래에 추가하고, 번복하면 기존 항목 상태를 “대체됨(ADR-N)”으로 바꾼다.

---

## ADR-001 자체 경량 결정론적 물리 (flame_forge2d 미사용)
- 날짜: 2026-09-28 · 상태: 채택
- 맥락: GDD §10 은 flame_forge2d 를 명시했지만, 밸런스·페이싱은 공식 `d = v²/g × …` 기반이고 데일리 챌린지(고정 시드)·리플레이·헤드리스 테스트가 필요하다.
- 결정: `lib/domain/sim`에 고정 timestep(1/60초) 순수 Dart 시뮬레이터를 직접 구현한다. 충돌은 원(모찌) vs 원/AABB(오브젝트) 수준으로 단순화한다.
- 결과: 공식과 실측 거리 보정 쉬움, 결정론 보장, 테스트 용이. 대신 복잡한 강체 충돌은 직접 만들어야 한다(게임 특성상 불필요).

## ADR-002 상태관리 flutter_riverpod (코드 생성 없음)
- 날짜: 2026-09-28 · 상태: 채택
- 결정: Riverpod 3.x 의 `Provider`/`Notifier` 계열만 사용. build_runner 코드 생성은 쓰지 않는다.
- 결과: 1인 개발에서 빌드 단계 단순, 테스트 시 override 로 Fake 주입 쉬움.

## ADR-003 외부 서비스는 인터페이스 + Fake 우선
- 날짜: 2026-09-28 · 상태: 채택
- 맥락: Firebase·AdMob 계정 미준비.
- 결정: domain/services 에 인터페이스, data/fake 에 Fake 를 먼저 만들고 P8 에서 실제 구현을 추가한다. `config/*.json`의 `USE_FAKE_SERVICES`로 선택.
- 결과: 코어 개발이 외부 준비에 막히지 않음. P8 에서 계약 테스트로 실제 구현 검증 필요.

## ADR-004 밸런스 단일 원본 = 엑셀
- 날짜: 2026-09-28 · 상태: 채택
- 결정: `모찌런처_밸런스시트.xlsx` → `tool/balance/export_balance.py` → `assets/config/balance_defaults.json`. JSON 직접 수정 금지(훅 차단), verify 가 불일치 검출.
- 결과: 기획 수치와 코드가 어긋나지 않음. 엑셀 구조를 바꾸면 스크립트도 수정 필요.

## ADR-005 저장소 hive_ce
- 날짜: 2026-09-28 · 상태: 채택
- 맥락: GDD 는 Hive 지정. 원본 hive 패키지는 유지보수가 멈춤.
- 결정: 커뮤니티 후속판 `hive_ce`/`hive_ce_flutter` 사용. data 레이어에만 import.

## ADR-006 린트 very_good_analysis + strict 모드
- 날짜: 2026-09-28 · 상태: 채택
- 결정: very_good_analysis 기반, `strict-casts/inference/raw-types`, verify 에서 info 도 실패 처리. 한국어 주석 때문에 `lines_longer_than_80_chars`, 문서 강제 `public_member_api_docs`는 끔(도메인 문서화는 리뷰로 확인).

## ADR-007 Android applicationId `com.repo.mozzi`, flavor dev/prod
- 날짜: 2026-09-28 · 상태: 채택
- 결정: prod `com.repo.mozzi`, dev `com.repo.mozzi.dev`. iOS 는 v1.0 이후 구성.
