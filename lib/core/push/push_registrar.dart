import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_endpoints.dart';
import 'push_gateway.dart';

/// Tells the shop which phone belongs to the signed-in shopper, so notifications
/// reach it while the app is closed, and acts on a tapped notification.
///
/// * Signing in asks for permission (Android 13+ shows its own question) and
///   registers this phone's address with the shop; signing out forgets it, so
///   the next person on the phone does not get the previous one's messages.
/// * When the service issues a new address it is registered again.
/// * A notification tapped from the tray opens what it is about ([onOpen]); one
///   that arrives while the app is open is handed to [onForeground], which
///   refreshes the in-app feed.
///
/// Every failure is swallowed: push is a convenience, never a reason for the app
/// to break.
class PushRegistrar {
  PushRegistrar({
    required this.gateway,
    required this.dio,
    required this.isSignedIn,
    required this.sessionChanges,
    required this.onOpen,
    required this.onForeground,
    this.platform = 'android',
  });

  final PushGateway gateway;
  final Dio dio;

  /// Whether someone is signed in right now.
  final bool Function() isSignedIn;

  /// Fires whenever someone signs in or out.
  final Stream<void> sessionChanges;

  /// Opens the screen a tapped notification is about (`orderId` / `productId`).
  final void Function(Map<String, String> data) onOpen;
  final VoidCallback onForeground;
  final String platform;

  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _started = false;
  bool _wasSignedIn = false;
  String? _registered;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      if (!await gateway.init()) return;
      _wasSignedIn = isSignedIn();
      _subscriptions
        ..add(sessionChanges.listen((_) => _sync()))
        ..add(gateway.onTokenRefresh.listen(_register))
        ..add(gateway.onMessage.listen((_) => onForeground()))
        ..add(gateway.onOpened.listen(onOpen));
      final first = await gateway.initialMessage();
      if (first != null) onOpen(first);
      if (_wasSignedIn) await _register();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  /// Someone signed in or out. Signing out only matters if someone was signed
  /// in: a guest opening the app tells the shop nothing.
  Future<void> _sync() async {
    final signedIn = isSignedIn();
    final was = _wasSignedIn;
    _wasSignedIn = signedIn;
    if (signedIn) {
      await _register();
    } else if (was) {
      await _forget();
    }
  }

  /// Asks permission and registers the phone's current address.
  Future<void> _register([String? known]) async {
    try {
      if (!isSignedIn()) return;
      if (known == null) {
        if (!await gateway.requestPermission()) return;
        known = await gateway.token();
      }
      if (known != null) await _send(known);
    } catch (_) {}
  }

  Future<void> _send(String token) async {
    if (!isSignedIn()) return;
    try {
      await dio.post<void>(
        ApiEndpoints.devices,
        data: {'token': token, 'platform': platform},
      );
      _registered = token;
    } catch (_) {}
  }

  /// The session is gone, so the shop is told by the address alone.
  Future<void> _forget() async {
    try {
      final token = _registered ?? await gateway.token();
      if (token == null) return;
      await dio.post<void>(
        ApiEndpoints.devicesUnregister,
        data: {'token': token},
      );
      _registered = null;
    } catch (_) {}
  }
}
