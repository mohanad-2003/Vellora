import 'package:flutter/foundation.dart';

/// The shipping rules the shop currently applies. The defaults are the shop's
/// original rules; the real ones are read from the server (see
/// `DeliveryRemoteDataSource.getOptions`) so the app's estimates agree with
/// what the server charges when the owner changes them.
@immutable
class ShippingRulesData {
  const ShippingRulesData({this.freeThreshold = 100, this.standardFee = 9.99});

  /// A subtotal at or above this ships free (standard delivery).
  final double freeThreshold;
  final double standardFee;

  @override
  bool operator ==(Object other) =>
      other is ShippingRulesData &&
      other.freeThreshold == freeThreshold &&
      other.standardFee == standardFee;

  @override
  int get hashCode => Object.hash(freeThreshold, standardFee);
}

class ShippingRules {
  ShippingRules._();

  static final ValueNotifier<ShippingRulesData> current = ValueNotifier(
    const ShippingRulesData(),
  );

  static void update({
    required double freeThreshold,
    required double standardFee,
  }) {
    current.value = ShippingRulesData(
      freeThreshold: freeThreshold,
      standardFee: standardFee,
    );
  }
}

/// The shop's name and how to reach it, from the server.
@immutable
class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.supportEmail,
    required this.supportPhone,
  });

  final String name;
  final String supportEmail;
  final String supportPhone;
}
