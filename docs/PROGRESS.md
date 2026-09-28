# 진행 기록

매 Phase 종료 시(`/phase-verify`) 최신 항목을 위에 추가한다.
형식: 날짜 · Phase · 버전 · 완료 항목 · 남은 이슈 · 결정(ADR 번호)

---

## 2026-09-28 · P0 하네스·스캐폴딩 · 0.0.1+1
**완료**
- Flutter 3.44.0 프로젝트 생성 (`com.repo.mozzi`), Android flavor dev/prod, 서명 설정 골격
- 문서: CLAUDE.md, ARCHITECTURE, CODING_RULES, BUILD_RELEASE, DEV_PLAN, DECISIONS, PROGRESS
- 하네스: verify(sh/ps1), 아키텍처 검사기+테스트, 밸런스 엑셀→JSON export/check, Claude 훅(보호 파일 차단·자동 포맷), `/phase-start`·`/phase-verify`
- CI/CD: ci.yml, release.yml
- 검증: verify 통과(테스트 7개), 아키텍처 위반 주입 시 exit 1 확인, 보호 파일 훅 exit 2 확인, dev 디버그 APK 빌드 성공

**남은 이슈**
- GitHub 원격 저장소 연결 후 CI 첫 실행 확인

**결정**: ADR-001 ~ ADR-007
