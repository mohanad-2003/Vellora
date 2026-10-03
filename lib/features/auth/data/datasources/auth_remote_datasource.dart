import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// Auth backend contract. [ApiAuthRemoteDataSource] talks to the Vellora API;
/// [MockAuthRemoteDataSource] (tests / offline demo) simulates latency and fails deterministically so
/// error/retry UI is reachable without a real API:
///   * login  → wrong password (< 6 chars) throws [ValidationException];
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
    if (password.length < 6) {
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
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
    );
    // The development server returns the code (no email provider yet).
    final devCode = res.data?['devCode'];
    if (kDebugMode && devCode != null) {
      debugPrint('[dev] password reset code: $devCode');
    }
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
}
