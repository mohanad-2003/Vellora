import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/push/push_gateway.dart';
import 'core/push/push_navigation.dart';
import 'core/push/push_registrar.dart';
import 'features/auth/presentation/bloc/user_session_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/product/domain/repositories/favorites_repository.dart';

Future<void> main() => CrashReporting.run(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      await configureDependencies();

      // A signed-in user's wishlist and bag may have changed on another device.
      unawaited(sl<FavoritesRepository>().sync());
      unawaited(sl<CartRepository>().sync());
      runApp(const VelloraApp());
      _startPush();
    });

/// Notifications while the app is closed: this phone is registered with the shop
/// for as long as someone is signed in. Only on phones, and never with mock data.
void _startPush() {
  const useMocks = bool.fromEnvironment('USE_MOCKS');
  final phone =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (useMocks || kIsWeb || !phone) return;
  final session = sl<UserSessionCubit>();
  unawaited(
    PushRegistrar(
      gateway: FirebasePushGateway(),
      dio: sl<Dio>(),
      isSignedIn: () => session.state != null,
      sessionChanges: session.stream.map((_) {}),
      onOpen: openFromPush,
      onForeground: () => sl<UnreadNotificationsCubit>().refresh(),
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    ).start(),
  );
}
