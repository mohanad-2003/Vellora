import 'package:dio/dio.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_endpoints.dart';

Future<bool> isGamesEnabled() async {
  try {
    final response = await sl<Dio>().get<Map<String, dynamic>>(
      ApiEndpoints.features,
    );
    return response.data?['gamesEnabled'] != false;
  } on DioException {
    // Keep the section available when using an older or unreachable API.
    return true;
  }
}
