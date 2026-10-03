import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Persists the signed-in user (Hive) and auth token (secure storage).
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clear();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(
    @Named(AppConstants.userBox) this._userBox,
    this._secureStorage,
  );

  final Box _userBox;
  final FlutterSecureStorage _secureStorage;

  static const _userKey = 'current_user';

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _userBox.put(_userKey, jsonEncode(user.toJson()));
      if (user.token != null) {
        await _secureStorage.write(
          key: AppConstants.secureAuthToken,
          value: user.token,
        );
      }
    } catch (_) {
      throw const CacheException('Failed to cache user');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = _userBox.get(_userKey);
      if (raw is! String) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const CacheException('Failed to read cached user');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _userBox.delete(_userKey);
      await _secureStorage.delete(key: AppConstants.secureAuthToken);
    } catch (_) {
      throw const CacheException('Failed to clear user');
    }
  }
}
