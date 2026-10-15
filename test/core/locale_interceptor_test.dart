import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/network/interceptors/locale_interceptor.dart';

Future<Map<String, dynamic>> _headersSent(
  String Function() language, {
  Map<String, dynamic> headers = const {},
}) async {
  Map<String, dynamic>? seen;
  final dio = Dio()
    ..interceptors.addAll([
      LocaleInterceptor(language),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seen = Map<String, dynamic>.from(options.headers);
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    ]);
  await dio.get<void>('https://shop.test/notifications', options: Options(headers: headers));
  return seen!;
}

void main() {
  test('every request says which language the app is in, and follows a change', () async {
    var current = 'ar';
    expect((await _headersSent(() => current))['Accept-Language'], 'ar');

    current = 'en';
    expect((await _headersSent(() => current))['Accept-Language'], 'en');
  });

  test('a language a call sets itself is kept', () async {
    final seen = await _headersSent(() => 'ar', headers: {'Accept-Language': 'en'});
    expect(seen['Accept-Language'], 'en');
  });

  test('when no language is known yet the request still goes out', () async {
    final seen = await _headersSent(() => throw StateError('not ready'));
    expect(seen.containsKey('Accept-Language'), isFalse);
  });
}
