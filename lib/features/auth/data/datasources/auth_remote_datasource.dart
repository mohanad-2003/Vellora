import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../models/user_model.dart';

/// Auth backend contract. [ApiAuthRemoteDataSource] talks to the Vellora API;
/// [MockAuthRemoteDataSource] (tests / offline demo) simulates latency and fails deterministically so
/// error/retry UI is reachable without a real API:
///   * login  → wrong password (< 8 chars) throws [ValidationException];
///              reserved fail email throws [ServerException].
///   * register → reserved existing email throws [ValidationException].
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> forgotPassword({required String email});
  Future<String> verifyOtp({required String email, required String code});
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  /// Saves the display name on the server for the signed-in user.
  Future<void> updateName({required String name});

  /// Changes the password. The server signs every session out and returns a
  /// fresh token for this device (null when there is nothing to replace).
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Tells the server to end the session behind [token] (and all others), so a
  /// copy of the token stops working. Best effort: the caller ignores failures.
  Future<void> logout({required String token});

  /// Permanently deletes the signed-in account (password confirms it).
  Future<void> deleteAccount({required String password});
}

@mockOnly
@LazySingleton(as: AuthRemoteDataSource)
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  int _idCounter = 1;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(AppConstants.mockDelay);

    if (email.trim().toLowerCase() == AppConstants.reservedFailEmail) {
      throw const ServerException('Login service is temporarily unavailable');
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw const ValidationException('Invalid email or password');
    }

    final name = _nameFromEmail(email);
    return UserModel(
      id: 'u${_idCounter++}',
      name: name,
      email: email.trim(),
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(AppConstants.mockDelay);

    if (email.trim().toLowerCase() == AppConstants.reservedExistingEmail) {
      throw const ValidationException('An account with this email exists');
    }

    return UserModel(
      id: 'u${_idCounter++}',
      name: name.trim(),
      email: email.trim(),
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(AppConstants.mockDelay);
    if (email.trim().toLowerCase() == AppConstants.reservedFailEmail) {
      throw const ServerException('Unable to send reset link');
    }
  }

  @override
  Future<String> verifyOtp({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(AppConstants.mockShortDelay);
    if (code.trim() != AppConstants.reservedOtpCode) {
      throw const ValidationException('The verification code is incorrect');
    }
    return 'reset-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await Future<void>.delayed(AppConstants.mockDelay);
    if (resetToken.isEmpty) {
      throw const ServerException('Reset session expired, please try again');
    }
  }

  @override
  Future<void> updateName({required String name}) async {}

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => null;

  @override
  Future<void> logout({required String token}) async {}

  @override
  Future<void> deleteAccount({required String password}) async {}

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Shopper';
    return local[0].toUpperCase() + local.substring(1);
  }
}

@apiOnly
@LazySingleton(as: AuthRemoteDataSource)
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._dio);

  final Dio _dio;

  UserModel _session(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return UserModel(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      token: json['token'] as String,
    );
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email.trim(), 'password': password},
    );
    return _session(res.data!);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return _session(res.data!);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _dio.post<void>(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
    );
  }

  @override
  Future<String> verifyOtp({
    required String email,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {'email': email.trim(), 'code': code.trim()},
    );
    return res.data!['resetToken'] as String;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.resetPassword,
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  @override
  Future<void> updateName({required String name}) async {
    await _dio.patch<void>(ApiEndpoints.me, data: {'name': name.trim()});
  }

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return res.data?['token'] as String?;
  }

  @override
  Future<void> logout({required String token}) async {
    // The token is passed explicitly: by the time this runs the local session
    // (and the interceptor's copy of the token) has already been cleared.
    await _dio.post<void>(
      ApiEndpoints.logout,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        // A 401 here only means this old token is already dead; it must not
        // clear a session the user may have started since.
        extra: {AuthInterceptor.skipAuthErrorKey: true},
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await _dio.delete<void>(ApiEndpoints.me, data: {'password': password});
  }
}
