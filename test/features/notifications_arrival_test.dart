import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/in_app_banner.dart';
import 'package:vellora/features/notifications/data/notifications_remote_datasource.dart';
import 'package:vellora/features/notifications/domain/notification_entity.dart';
import 'package:vellora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:vellora/features/notifications/presentation/widgets/notifications_refresher.dart';

/// A feed the test controls: what the shop would answer on each read.
class _Feed implements NotificationsRemoteDataSource {
  List<NotificationEntity> items = const [];
  bool offline = false;
  int reads = 0;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    reads++;
    if (offline) throw Exception('offline');
    return items;
  }

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> delete(String id) async {}
}

NotificationEntity _n(String id, {bool unread = true, String? productId, String? orderId, String? title}) =>
    NotificationEntity(
      id: id,
      kind: NotificationKind.promo,
      createdAt: DateTime(2026, 10, 15),
      title: title ?? 'Title $id',
      body: 'Body $id',
      isUnread: unread,
      productId: productId,
      orderId: orderId,
    );

void main() {
  late _Feed feed;
  late UnreadNotificationsCubit unread;
  late List<String> announced;

  setUp(() {
    feed = _Feed();
    unread = UnreadNotificationsCubit(feed);
    announced = [];
    unread.arrivals.listen((n) => announced.add(n.id));
  });

  tearDown(() async => unread.close());

  group('notifications that arrive while the app is open', () {
    test('what was there at the first read is not announced, what comes later is', () async {
      feed.items = [_n('old1'), _n('old2')];
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(announced, isEmpty);
      expect(unread.state, 2);

      feed.items = [_n('new', productId: 'p1'), _n('old1'), _n('old2')];
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(announced, ['new']);
      expect(unread.state, 3);

      await unread.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(announced, ['new'], reason: 'not announced twice');
    });

    test('several at once are announced oldest first, and read ones are not', () async {
      feed.items = [_n('a')];
      await unread.refresh();

      feed.items = [_n('c'), _n('r', unread: false), _n('b'), _n('a')];
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(announced, ['b', 'c']);
    });

    test('an offline moment announces nothing and loses nothing', () async {
      feed.items = [_n('a')];
      await unread.refresh();

      feed.offline = true;
      await unread.refresh();
      expect(unread.state, 0);

      feed.offline = false;
      feed.items = [_n('b'), _n('a')];
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(announced, ['b']);
    });

    test('what the shopper has just done themselves is taken in without announcing it', () async {
      feed.items = [_n('a')];
      await unread.refresh();

      feed.items = [_n('placed', orderId: 'o-1', title: 'Order placed'), _n('a')];
      await unread.refresh(announce: false);
      await Future<void>.delayed(Duration.zero);
      expect(announced, isEmpty);
      expect(unread.state, 2, reason: 'the dot still counts it');

      await unread.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(announced, isEmpty, reason: 'and it is not announced afterwards either');
    });

    test('after the account changes the new feed starts from scratch', () async {
      feed.items = [_n('mine')];
      await unread.refresh();

      unread.reset();
      feed.items = [_n('theirs1'), _n('theirs2')];
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(announced, isEmpty);
      expect(unread.state, 2);
    });

    test('what the Notifications screen already showed is not announced afterwards', () async {
      feed.items = [_n('a')];
      await unread.refresh();

      feed.items = [_n('b'), _n('a')];
      final screen = NotificationsCubit(feed, unread);
      await screen.load();
      await unread.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(announced, isEmpty);
      await screen.close();
    });
  });

  group('the Notifications screen', () {
    test('shows a notification that arrives while it is open, without a loading flash', () async {
      feed.items = [_n('a')];
      await unread.refresh();
      final screen = NotificationsCubit(feed, unread);
      await screen.load();
      expect(screen.state.items.map((n) => n.id), ['a']);

      final states = <NotificationsStatus>[];
      final sub = screen.stream.listen((s) => states.add(s.status));
      feed.items = [_n('b'), _n('a')];
      await unread.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(screen.state.items.map((n) => n.id), ['b', 'a']);
      expect(states, everyElement(NotificationsStatus.loaded));
      await sub.cancel();
      await screen.close();
    });

    test('keeps what it shows when the quiet reload fails', () async {
      feed.items = [_n('a')];
      final screen = NotificationsCubit(feed, unread);
      await screen.load();

      feed.offline = true;
      await screen.reloadQuietly();

      expect(screen.state.status, NotificationsStatus.loaded);
      expect(screen.state.items.map((n) => n.id), ['a']);
      await screen.close();
    });

    test('stops listening when it is closed', () async {
      final screen = NotificationsCubit(feed, unread);
      await screen.close();
      final before = feed.reads;

      feed.items = [_n('b')];
      await unread.refresh();
      await unread.refresh();
      feed.items = [_n('c'), _n('b')];
      await unread.refresh();

      expect(feed.reads - before, 3, reason: 'only the three refreshes, no reload by the closed screen');
    });
  });

  group('the banner over the top of the screen', () {
    late GlobalKey<NavigatorState> nav;
    late List<String> opened;

    setUp(() {
      nav = GlobalKey<NavigatorState>();
      opened = [];
      if (sl.isRegistered<UnreadNotificationsCubit>()) sl.unregister<UnreadNotificationsCubit>();
      sl.registerSingleton<UnreadNotificationsCubit>(unread);
    });

    tearDown(() {
      InAppBanner.hide();
      if (sl.isRegistered<UnreadNotificationsCubit>()) sl.unregister<UnreadNotificationsCubit>();
    });

    Widget app() => MaterialApp(
          navigatorKey: nav,
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => NotificationsRefresher(
            every: const Duration(hours: 1),
            overlay: () => nav.currentState?.overlay,
            open: (route, id) => opened.add('$route:$id'),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Center(child: Text('Product page')), bottomNavigationBar: SizedBox(height: 56, child: Text('Bottom bar'))),
        );

    Future<void> arrive(WidgetTester tester, NotificationEntity n) async {
      feed.items = [_n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pumpWidget(app());
      feed.items = [n, _n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows the title and text at the top, away from the bottom of the screen', (tester) async {
      await arrive(tester, _n('b', productId: 'p1', title: 'Back in stock'));

      expect(find.text('Back in stock'), findsOneWidget);
      expect(find.text('Body b'), findsOneWidget);
      final top = tester.getTopLeft(find.text('Back in stock')).dy;
      expect(top, lessThan(120), reason: 'near the top edge');
      expect(tester.getBottomLeft(find.text('Body b')).dy, lessThan(tester.getTopLeft(find.text('Bottom bar')).dy));
    });

    testWidgets('a tap opens the product it is about and closes the banner', (tester) async {
      await arrive(tester, _n('b', productId: 'p1', title: 'Back in stock'));

      await tester.tap(find.text('Back in stock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(opened, ['product:p1']);
      expect(find.text('Back in stock'), findsNothing);
    });

    testWidgets('an order notification opens the order', (tester) async {
      await arrive(tester, _n('b', orderId: 'o-7', title: 'Order shipped'));

      await tester.tap(find.text('Order shipped'));
      await tester.pump();

      expect(opened, ['orderDetails:o-7']);
    });

    testWidgets('one with nothing to open just closes when tapped', (tester) async {
      await arrive(tester, _n('b', title: 'Sale'));

      await tester.tap(find.text('Sale'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(opened, isEmpty);
      expect(find.text('Sale'), findsNothing);
    });

    testWidgets('goes away by itself, and a swipe up sends it away at once', (tester) async {
      await arrive(tester, _n('b', title: 'Sale'));
      expect(find.text('Sale'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Sale'), findsNothing);

      feed.items = [_n('c', title: 'Second'), _n('b', title: 'Sale'), _n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Second'), findsOneWidget);
      await tester.fling(find.text('Second'), const Offset(0, -300), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('a newer notification replaces the one showing', (tester) async {
      await arrive(tester, _n('b', title: 'First'));
      feed.items = [_n('c', title: 'Second'), _n('b', title: 'First'), _n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
    });
  });

  group('which way a message reads', () {
    test('Arabic right to left, everything else left to right', () {
      expect(AppSnackbar.directionOf('Order #VL-20042 was placed and is being processed.'), TextDirection.ltr);
      expect(AppSnackbar.directionOf('تم تأكيد طلبك'), TextDirection.rtl);
      expect(AppSnackbar.directionOf('طلب VL-20042'), TextDirection.rtl);
      expect(AppSnackbar.directionOf(''), TextDirection.ltr);
      expect(AppSnackbar.directionOf('12345'), TextDirection.ltr);
    });
  });
}
