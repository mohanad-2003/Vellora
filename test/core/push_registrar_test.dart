import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/push/push_gateway.dart';
import 'package:vellora/core/push/push_navigation.dart';
import 'package:vellora/core/push/push_registrar.dart';
import 'package:vellora/core/routing/route_names.dart';

class _Gateway implements PushGateway {
  bool available = true;
  bool allowed = true;
  String? current = 'token-one-aaaaaaaaaaaaaaaa';
  final refreshes = StreamController<String>.broadcast();
  final messages = StreamController<Map<String, String>>.broadcast();
  final opened = StreamController<Map<String, String>>.broadcast();
  Map<String, String>? started;
  int permissionAsks = 0;

  @override
  Future<bool> init() async => available;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return allowed;
  }

  @override
  Future<String?> token() async => current;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Stream<Map<String, String>> get onMessage => messages.stream;

  @override
  Stream<Map<String, String>> get onOpened => opened.stream;

  @override
  Future<Map<String, String>?> initialMessage() async => started;
}

/// What the shop sees: every request the registrar sends.
class _Calls {
  final sent = <({String path, Map<String, dynamic> body})>[];
  bool failing = false;

  Dio dio() => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (failing) {
            return handler.reject(
              DioException(requestOptions: options, type: DioExceptionType.connectionError),
            );
          }
          sent.add((path: options.path, body: Map<String, dynamic>.from(options.data as Map)));
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );
}

void main() {
  late _Gateway gateway;
  late _Calls calls;
  late bool signedIn;
  late StreamController<void> session;
  late List<Map<String, String>> opened;
  late int foreground;
  late PushRegistrar registrar;
  late String language;
  late StreamController<void> languageChanges;

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    gateway = _Gateway();
    calls = _Calls();
    signedIn = false;
    session = StreamController<void>.broadcast();
    opened = [];
    foreground = 0;
    language = 'en';
    languageChanges = StreamController<void>.broadcast();
    registrar = PushRegistrar(
      gateway: gateway,
      dio: calls.dio(),
      isSignedIn: () => signedIn,
      sessionChanges: session.stream,
      onOpen: opened.add,
      onForeground: () => foreground++,
      locale: () => language,
      localeChanges: languageChanges.stream,
    );
  });

  tearDown(() async {
    await registrar.dispose();
    await session.close();
    await languageChanges.close();
  });

  test('nobody signed in: nothing is registered, nobody is asked, the shop hears nothing', () async {
    await registrar.start();
    session.add(null);
    await settle();

    expect(calls.sent, isEmpty);
    expect(gateway.permissionAsks, 0);
  });

  test('signing in asks permission and registers this phone', () async {
    await registrar.start();

    signedIn = true;
    session.add(null);
    await settle();

    expect(gateway.permissionAsks, 1);
    expect(calls.sent.single.path, '/devices');
    expect(calls.sent.single.body, {'token': 'token-one-aaaaaaaaaaaaaaaa', 'platform': 'android', 'locale': 'en'});
  });

  test('the phone is registered with the language of the app, and again when the language changes', () async {
    language = 'ar';
    signedIn = true;
    await registrar.start();
    expect(calls.sent.single.body['locale'], 'ar');
    calls.sent.clear();

    language = 'en';
    languageChanges.add(null);
    await settle();
    expect(calls.sent.single.path, '/devices');
    expect(calls.sent.single.body, {'token': 'token-one-aaaaaaaaaaaaaaaa', 'platform': 'android', 'locale': 'en'});
  });

  test('a language change tells the shop nothing when this phone is not registered', () async {
    await registrar.start();
    language = 'ar';
    languageChanges.add(null);
    await settle();

    expect(calls.sent, isEmpty);
  });

  test('already signed in at start: registers at once', () async {
    signedIn = true;
    await registrar.start();

    expect(calls.sent.single.path, '/devices');
  });

  test('if notifications are not allowed nothing is registered', () async {
    gateway.allowed = false;
    signedIn = true;
    await registrar.start();
    await settle();

    expect(calls.sent, isEmpty);
  });

  test('a new address from the service is registered again, but only while signed in', () async {
    signedIn = true;
    await registrar.start();
    calls.sent.clear();

    gateway.refreshes.add('token-two-bbbbbbbbbbbbbbbb');
    await settle();
    expect(calls.sent.single.body['token'], 'token-two-bbbbbbbbbbbbbbbb');

    calls.sent.clear();
    signedIn = false;
    gateway.refreshes.add('token-three-cccccccccccccc');
    await settle();
    expect(calls.sent, isEmpty);
  });

  test('signing out forgets this phone by its address, with no session needed', () async {
    signedIn = true;
    await registrar.start();
    calls.sent.clear();

    signedIn = false;
    session.add(null);
    await settle();

    expect(calls.sent.single.path, '/devices/unregister');
    expect(calls.sent.single.body, {'token': 'token-one-aaaaaaaaaaaaaaaa'});
  });

  test('if this phone was never registered, signing out still forgets its address', () async {
    gateway.allowed = false;
    signedIn = true;
    await registrar.start();
    expect(calls.sent, isEmpty);

    signedIn = false;
    session.add(null);
    await settle();

    expect(calls.sent.single.path, '/devices/unregister');
  });

  test('a tapped notification opens what it is about, also one that started the app', () async {
    gateway.started = {'orderId': 'o-1'};
    await registrar.start();
    expect(opened, [
      {'orderId': 'o-1'},
    ]);

    gateway.opened.add({'productId': 'p-9'});
    await settle();
    expect(opened.last, {'productId': 'p-9'});
  });

  test('a notification while the app is open refreshes the in-app feed', () async {
    await registrar.start();

    gateway.messages.add({'productId': 'p-9'});
    await settle();

    expect(foreground, 1);
  });

  test('without the service, or when the shop is unreachable, nothing breaks', () async {
    gateway.available = false;
    signedIn = true;
    await registrar.start();
    expect(calls.sent, isEmpty);

    final offline = _Calls()..failing = true;
    final other = PushRegistrar(
      gateway: _Gateway(),
      dio: offline.dio(),
      isSignedIn: () => true,
      sessionChanges: const Stream.empty(),
      onOpen: (_) {},
      onForeground: () {},
    );
    await other.start();
    await settle();
    await other.dispose();
  });

  group('where a tapped notification leads', () {
    test('an order, else a product, else nowhere', () {
      expect(pushTarget({'orderId': 'o1', 'productId': 'p1'}), (route: RouteNames.nOrderDetails, id: 'o1'));
      expect(pushTarget({'productId': 'p1'}), (route: RouteNames.nProduct, id: 'p1'));
      expect(pushTarget({'productId': ''}), isNull);
      expect(pushTarget({'kind': 'promo'}), isNull);
      expect(pushTarget({}), isNull);
    });
  });
}
