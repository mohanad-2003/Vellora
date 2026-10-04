import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only request/response logging that never prints a credential.
///
/// Headers are not logged at all (that is where `Authorization` lives), and
/// bodies are logged with every sensitive field replaced by `***`: passwords,
/// access/reset tokens and one-time codes. In profile and release builds the
/// interceptor does nothing.
Interceptor buildLoggingInterceptor({
  bool? enabled,
  void Function(String line)? sink,
}) {
  if (!(enabled ?? kDebugMode)) return InterceptorsWrapper();
  return RedactingLogInterceptor(sink: sink ?? debugPrint);
}

class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor({required this.sink});

  final void Function(String line) sink;

  /// Field names (lower-case) whose values are never printed.
  static const _sensitiveKeys = {
    'password',
    'newpassword',
    'currentpassword',
    'token',
    'accesstoken',
    'refreshtoken',
    'resettoken',
    'code',
    'otp',
    'devcode',
    'authorization',
    'cookie',
    'set-cookie',
  };

  /// A copy of [value] with sensitive fields masked, at any depth.
  static Object? redact(Object? value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          e.key: _sensitiveKeys.contains('${e.key}'.toLowerCase())
              ? '***'
              : redact(e.value),
      };
    }
    if (value is List) return value.map(redact).toList();
    return value;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    sink('--> ${options.method} ${options.uri} ${redact(options.data) ?? ''}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    sink(
      '<-- ${response.statusCode} ${response.requestOptions.uri} '
      '${redact(response.data) ?? ''}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    sink(
      '<-- ERROR ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.uri} ${redact(err.response?.data) ?? ''}',
    );
    handler.next(err);
  }
}
