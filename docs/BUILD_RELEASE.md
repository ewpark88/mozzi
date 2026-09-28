# 빌드 & 출시 규칙

## 1. 브랜치
| 브랜치 | 용도 | 규칙 |
|---|---|---|
| `main` | 항상 빌드·실행 가능한 상태 | 직접 커밋 금지(P0 초기 커밋 제외). PR + CI 통과 후 머지 |
| `feat/P{N}-{이름}` | Phase 작업 | 예: `feat/P1-domain-core`. Phase 하나에 PR 1~3개 |
| `fix/{이름}` | 버그 수정 | 재현 테스트 포함 |
| `hotfix/v{X.Y.Z}` | 출시 버전 긴급 수정 | 출시 태그에서 분기 → main 에도 머지 |

- 머지 방식: Squash merge (PR 제목 = Conventional Commit 형식).

## 2. 커밋
Conventional Commits, 한 커밋 = 한 목적, 메시지는 한국어 가능.
```
<type>(<scope>): <요약>
type : feat | fix | refactor | test | docs | chore | build | ci | perf | balance
scope: app | core | balance | sim | world | economy | progress | data | game | ui | tool | docs
예)  feat(sim): 퍼펙트 릴리즈 시 초기 속도 +15%
     balance: 공기역학 비용 증가율 1.17 → 1.18 (엑셀 갱신 + JSON 재생성)
```
- 커밋 전 `bash tool/verify.sh` 통과 필수.

## 3. 버전
`pubspec.yaml`의 `version: MAJOR.MINOR.PATCH+BUILD`
| 구간 | 버전 | 예 |
|---|---|---|
| P0~P9 개발(MVP) | `0.<Phase>.PATCH` | P3 완료 = `0.3.0` |
| MVP 소프트런칭 | `0.9.x` | |
| 정식 출시 | `1.0.0` | 이후 GDD 로드맵: 1.1 / 1.2 |
| 핫픽스 | PATCH +1 | `1.0.1` |
- `BUILD`(versionCode)는 **스토어에 올릴 때마다 +1**, 절대 줄이지 않는다.
- 태그: `v{MAJOR.MINOR.PATCH}` — release 워크플로가 pubspec 버전과 태그 일치를 검사한다.
- Phase 완료 시 MINOR 를 올리고 `docs/PROGRESS.md`에 기록한다.

## 4. Flavor (환경)
| flavor | applicationId | 앱 이름 | 진입점 | 설정 파일 | 용도 |
|---|---|---|---|---|---|
| dev | `com.repo.mozzi.dev` | 모찌 DEV | `lib/main_dev.dart` | `config/dev.json` | 개발, 테스트 광고 ID, 디버그 메뉴 |
| prod | `com.repo.mozzi` | 모찌 런처 | `lib/main_prod.dart` | `config/prod.json` | 스토어 출시 |

```bash
# 실행
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
# 개발 APK
flutter build apk --flavor dev --debug -t lib/main_dev.dart --dart-define-from-file=config/dev.json
# 출시 AAB (로컬; 보통은 CI)
flutter build appbundle --flavor prod --release -t lib/main_prod.dart \
  --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols
```
- dev/prod 는 기기에 동시 설치 가능 (applicationId 다름).
- `config/*.json`에는 비밀 값을 넣지 않는다 (광고 ID처럼 공개돼도 되는 값만).
- iOS flavor 는 iOS 작업 시작 시(v1.0 이후) 구성한다.

## 5. 서명
- 업로드 키스토어: `android/app/upload-keystore.jks`, 설정: `android/key.properties` — **둘 다 git 제외**.
  ```properties
  storeFile=upload-keystore.jks
  keyAlias=upload
  keyPassword=****
  storePassword=****
  ```
- `key.properties`가 없으면 release 빌드는 debug 키로 서명된다 (로컬 확인용, 스토어 업로드 불가).
- Play App Signing 사용 (Google 이 앱 서명 키 보관, 우리는 업로드 키만 관리).
- 키스토어 원본과 비밀번호는 저장소 밖 2곳 이상(암호 관리자 + 오프라인 백업)에 보관.
- CI: GitHub Secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`.

## 6. CI (`.github/workflows/ci.yml`)
- 트리거: 모든 PR, main push.
- 단계: pub get → `tool/verify.sh`(format / analyze / architecture / balance sync / test) → dev debug APK 빌드.
- CI 실패 PR 은 머지하지 않는다. Flutter 버전은 워크플로에 고정(현재 3.44.0) — 올릴 때는 ADR 기록.

## 7. 릴리즈 (`.github/workflows/release.yml`)
1. `release/v{X.Y.Z}` 준비: pubspec 버전·BUILD 증가, `docs/PROGRESS.md` 에 변경 요약.
2. 체크리스트(§8) 확인 → main 머지.
3. `git tag vX.Y.Z && git push origin vX.Y.Z` (사용자 승인 후)
4. CI 가 verify → 태그/버전 일치 검사 → 서명된 prod AAB + 난독화 심볼 아티팩트 생성.
5. (P9 이후) 자동으로 Play Console **internal** 트랙 업로드.
6. 트랙 승격: internal → closed(소프트런칭) → production 단계적 출시 10% → 50% → 100% (각 단계 최소 24시간, 크래시율 확인).

## 8. 출시 체크리스트
- [ ] `tool/verify.sh` 통과, CI green
- [ ] pubspec 버전·BUILD 증가, 태그와 일치
- [ ] prod flavor 에 테스트 광고 ID·디버그 메뉴·Fake 서비스가 **없음** (`USE_FAKE_SERVICES=false`)
- [ ] `balance_defaults.json` = 엑셀 최신값, Remote Config 콘솔 기본값과 동기화
- [ ] 신규 Analytics 이벤트가 이벤트 명세와 일치
- [ ] 실기기(저사양 1대 포함) 10판 플레이: 크래시 0, 60fps 유지, 저장/복원 정상
- [ ] 광고: 첫 5판 전면 광고 없음, 보상형 보상 지급 확인
- [ ] 결제: 테스트 계정으로 구매·복원 확인
- [ ] 스토어 문구·스크린샷·개인정보처리방침·데이터 보안 양식 최신
- [ ] 난독화 심볼(build/symbols) 보관

## 9. 롤백·핫픽스
1. **먼저 Remote Config** 로 문제 기능 끄기/수치 복구 (`liveops_active_event` 등) — 앱 업데이트 없이 즉시.
2. 단계적 출시 중이면 Play Console 에서 출시 중지.
3. 코드 수정 필요 시 `hotfix/vX.Y.Z` → 재현 테스트 + 수정 → PATCH 버전 → 릴리즈 절차.
4. `docs/PROGRESS.md` 에 사고 기록(원인·영향·재발 방지).
