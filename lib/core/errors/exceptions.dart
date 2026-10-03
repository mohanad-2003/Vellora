/// Low-level exceptions thrown by the data layer (datasources / interceptors).
/// Repositories catch these and map them to [Failure]s.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation error', this.code]);

  /// Stable server error code (e.g. `invalid_credentials`), when known.
  final String? code;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized', this.code]);

  final String? code;
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}
