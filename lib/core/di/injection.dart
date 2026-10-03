import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'environments.dart';
import 'injection.config.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Generates registrations from `@injectable`-annotated classes + modules.
/// Awaited in `main.dart` because some registrations are `@preResolve`.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String? environment}) async {
  const useMocks = bool.fromEnvironment('USE_MOCKS');
  await sl.init(environment: environment ?? (useMocks ? mockEnv : apiEnv));
}
