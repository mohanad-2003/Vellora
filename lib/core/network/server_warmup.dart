import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

/// Wakes the hosted API early. It sleeps when idle and takes up to a minute to
/// answer its first request, so a tiny `/ping` goes out as the app opens (while
/// the splash plays) and again when the app returns after a long pause. Every
/// failure is ignored: this only shortens the wait, it never changes what a
/// screen shows.
class ServerWarmup with WidgetsBindingObserver {
  ServerWarmup({Dio? dio, DateTime Function()? now})
    : _dio = dio ?? _bareDio(),
      _now = now ?? DateTime.now;

  /// A little less than the host's idle limit, so the server is still awake
  /// when the user is.
  static const Duration idleAfter = Duration(minutes: 8);

  final Dio _dio;
  final DateTime Function() _now;
  DateTime? _lastPing;
  DateTime? _pausedAt;

  static Dio _bareDio() => Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ),
  );

  /// Sends the first ping and starts watching for the app coming back.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(ping());
  }

  void stop() => WidgetsBinding.instance.removeObserver(this);

  Future<void> ping() async {
    _lastPing = _now();
    try {
      await _dio.get<String>('/ping');
    } catch (_) {
      // Offline or still waking: the real request will retry on its own.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = _now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt;
      final last = _lastPing;
      _pausedAt = null;
      final since = last == null ? idleAfter : _now().difference(last);
      if (away != null && since >= idleAfter) unawaited(ping());
    }
  }
}
