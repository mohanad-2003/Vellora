import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/environments.dart';
import '../../../core/network/api_endpoints.dart';
import '../presentation/models/checkout_models.dart';

/// What checkout may offer, from the server so the app and the order total it
/// computes always agree with what the server will accept.
abstract class DeliveryRemoteDataSource {
  /// The delivery speeds the shop offers.
  Future<List<DeliveryOption>> getOptions();

  /// The ways the shop accepts payment right now, or `null` when the server
  /// cannot say (an older server, or no connection): then nothing is hidden and
  /// the server decides when the order is placed.
  Future<Set<PaymentKind>?> getPaymentKinds();
}

@mockOnly
@LazySingleton(as: DeliveryRemoteDataSource)
class MockDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  @override
  Future<List<DeliveryOption>> getOptions() async => DeliveryDefaults.options;

  @override
  Future<Set<PaymentKind>?> getPaymentKinds() async =>
      PaymentKind.values.toSet();
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

  @override
  Future<Set<PaymentKind>?> getPaymentKinds() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentOptions,
      );
      final names = (res.data?['methods'] as List?)?.cast<String>();
      if (names == null) return null;
      return {
        for (final kind in PaymentKind.values)
          if (names.contains(kind.name)) kind,
      };
    } catch (_) {
      return null;
    }
  }

  DeliveryOption _option(Map<String, dynamic> j) => DeliveryOption(
    id: j['id'] as String,
    kind: j['id'] == 'express' ? DeliveryKind.express : DeliveryKind.standard,
    minDays: (j['minDays'] as num).toInt(),
    maxDays: (j['maxDays'] as num).toInt(),
    flatFee: (j['fee'] as num?)?.toDouble(),
  );
}
