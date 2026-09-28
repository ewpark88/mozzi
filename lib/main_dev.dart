import 'package:mozzi/app/bootstrap.dart';
import 'package:mozzi/core/env/app_env.dart';

Future<void> main() => bootstrap(AppEnv.fromEnvironment());
