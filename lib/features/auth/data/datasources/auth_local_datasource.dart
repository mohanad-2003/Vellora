import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Persists the signed-in user and their session.
///
/// * Hive `user_box`: profile data only (id, name, email, phone, avatar). It is
///   a plain file, so it never holds the access token or any credential.
/// * Secure storage: the access token, and nothing else. It is the only proof
///   of a session: a profile record without a token does not count as signed in.
abstract class AuthLocalDataSource {
  /// Saves the profile in Hive and, when [user] carries one, the token in
  /// secure storage.
  Future<void> cacheUser(UserModel user);

  /// The signed-in user with their token, or null when there is no session: no
  /// profile, or a profile whose token is missing (the stale record is removed).
  Future<UserModel?> getCachedUser();

  /// Replaces the stored access token (the server issued a fresh one).
  Future<void> saveToken(String token);
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

  /// True while old-format data is being cleaned up, so two reads at once do
  /// not both start it.
  bool _migratingLegacy = false;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      // `token` is not part of the JSON, so it cannot reach Hive.
      await _userBox.put(_userKey, jsonEncode(user.toJson()));
      final token = user.token;
      if (token != null && token.isNotEmpty) await saveToken(token);
    } catch (_) {
      throw const CacheException('Failed to cache user');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = _userBox.get(_userKey);
      if (raw is! String) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Versions before this one kept the token inside the Hive record.
      final hadLegacyToken = json.containsKey('token');
      if (hadLegacyToken) json.remove('token');

      final token = await _secureStorage.read(key: AppConstants.secureAuthToken);
      final hasSession = token != null && token.isNotEmpty;

      if (hadLegacyToken || !hasSession) {
        if (hasSession) {
          // Keep the profile, minus the token that used to be stored with it.
          await _userBox.put(_userKey, jsonEncode(json));
        } else {
          // A profile with no token is not a session (and may have been planted).
          await _userBox.delete(_userKey);
        }
        if (hadLegacyToken) await _compactAfterLegacyCleanup();
      }
      if (!hasSession) return null;
      return UserModel.fromJson(json).copyWith(token: token);
    } catch (_) {
      throw const CacheException('Failed to read cached user');
    }
  }

  /// Hive only appends to its file: overwriting or deleting a record leaves the
  /// old bytes there until the box is compacted. After removing a legacy token
  /// from the record, compact so that old copies are rewritten away too.
  /// Runs only on this one-time cleanup path, never on ordinary reads.
  Future<void> _compactAfterLegacyCleanup() async {
    if (_migratingLegacy) return;
    _migratingLegacy = true;
    try {
      await _userBox.compact();
    } catch (_) {
      // Cleanup is best effort; the record itself is already token-free.
    } finally {
      _migratingLegacy = false;
    }
  }

  @override
  Future<void> saveToken(String token) =>
      _secureStorage.write(key: AppConstants.secureAuthToken, value: token);

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
