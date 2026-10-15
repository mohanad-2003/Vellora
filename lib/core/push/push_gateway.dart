import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// What the app needs from the push service, so the rest of the app (and its
/// tests) never touch Firebase directly.
abstract class PushGateway {
  /// Starts the service. False when it is not available here (a platform
  /// without Firebase set up, or no network service): push is then simply off.
  Future<bool> init();

  /// Asks the person to allow notifications; true when they are allowed.
  Future<bool> requestPermission();

  /// This phone's address for notifications, or null when there is none.
  Future<String?> token();

  /// A new address, when the service replaces the old one.
  Stream<String> get onTokenRefresh;

  /// A notification that arrived while the app is open.
  Stream<Map<String, String>> get onMessage;

  /// The person tapped a notification while the app was in the background.
  Stream<Map<String, String>> get onOpened;

  /// The notification that started the app, when it was tapped while closed.
  Future<Map<String, String>?> initialMessage();
}

Map<String, String> _data(RemoteMessage m) => {
  for (final e in m.data.entries) e.key: '${e.value}',
};

/// Firebase Cloud Messaging.
class FirebasePushGateway implements PushGateway {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<bool> init() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => _fcm.getToken();

  @override
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  @override
  Stream<Map<String, String>> get onMessage =>
      FirebaseMessaging.onMessage.map(_data);

  @override
  Stream<Map<String, String>> get onOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_data);

  @override
  Future<Map<String, String>?> initialMessage() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : _data(m);
  }
}
