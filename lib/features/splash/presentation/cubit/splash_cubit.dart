import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/safe_emit.dart';
import '../../../auth/domain/usecases/get_cached_user_usecase.dart';

/// Where the splash screen should route to once its checks complete.
enum SplashDestination { languageSelect, onboarding, login, home }

/// Resolves the initial destination: onboarding (first launch) → login
/// (returning, signed out) → home (valid session). Home is browsable as a
/// guest, so a missing session is not an error, but a session only counts when
/// the access token is in secure storage and the server still accepts it.
@injectable
class SplashCubit extends Cubit<SplashDestination?> with SafeEmit<SplashDestination?> {
  SplashCubit(this._prefs, this._getCachedUser, this._dio) : super(null);

  final SharedPreferences _prefs;
  final GetCachedUserUseCase _getCachedUser;
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

    // Signed in means a token in secure storage, not just a profile in Hive:
    // the use case returns null (and drops a stray profile) without one.
    final result = await _getCachedUser(const NoParams());
    final signedIn = result.fold((_) => false, (user) => user != null);
    if (!signedIn || !await _sessionStillValid()) {
      emit(SplashDestination.login);
      return;
    }
    emit(SplashDestination.home);
  }

  /// Asks the server whether the saved token is still accepted. Only an
  /// explicit 401 counts as expired (the auth interceptor has then already
  /// cleared the session); being offline or a slow server must not sign the
  /// user out, so every other outcome keeps the session.
  Future<bool> _sessionStillValid() async {
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
