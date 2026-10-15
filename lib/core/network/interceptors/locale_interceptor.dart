import 'package:dio/dio.dart';

/// Tells the shop which language the app is in, so what it writes for the
/// shopper (notifications) comes back in that language.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  /// The app's current language code (`en`, `ar`), read for every request so a
  /// language change applies at once.
  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      options.headers.putIfAbsent('Accept-Language', _languageCode);
    } catch (_) {
      // No language known (very early start-up): the shop answers in English.
    }
    handler.next(options);
  }
}
