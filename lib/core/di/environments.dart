import 'package:injectable/injectable.dart';

/// Dependency-injection environments.
///
/// * [apiEnv] (default) — datasources talk to the Vellora API over HTTP.
/// * [mockEnv] — in-memory datasources with canned data. Used by the test suite
///   and available for offline demos:
///   `flutter run --dart-define=USE_MOCKS=true`.
const String apiEnv = 'api';
const String mockEnv = 'mock';

/// Registers a class only when talking to the real API.
const apiOnly = Environment(apiEnv);

/// Registers a class only in the mock environment.
const mockOnly = Environment(mockEnv);
