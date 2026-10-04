import 'package:equatable/equatable.dart';

import 'order_entity.dart';

class PlaceOrderItem extends Equatable {
  const PlaceOrderItem({
    required this.productId,
    required this.quantity,
    this.color,
    this.size,
  });

  final String productId;
  final int quantity;
  final String? color;
  final String? size;

  @override
  List<Object?> get props => [productId, quantity, color, size];
}

/// Everything needed to place an order.
///
/// The API recalculates prices, discount and shipping itself and returns the
/// authoritative order. [preview] is the order as the client computed it; it is
/// only used by the offline mock, which has no server to ask.
class PlaceOrderRequest extends Equatable {
  const PlaceOrderRequest({
    required this.items,
    required this.express,
    required this.recipient,
    required this.addressLine,
    required this.city,
    required this.paymentKind,
    required this.preview,
    required this.idempotencyKey,
    this.promoCode,
    this.phone,
    this.paymentDetail = '',
  });

  final List<PlaceOrderItem> items;
  final bool express;
  final String? promoCode;
  final String recipient;
  final String? phone;
  final String addressLine;
  final String city;
  final OrderPaymentKind paymentKind;
  final String paymentDetail;
  final OrderEntity preview;

  /// Identifies this attempt to place the order. Sent to the API so that a retry
  /// after a timeout returns the order that was already created instead of
  /// creating a second one.
  final String idempotencyKey;

  @override
  List<Object?> get props => [
    items,
    express,
    promoCode,
    recipient,
    phone,
    addressLine,
    city,
    paymentKind,
    paymentDetail,
    preview,
    idempotencyKey,
  ];
}
