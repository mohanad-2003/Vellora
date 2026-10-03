import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';

/// Lightweight, always-current view of the signed-in user for chrome that
/// needs only a name/avatar (Home greeting). Watches the Hive user box, so it
/// reflects login, profile edits and logout instantly. `null` means guest.
class SessionUser {
  const SessionUser({required this.name, this.email, this.avatarUrl});

  final String name;
  final String? email;
  final String? avatarUrl;

  /// First word of the name, for friendly greetings.
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.first;
  }

  @override
  bool operator ==(Object other) =>
      other is SessionUser &&
      other.name == name &&
      other.email == email &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(name, email, avatarUrl);
}

@lazySingleton
class UserSessionCubit extends Cubit<SessionUser?> {
  UserSessionCubit(@Named(AppConstants.userBox) this._box)
    : super(_read(_box)) {
    _subscription = _box.watch().listen((_) => emit(_read(_box)));
  }

  final Box _box;
  late final StreamSubscription<BoxEvent> _subscription;

  static const _userKey = 'current_user';

  static SessionUser? _read(Box box) {
    final raw = box.get(_userKey);
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final name = (json['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;
      return SessionUser(
        name: name,
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
