import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/environments.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/coupon_offer_entity.dart';
import '../../domain/entities/promo_code_entity.dart';

/// Mocked promo validation with a hardcoded code map + simulated delay.
/// Unknown codes throw [ValidationException] to exercise the invalid-code UI.
abstract class PromoDataSource {
  Future<PromoCodeEntity> validate(String code);

  /// The coupons listed for shoppers, biggest discount first.
  Future<List<CouponOfferEntity>> available();
}

@mockOnly
@LazySingleton(as: PromoDataSource)
class MockPromoDataSource implements PromoDataSource {
  static const Map<String, double> _codes = {
    'SAVE10': 10,
    'WELCOME20': 20,
  };

  @override
  Future<PromoCodeEntity> validate(String code) async {
    await Future<void>.delayed(AppConstants.mockShortDelay);
    final normalized = code.trim().toUpperCase();
    final discount = _codes[normalized];
    if (discount == null) {
      throw const ValidationException('Invalid promo code');
    }
    return PromoCodeEntity(code: normalized, discountPercent: discount);
  }

  @override
  Future<List<CouponOfferEntity>> available() async {
    await Future<void>.delayed(AppConstants.mockShortDelay);
    return [
      for (final e in _codes.entries)
        CouponOfferEntity(code: e.key, discountPercent: e.value),
    ];
  }
}

@apiOnly
@LazySingleton(as: PromoDataSource)
class ApiPromoDataSource implements PromoDataSource {
  ApiPromoDataSource(this._dio);

  final Dio _dio;

  @override
  Future<PromoCodeEntity> validate(String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.promoValidate,
      data: {'code': code.trim()},
    );
    return PromoCodeEntity(
      code: res.data!['code'] as String,
      discountPercent: (res.data!['discountPercent'] as num).toDouble(),
    );
  }

  @override
  Future<List<CouponOfferEntity>> available() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.promosAvailable);
    return [
      for (final c in res.data ?? const [])
        CouponOfferEntity(
          code: (c as Map<String, dynamic>)['code'] as String,
          discountPercent: (c['discountPercent'] as num).toDouble(),
          minSubtotal: (c['minSubtotal'] as num?)?.toDouble(),
          firstOrderOnly: c['firstOrderOnly'] as bool? ?? false,
        ),
    ];
  }
}
