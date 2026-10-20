import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/network/server_warmup.dart';

/// Answers every request itself and remembers the paths asked for.
class _Recorder extends Interceptor {
  final paths = <String>[];
  bool fail = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add(options.path);
    if (fail) {
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.unknown),
      );
    } else {
      handler.resolve(Response(requestOptions: options, data: 'pong'));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recorder server;
  late DateTime clock;
  late ServerWarmup warmup;

  setUp(() {
    server = _Recorder();
    clock = DateTime(2026, 1, 1, 12);
    warmup = ServerWarmup(
      dio: Dio()..interceptors.add(server),
      now: () => clock,
    );
  });

  test('pings the lightweight endpoint', () async {
    await warmup.ping();
    expect(server.paths, ['/ping']);
  });

  test('a failed ping is swallowed', () async {
    server.fail = true;
    await warmup.ping();
    expect(server.paths, ['/ping']);
  });

  test('coming back after a long pause pings again', () async {
    await warmup.ping();
    warmup.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock = clock.add(ServerWarmup.idleAfter);
    warmup.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(server.paths.length, 2);
  });

  test('a short pause does not ping', () async {
    await warmup.ping();
    warmup.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock = clock.add(const Duration(minutes: 2));
    warmup.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(server.paths.length, 1);
  });
}
