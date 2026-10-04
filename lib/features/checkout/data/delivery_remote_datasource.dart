import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/environments.dart';
import '../../../core/network/api_endpoints.dart';
import '../presentation/models/checkout_models.dart';

/// The delivery speeds the shop offers, from the server so the app and the
/// order total it computes always agree.
abstract class DeliveryRemoteDataSource {
  Future<List<DeliveryOption>> getOptions();
}

@mockOnly
@LazySingleton(as: DeliveryRemoteDataSource)
class MockDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  @override
  Future<List<DeliveryOption>> getOptions() async =>
      DeliveryDefaults.options;
}

@apiOnly
@LazySingleton(as: DeliveryRemoteDataSource)
class ApiDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  ApiDeliveryRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<DeliveryOption>> getOptions() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.deliveryOptions,
    );
    final options = <DeliveryOption>[
      for (final raw in res.data!['options'] as List)
        _option(raw as Map<String, dynamic>),
    ];
    return options.isEmpty ? DeliveryDefaults.options : options;
  }

  DeliveryOption _option(Map<String, dynamic> j) => DeliveryOption(
    id: j['id'] as String,
    kind: j['id'] == 'express' ? DeliveryKind.express : DeliveryKind.standard,
    minDays: (j['minDays'] as num).toInt(),
    maxDays: (j['maxDays'] as num).toInt(),
    flatFee: (j['fee'] as num?)?.toDouble(),
  );
}
