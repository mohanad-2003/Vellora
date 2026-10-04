import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../constants/app_constants.dart';

/// Attaches the bearer token (if any) from secure storage to each request.
/// On a 401 for a signed-in request it ends the session (token + cached user),
/// which the app shell observes to send the user back to login. Swap point for
/// refresh-token rotation later.
@lazySingleton
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage,
    @Named(AppConstants.userBox) this._userBox,
  );

  final FlutterSecureStorage _storage;
  final Box _userBox;

  static const _userKey = 'current_user';

  /// Request option (`Options(extra: {skipAuthErrorKey: true})`) for calls that
  /// carry their own credentials and are not about the current session, such as
  /// the best-effort server sign-out of a token that was already cleared
  /// locally. A 401 for such a call must not end whatever session is active now.
  static const skipAuthErrorKey = 'skipAuthErrorHandling';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // An explicit Authorization header is left alone, not replaced by whatever
    // token happens to be stored when the request is sent.
    if (options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }
    final token = await _storage.read(key: AppConstants.secureAuthToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final skip = err.requestOptions.extra[skipAuthErrorKey] == true;
    final sentToken =
        err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && sentToken && !skip) {
      await _storage.delete(key: AppConstants.secureAuthToken);
      await _userBox.delete(_userKey);
    }
    handler.next(err);
  }
}
