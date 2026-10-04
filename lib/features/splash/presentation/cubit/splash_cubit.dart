import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_endpoints.dart';

/// Where the splash screen should route to once its checks complete.
enum SplashDestination { languageSelect, onboarding, login, home }

/// Resolves the initial destination: onboarding (first launch) → login
/// (returning, signed out) → home (cached user present). Home is browsable in
/// Phase 1, so auth is not strictly guarded.
@injectable
class SplashCubit extends Cubit<SplashDestination?> {
  SplashCubit(
    this._prefs,
    @Named(AppConstants.userBox) this._userBox,
    this._storage,
    this._dio,
  ) : super(null);

  final SharedPreferences _prefs;
  final Box _userBox;
  final FlutterSecureStorage _storage;
  final Dio _dio;

  Future<void> decide() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    final languageSelected =
        _prefs.getBool(AppConstants.prefLanguageSelected) ?? false;
    if (!languageSelected) {
      emit(SplashDestination.languageSelect);
      return;
    }

    final seenOnboarding =
        _prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;
    if (!seenOnboarding) {
      emit(SplashDestination.onboarding);
      return;
    }

    final hasCachedUser = _userBox.isNotEmpty;
    if (hasCachedUser && !await _sessionStillValid()) {
      emit(SplashDestination.login);
      return;
    }
    emit(hasCachedUser ? SplashDestination.home : SplashDestination.login);
  }

  /// Asks the server whether the saved token is still accepted. Only an
  /// explicit 401 counts as expired; being offline or a slow server must not
  /// sign the user out, so every other outcome keeps the cached session.
  Future<bool> _sessionStillValid() async {
    final token = await _storage.read(key: AppConstants.secureAuthToken);
    if (token == null || token.isEmpty) return true;
    try {
      await _dio.get<void>(
        ApiEndpoints.me,
        options: Options(
          sendTimeout: _sessionCheckTimeout,
          receiveTimeout: _sessionCheckTimeout,
        ),
      );
    } on DioException catch (e) {
      return e.response?.statusCode != 401;
    }
    return true;
  }

  static const _sessionCheckTimeout = Duration(seconds: 5);
}
