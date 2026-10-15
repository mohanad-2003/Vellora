import 'package:equatable/equatable.dart';

/// A coupon the shop lists for shoppers to apply with a tap. Whether it fits
/// the bag (minimum spend, category) is checked when it is applied.
class CouponOfferEntity extends Equatable {
  const CouponOfferEntity({
    required this.code,
    required this.discountPercent,
    this.minSubtotal,
    this.firstOrderOnly = false,
  });

  final String code;
  final double discountPercent;

  /// The bag must be worth at least this much, when set.
  final double? minSubtotal;
  final bool firstOrderOnly;

  @override
  List<Object?> get props => [code, discountPercent, minSubtotal, firstOrderOnly];
}
