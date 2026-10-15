import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
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

  group('the announcement on screen', () {
    setUp(() {
      if (sl.isRegistered<UnreadNotificationsCubit>()) sl.unregister<UnreadNotificationsCubit>();
      sl.registerSingleton<UnreadNotificationsCubit>(unread);
    });

    tearDown(() {
      if (sl.isRegistered<UnreadNotificationsCubit>()) sl.unregister<UnreadNotificationsCubit>();
    });

    Widget app() => MaterialApp(
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
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Center(child: Text('Product page'))),
        );

    testWidgets('says what arrived, with a button to open it', (tester) async {
      feed.items = [_n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pumpWidget(app());

      feed.items = [_n('b', productId: 'p1', title: 'Back in stock'), _n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Back in stock'), findsOneWidget);
      expect(find.textContaining('Body b'), findsOneWidget);
      expect(find.text('View details'), findsOneWidget);
    });

    testWidgets('a notification with nothing to open is shown without a button', (tester) async {
      feed.items = [_n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pumpWidget(app());

      feed.items = [_n('b', title: 'Sale'), _n('a')];
      await tester.runAsync(unread.refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Sale'), findsOneWidget);
      expect(find.text('View details'), findsNothing);
    });
  });
}
