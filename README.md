# 모찌 런처 (mozzi)

볼주머니 빵빵한 햄스터를 쭈욱 당겨서, 달까지 날려라! — Flutter + Flame 하이브리드 캐주얼 게임.

- 기획: `모찌 런처 게임 기획서 (GDD).md`, 밸런스: `모찌런처_밸런스시트.xlsx`
- 개발 계획표: [docs/DEV_PLAN.md](docs/DEV_PLAN.md) · 진행 기록: [docs/PROGRESS.md](docs/PROGRESS.md)
- 규칙: [아키텍처](docs/ARCHITECTURE.md) · [코드](docs/CODING_RULES.md) · [빌드·출시](docs/BUILD_RELEASE.md) · [결정 기록](docs/DECISIONS.md)

```bash
flutter pub get
bash tool/verify.sh     # 품질 게이트
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```
