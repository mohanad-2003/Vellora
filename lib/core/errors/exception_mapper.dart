import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// [ValidationFailure.code] marking "ask for the two-factor code".
const twoFactorRequiredCode = 'two_factor_required';

/// Translates data-layer [AppException]s into presentation-facing [Failure]s.
Failure mapExceptionToFailure(Object error) {
  // Dio wraps what our ErrorInterceptor produced; unwrap to the typed error.
  if (error is DioException && error.error is AppException) {
    error = error.error!;
  }
  if (error is TwoFactorRequiredException) {
    // Not an error to show: the sign-in flow reads `code` and asks for the
    // authenticator code. The challenge travels in `message`.
    return Failure.validation(
      message: error.challengeToken,
      code: twoFactorRequiredCode,
    );
  }
  if (error is ValidationException) {
    return Failure.validation(message: error.message, code: error.code);
  }
  if (error is NetworkException) {
    return Failure.network(message: error.message);
  }
  if (error is CacheException) {
    return Failure.cache(message: error.message);
  }
  if (error is NotFoundException || error is ServerException) {
    return Failure.server(message: (error as AppException).message);
  }
  if (error is UnauthorizedException) {
    return error.code == 'invalid_credentials'
        ? Failure.validation(message: error.message, code: error.code)
        : Failure.unauthorized(message: error.message);
  }
  if (error is AppException) {
    return Failure.unexpected(message: error.message);
  }
  return Failure.unexpected(message: error.toString());
}
