import 'package:equatable/equatable.dart';

import '../../../../core/shipping/shipping_rules.dart';
import 'cart_item_entity.dart';
import 'promo_code_entity.dart';

class CartSummaryEntity extends Equatable {
  const CartSummaryEntity({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    required this.itemCount,
  });

  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final int itemCount;

  factory CartSummaryEntity.from(
    List<CartItemEntity> items,
    PromoCodeEntity? promo,
  ) {
    final subtotal =
        items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final discount =
        promo == null ? 0.0 : subtotal * (promo.discountPercent / 100);
    final rules = ShippingRules.current.value;
    final shipping = subtotal >= rules.freeThreshold || subtotal == 0
        ? 0.0
        : rules.standardFee;
    final total = subtotal - discount + shipping;
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    return CartSummaryEntity(
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: total,
      itemCount: itemCount,
    );
  }

  @override
  List<Object?> get props =>
      [subtotal, discount, shipping, total, itemCount];
}
