import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Configures a shared [Dio] instance with base options + the three
/// interceptors, pointed at the Vellora API.
@lazySingleton
class DioClient {
  DioClient(this._authInterceptor) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.addAll([
        _authInterceptor,
        buildLoggingInterceptor(),
        ErrorInterceptor(),
      ]);
  }

  final AuthInterceptor _authInterceptor;
  late final Dio _dio;

  Dio get dio => _dio;
}
