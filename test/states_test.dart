import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/exceptions.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/failure_state_view.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/slow_load_hint.dart';
import 'package:vellora/features/notifications/data/notifications_remote_datasource.dart';
import 'package:vellora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:vellora/features/orders/data/orders_remote_datasource.dart';
import 'package:vellora/features/orders/presentation/cubit/orders_cubit.dart';

class _MockOrders extends Mock implements OrdersRemoteDataSource {}

class _MockNotifications extends Mock implements NotificationsRemoteDataSource {}

Widget _app(Widget home, {GoRouter? router}) {
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (router != null) {
    return MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: delegates,
    home: Scaffold(body: home),
  );
}

void main() {
  group('FailureStateView', () {
    testWidgets('signed-out refusal becomes an invitation to sign in',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            builder: (_, _) =>
                const Scaffold(body: FailureStateView(failureKey: 'pleaseLogin')),
          ),
          GoRoute(
            path: RouteNames.login,
            name: RouteNames.nLogin,
            builder: (_, _) => const Scaffold(body: Text('LOGIN SCREEN')),
          ),
        ],
      );
      await tester.pumpWidget(_app(const SizedBox(), router: router));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Retry'), findsNothing);

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN SCREEN'), findsOneWidget);
    });

    testWidgets('no connection says so and offers a retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _app(FailureStateView(failureKey: 'noConnection', onRetry: () => retried++)),
      );

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('an unknown key falls back to a generic message', (tester) async {
      await tester.pumpWidget(_app(const FailureStateView()));
      expect(find.text('Something went wrong'), findsWidgets);
    });
  });

  group('SlowLoadHint', () {
    testWidgets('appears only after the screen has been loading a while',
        (tester) async {
      await tester.pumpWidget(_app(const SlowLoadHint()));

      expect(find.textContaining('server may be waking up'), findsNothing);
      await tester.pump(const Duration(seconds: 7));
      expect(find.textContaining('server may be waking up'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('server may be waking up'), findsOneWidget);
    });

    testWidgets('leaving early leaves no timer running', (tester) async {
      await tester.pumpWidget(_app(const SlowLoadHint()));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 30)); // would fail on a leaked timer
      expect(find.textContaining('server may be waking up'), findsNothing);
    });

    testWidgets('list skeletons carry it', (tester) async {
      await tester.pumpWidget(_app(const ListSkeleton()));
      expect(find.byType(SlowLoadHint), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
      expect(find.textContaining('server may be waking up'), findsOneWidget);
    });
  });

  group('Order details: why it failed', () {
    late _MockOrders remote;
    late OrderDetailCubit cubit;

    setUp(() {
      remote = _MockOrders();
      cubit = OrderDetailCubit(remote);
    });

    tearDown(() => cubit.close());

    test('a missing order is "not found"', () async {
      when(() => remote.getOrder(any())).thenThrow(const NotFoundException());
      await cubit.load('x');
      expect(cubit.state.status, OrderDetailStatus.notFound);
    });

    test('being offline is an error with a retry, not "not found"', () async {
      when(() => remote.getOrder(any())).thenThrow(const NetworkException());
      await cubit.load('x');
      expect(cubit.state.status, OrderDetailStatus.error);
      expect(cubit.state.failureKey, 'noConnection');
    });

    test('a signed-out user is asked to sign in', () async {
      when(() => remote.getOrder(any()))
          .thenThrow(const UnauthorizedException('no token', 'unauthorized'));
      await cubit.load('x');
      expect(cubit.state.status, OrderDetailStatus.error);
      expect(cubit.state.failureKey, 'pleaseLogin');
    });

    test('a server failure says so', () async {
      when(() => remote.getOrder(any())).thenThrow(const ServerException());
      await cubit.load('x');
      expect(cubit.state.failureKey, 'serverError');
    });
  });

  group('Lists keep the reason they failed', () {
    test('orders', () async {
      final remote = _MockOrders();
      when(remote.getOrders).thenThrow(const NetworkException());
      final cubit = OrdersCubit(remote);
      await cubit.load();
      expect(cubit.state.status, OrdersStatus.error);
      expect(cubit.state.failureKey, 'noConnection');
      await cubit.close();
    });

    test('orders for a signed-out user', () async {
      final remote = _MockOrders();
      when(remote.getOrders)
          .thenThrow(const UnauthorizedException('no token', 'unauthorized'));
      final cubit = OrdersCubit(remote);
      await cubit.load();
      expect(cubit.state.failureKey, 'pleaseLogin');
      await cubit.close();
    });

    test('notifications', () async {
      final remote = _MockNotifications();
      when(remote.getNotifications)
          .thenThrow(const UnauthorizedException('no token', 'unauthorized'));
      final cubit = NotificationsCubit(remote, UnreadNotificationsCubit(remote));
      await cubit.load();
      expect(cubit.state.status, NotificationsStatus.error);
      expect(cubit.state.failureKey, 'pleaseLogin');
      await cubit.close();
    });
  });
}
