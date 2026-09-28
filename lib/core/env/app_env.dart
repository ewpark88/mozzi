/// 빌드 flavor 환경값. `--dart-define-from-file=config/<flavor>.json` 으로 주입된다.
///
/// 규칙: docs/BUILD_RELEASE.md §4
enum Flavor { dev, prod }

class AppEnv {
  const AppEnv({required this.flavor, required this.useFakeServices});

  /// dart-define 값으로 환경을 만든다. 값이 없으면 dev + Fake 서비스.
  factory AppEnv.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const useFake = bool.fromEnvironment(
      'USE_FAKE_SERVICES',
      defaultValue: true,
    );
    return AppEnv(
      flavor: Flavor.values.firstWhere(
        (f) => f.name == flavorName,
        orElse: () => Flavor.dev,
      ),
      useFakeServices: useFake,
    );
  }

  final Flavor flavor;

  /// true면 Remote Config·Analytics·광고·결제를 Fake 구현으로 대체한다.
  final bool useFakeServices;

  bool get isDev => flavor == Flavor.dev;
}
