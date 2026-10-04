import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/network/dio_client.dart';
import 'package:vellora/core/network/interceptors/auth_interceptor.dart';
import 'package:vellora/core/network/interceptors/logging_interceptor.dart';
import 'package:vellora/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:vellora/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vellora/features/auth/data/models/user_model.dart';
import 'package:vellora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vellora/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:vellora/features/cart/domain/repositories/cart_repository.dart';
import 'package:vellora/features/product/domain/repositories/favorites_repository.dart';
import 'package:vellora/features/splash/presentation/cubit/splash_cubit.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockFavorites extends Mock implements FavoritesRepository {}

class _MockCart extends Mock implements CartRepository {}

class _SpyBox extends Mock implements Box<dynamic> {}

FavoritesRepository _fakeFavorites() {
  final f = _MockFavorites();
  when(f.clear).thenAnswer((_) async {});
  return f;
}

CartRepository _fakeCart() {
  final c = _MockCart();
  when(c.clearLocal).thenAnswer((_) async {});
  return c;
}

/// Serves canned responses so no network is touched.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _token = 'eyJ.header.PAYLOAD-secret-token-value';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStore = <String, String>{};
  late Directory hiveDir;
  late Box userBox;
  late FlutterSecureStorage storage;
  late AuthLocalDataSourceImpl local;

  setUpAll(() async {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          secureStore[key!] = args['value'] as String;
          return null;
        case 'read':
          return secureStore[key];
        case 'delete':
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });
    hiveDir = await Directory.systemTemp.createTemp('hive_security_test');
    Hive.init(hiveDir.path);
    userBox = await Hive.openBox('security_user_box');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await hiveDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    secureStore.clear();
    await userBox.clear();
    storage = const FlutterSecureStorage();
    local = AuthLocalDataSourceImpl(userBox, storage);
  });

  /// Everything Hive holds, as one string, to search for leaked values.
  String hiveDump() => userBox.toMap().toString();

  const user = UserModel(
    id: 'u1',
    name: 'Sara',
    email: 'sara@test.com',
    phone: '+100',
    token: _token,
  );

  group('token storage', () {
    test('1. the token is never written to Hive', () async {
      await local.cacheUser(user);

      expect(userBox.isNotEmpty, isTrue, reason: 'the profile is cached');
      expect(hiveDump(), isNot(contains(_token)));
      expect(hiveDump().toLowerCase(), isNot(contains('token')));
      expect(user.toJson().containsKey('token'), isFalse);
    });

    test('2. the token lives only in secure storage', () async {
      await local.cacheUser(user);

      expect(secureStore[AppConstants.secureAuthToken], _token);
      final cached = await local.getCachedUser();
      expect(cached?.token, _token, reason: 'attached from secure storage');
      expect(cached?.email, 'sara@test.com');
    });

    test('a token left in Hive by an older version is removed, not trusted',
        () async {
      await userBox.put(
        'current_user',
        jsonEncode({...user.toJson(), 'token': 'legacy-token-in-hive'}),
      );

      // No secure token: the Hive copy must not count as a session.
      expect(await local.getCachedUser(), isNull);
      expect(userBox.isEmpty, isTrue);

      // With a secure token the record is scrubbed and the secure one is used.
      await userBox.put(
        'current_user',
        jsonEncode({...user.toJson(), 'token': 'legacy-token-in-hive'}),
      );
      secureStore[AppConstants.secureAuthToken] = 'real-token';
      final cached = await local.getCachedUser();
      expect(cached?.token, 'real-token');
      expect(hiveDump(), isNot(contains('legacy-token-in-hive')));
    });

    test('clear removes both the profile and the token', () async {
      await local.cacheUser(user);
      await local.clear();
      expect(userBox.isEmpty, isTrue);
      expect(secureStore, isEmpty);
    });
  });

  group('authentication state', () {
    late _MockRemote remote;
    late AuthRepositoryImpl repo;

    setUp(() {
      remote = _MockRemote();
      repo = AuthRepositoryImpl(remote, local, _MockFavorites(), _MockCart());
      when(() => remote.logout(token: any(named: 'token')))
          .thenAnswer((_) async {});
    });

    test('3. a Hive profile without a token is not authenticated', () async {
      await userBox.put('current_user', jsonEncode(user.toJson()));

      final result = await repo.getCachedUser();

      expect(result.getOrElse((_) => throw 'unexpected failure'), isNull);
      expect(userBox.isEmpty, isTrue, reason: 'the planted record is dropped');
    });

    test('4. a guest editing the profile does not become a "local" user',
        () async {
      final result = await repo.updateProfile(
        name: 'Guest',
        email: 'g@test.com',
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('a guest must not get a profile'),
      );
      expect(userBox.isEmpty, isTrue, reason: 'nothing was stored');
      expect(secureStore, isEmpty);
      expect(await local.getCachedUser(), isNull);
    });

    test('a signed-in user can edit the profile', () async {
      await local.cacheUser(user);
      when(() => remote.updateName(name: any(named: 'name')))
          .thenAnswer((_) async {});

      final result =
          await repo.updateProfile(name: 'Sara B', email: 'sara@test.com');

      expect(result.isRight(), isTrue);
      expect((await local.getCachedUser())?.name, 'Sara B');
      expect(hiveDump(), isNot(contains(_token)));
    });

    test('logout clears local data and revokes the token on the server',
        () async {
      await local.cacheUser(user);
      final cart = _MockCart();
      final favorites = _MockFavorites();
      when(cart.clearLocal).thenAnswer((_) async {});
      when(favorites.clear).thenAnswer((_) async {});
      final r = AuthRepositoryImpl(remote, local, favorites, cart);

      expect((await r.logout()).isRight(), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(userBox.isEmpty, isTrue);
      expect(secureStore, isEmpty);
      verify(() => remote.logout(token: _token)).called(1);
    });

    test('logout still works when the server cannot be reached', () async {
      await local.cacheUser(user);
      final cart = _MockCart();
      final favorites = _MockFavorites();
      when(cart.clearLocal).thenAnswer((_) async {});
      when(favorites.clear).thenAnswer((_) async {});
      when(() => remote.logout(token: any(named: 'token')))
          .thenThrow(Exception('offline'));
      final r = AuthRepositoryImpl(remote, local, favorites, cart);

      expect((await r.logout()).isRight(), isTrue);
      expect(secureStore, isEmpty);
    });

    test('changing the password stores the fresh token the server issued',
        () async {
      await local.cacheUser(user);
      when(
        () => remote.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => 'fresh-token');

      final result = await repo.changePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password-1',
      );

      expect(result.isRight(), isTrue);
      expect(secureStore[AppConstants.secureAuthToken], 'fresh-token');
      expect(hiveDump(), isNot(contains('fresh-token')));
    });
  });

  group('splash decision', () {
    late _MockRemote remote;
    late AuthRepositoryImpl repo;

    setUp(() {
      remote = _MockRemote();
      repo = AuthRepositoryImpl(remote, local, _MockFavorites(), _MockCart());
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLanguageSelected: true,
        AppConstants.prefOnboardingSeen: true,
      });
    });

    Future<({SplashDestination? to, _Adapter api})> run(
      ResponseBody Function(RequestOptions) respond,
    ) async {
      final api = _Adapter(respond);
      final dio = DioClient(AuthInterceptor(storage, userBox)).dio
        ..httpClientAdapter = api;
      final cubit = SplashCubit(
        await SharedPreferences.getInstance(),
        GetCachedUserUseCase(repo),
        dio,
      );
      await cubit.decide();
      final to = cubit.state;
      await cubit.close();
      return (to: to, api: api);
    }

    test('3. a profile in Hive without a token goes to login, no request',
        () async {
      await userBox.put('current_user', jsonEncode(user.toJson()));

      final r = await run((_) => _json(200, {}));

      expect(r.to, SplashDestination.login);
      expect(r.api.requests, isEmpty);
    });

    test('a valid session goes home after the server accepts the token',
        () async {
      await local.cacheUser(user);

      final r = await run((_) => _json(200, {'user': {}}));

      expect(r.to, SplashDestination.home);
      expect(r.api.requests.single.path, '/me');
      expect(r.api.requests.single.headers['Authorization'], 'Bearer $_token');
    });

    test('11. a 401 at startup ends the session and goes to login', () async {
      await local.cacheUser(user);

      final r = await run((_) => _json(401, {
            'error': {'code': 'unauthorized', 'message': 'Invalid or expired'},
          }));

      expect(r.to, SplashDestination.login);
      expect(secureStore, isEmpty, reason: 'token cleared');
      expect(userBox.isEmpty, isTrue, reason: 'profile cleared');
    });

    test('offline at startup keeps the session', () async {
      await local.cacheUser(user);

      final r = await run((o) => throw DioException.connectionError(
            requestOptions: o,
            reason: 'offline',
          ));

      expect(r.to, SplashDestination.home);
      expect(secureStore[AppConstants.secureAuthToken], _token);
    });
  });

  group('401 handling', () {
    Dio dioWith(ResponseBody Function(RequestOptions) respond) =>
        DioClient(AuthInterceptor(storage, userBox)).dio
          ..httpClientAdapter = _Adapter(respond);

    test('11. a 401 on an authenticated request wipes the session', () async {
      await local.cacheUser(user);
      final dio = dioWith((_) => _json(401, {
            'error': {'code': 'unauthorized', 'message': 'Invalid or expired'},
          }));

      await expectLater(dio.get<void>('/orders'), throwsA(isA<DioException>()));

      expect(secureStore, isEmpty);
      expect(userBox.isEmpty, isTrue);
    });

    test('a failed login (401, no token sent) leaves other state alone',
        () async {
      await userBox.put('current_user', jsonEncode(user.toJson()));
      final dio = dioWith((_) => _json(401, {
            'error': {'code': 'invalid_credentials', 'message': 'Nope'},
          }));

      await expectLater(
        dio.post<void>('/auth/login', data: {'email': 'a', 'password': 'b'}),
        throwsA(isA<DioException>()),
      );

      expect(userBox.isNotEmpty, isTrue);
    });
  });

  group('logging', () {
    test('10. logs never contain passwords, tokens, codes or Authorization',
        () async {
      await local.cacheUser(user);
      final lines = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..interceptors.addAll([
          AuthInterceptor(storage, userBox),
          buildLoggingInterceptor(enabled: true, sink: lines.add),
        ])
        ..httpClientAdapter = _Adapter((_) => _json(200, {
              'user': {'id': 'u1', 'email': 'sara@test.com'},
              'token': 'response-access-token-value',
              'resetToken': 'response-reset-token-value',
            }));

      await dio.post<void>(
        '/auth/login',
        data: {
          'email': 'sara@test.com',
          'password': 'hunter2-hunter2',
          'newPassword': 'brand-new-secret',
          'currentPassword': 'current-secret',
          'code': '482913',
        },
      );

      final log = lines.join('\n');
      expect(log, isNotEmpty);
      for (final secret in [
        'hunter2-hunter2',
        'brand-new-secret',
        'current-secret',
        '482913',
        'response-access-token-value',
        'response-reset-token-value',
        _token,
        'Bearer',
        'Authorization',
      ]) {
        expect(log, isNot(contains(secret)), reason: '$secret leaked');
      }
      expect(log, contains('***'));
      expect(log, contains('/auth/login'), reason: 'still useful for debugging');
    });

    test('logging is off unless explicitly enabled (profile/release)', () async {
      final lines = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..interceptors.add(buildLoggingInterceptor(enabled: false, sink: lines.add))
        ..httpClientAdapter = _Adapter((_) => _json(200, {}));

      await dio.get<void>('/home');

      expect(lines, isEmpty);
    });
  });
  group('N2: legacy token cleanup in Hive', () {
    const legacyToken = 'LEGACY-JWT-aaaa.bbbb.cccc-should-not-survive';

    Map<String, dynamic> legacyRecord() => {
          ...user.toJson(),
          'token': legacyToken,
        };

    test('compacts once after cleaning a legacy record, never on normal reads',
        () async {
      final box = _SpyBox();
      var stored = jsonEncode(legacyRecord());
      when(() => box.get('current_user')).thenAnswer((_) => stored);
      when(() => box.put('current_user', any<dynamic>())).thenAnswer((i) async {
        stored = i.positionalArguments[1] as String;
      });
      when(() => box.compact()).thenAnswer((_) async {});
      final ds = AuthLocalDataSourceImpl(box, storage);
      secureStore[AppConstants.secureAuthToken] = 'real-token';

      await ds.getCachedUser();
      verify(() => box.compact()).called(1);

      // The record is clean now: further reads do not compact again.
      await ds.getCachedUser();
      await ds.getCachedUser();
      verifyNever(() => box.compact());
    });

    test('does not compact when there is nothing legacy to clean', () async {
      final box = _SpyBox();
      when(() => box.get('current_user'))
          .thenAnswer((_) => jsonEncode(user.toJson()));
      when(() => box.delete('current_user')).thenAnswer((_) async {});
      when(() => box.compact()).thenAnswer((_) async {});
      final ds = AuthLocalDataSourceImpl(box, storage);

      // Profile without a token and without a legacy token: dropped, no compact.
      expect(await ds.getCachedUser(), isNull);
      secureStore[AppConstants.secureAuthToken] = 'real-token';
      expect(await ds.getCachedUser(), isNotNull);

      verifyNever(() => box.compact());
    });

    test('a failing compaction does not break reading the user', () async {
      final box = _SpyBox();
      var stored = jsonEncode(legacyRecord());
      when(() => box.get('current_user')).thenAnswer((_) => stored);
      when(() => box.put('current_user', any<dynamic>())).thenAnswer((i) async {
        stored = i.positionalArguments[1] as String;
      });
      when(() => box.compact()).thenThrow(Exception('disk'));
      secureStore[AppConstants.secureAuthToken] = 'real-token';

      final cached = await AuthLocalDataSourceImpl(box, storage).getCachedUser();

      expect(cached?.token, 'real-token');
      expect(stored, isNot(contains(legacyToken)));
    });

    /// Reads the real file Hive keeps for [name] and reports whether it still
    /// holds [needle] anywhere, including in superseded entries.
    Future<bool> fileContains(String name, String needle) async {
      final bytes = await File('${hiveDir.path}/$name.hive').readAsBytes();
      return latin1.decode(bytes).contains(needle);
    }

    for (final withSession in [true, false]) {
      test(
        'physical file: the old token bytes are gone afterwards '
        '(${withSession ? 'session in secure storage' : 'no session'})',
        () async {
          final name = 'legacy_cleanup_${withSession ? 'a' : 'b'}';
          final box = await Hive.openBox(name);
          // What an old version wrote: the same key, several times.
          await box.put('current_user', jsonEncode(legacyRecord()));
          await box.put('current_user', jsonEncode(legacyRecord()));
          expect(await fileContains(name, legacyToken), isTrue,
              reason: 'sanity: the file really contains the token to begin with');
          if (withSession) secureStore[AppConstants.secureAuthToken] = 'real-token';

          await AuthLocalDataSourceImpl(box, storage).getCachedUser();

          expect(await fileContains(name, legacyToken), isFalse,
              reason: 'the token must not linger in superseded entries');
          expect(box.toMap().toString(), isNot(contains(legacyToken)));
          await box.close();
        },
      );
    }
  });

  group('N3: stale logout 401 must not clear a newer session', () {
    Dio dioWith(ResponseBody Function(RequestOptions) respond) =>
        DioClient(AuthInterceptor(storage, userBox)).dio
          ..httpClientAdapter = _Adapter(respond);

    ResponseBody unauthorized(RequestOptions _) => _json(401, {
          'error': {'code': 'unauthorized', 'message': 'Invalid or expired'},
        });

    test('logout request: its 401 leaves the active session alone', () async {
      // The user signed out, then signed in again before the reply arrived.
      await local.cacheUser(user.copyWith(token: 'NEW-session-token'));
      final adapter = _Adapter(unauthorized);
      final dio = DioClient(AuthInterceptor(storage, userBox)).dio
        ..httpClientAdapter = adapter;

      await expectLater(
        ApiAuthRemoteDataSource(dio).logout(token: 'OLD-session-token'),
        throwsA(isA<DioException>()),
      );

      expect(secureStore[AppConstants.secureAuthToken], 'NEW-session-token');
      expect(userBox.isNotEmpty, isTrue);
      expect(adapter.requests.single.path, '/auth/logout');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer OLD-session-token',
        reason: 'the request must not pick up the new session token',
      );
    });

    test('the flag is what protects it: any other 401 still ends the session',
        () async {
      await local.cacheUser(user);
      final dio = dioWith(unauthorized);

      await expectLater(dio.get<void>('/orders'), throwsA(isA<DioException>()));

      expect(secureStore, isEmpty);
      expect(userBox.isEmpty, isTrue);
    });

    test('the flag only applies to the request that sets it', () async {
      await local.cacheUser(user);
      final dio = dioWith(unauthorized);

      await expectLater(
        dio.get<void>(
          '/orders',
          options: Options(extra: {AuthInterceptor.skipAuthErrorKey: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(secureStore, isNotEmpty, reason: 'skipped for this request');

      await expectLater(dio.get<void>('/wishlist'), throwsA(isA<DioException>()));
      expect(secureStore, isEmpty, reason: 'next request is handled normally');
    });

    test('an explicit Authorization header is not replaced by the stored token',
        () async {
      await local.cacheUser(user.copyWith(token: 'stored-token'));
      final adapter = _Adapter((_) => _json(200, {}));
      final dio = DioClient(AuthInterceptor(storage, userBox)).dio
        ..httpClientAdapter = adapter;

      await dio.get<void>(
        '/x',
        options: Options(headers: {'Authorization': 'Bearer explicit'}),
      );
      await dio.get<void>('/y');

      expect(adapter.requests[0].headers['Authorization'], 'Bearer explicit');
      expect(adapter.requests[1].headers['Authorization'], 'Bearer stored-token');
    });

    test('logout is still best effort: the local session is gone either way',
        () async {
      await local.cacheUser(user);
      final adapter = _Adapter(unauthorized);
      final dio = DioClient(AuthInterceptor(storage, userBox)).dio
        ..httpClientAdapter = adapter;
      final repo = AuthRepositoryImpl(
        ApiAuthRemoteDataSource(dio),
        local,
        _fakeFavorites(),
        _fakeCart(),
      );

      expect((await repo.logout()).isRight(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(secureStore, isEmpty);
      expect(userBox.isEmpty, isTrue);
      expect(adapter.requests.single.path, '/auth/logout');
    });
  });
}
