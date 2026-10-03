import 'package:equatable/equatable.dart';

enum OrderStatus { processing, shipped, delivered, cancelled }

/// How the order was paid, for display only.
enum OrderPaymentKind { card, paypal, cashOnDelivery }

class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.name,
    required this.imagePath,
    required this.quantity,
    required this.price,
    this.color,
    this.size,
  });

  final String name;
  final String imagePath;
  final int quantity;
  final double price;
  final String? color;
  final String? size;

  double get lineTotal => price * quantity;

  @override
  List<Object?> get props => [name, imagePath, quantity, price, color, size];
}

/// A placed order. Display-oriented snapshot: everything the Orders screens
/// need is captured at order time, so they never depend on live cart or
/// address data.
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    required this.recipient,
    required this.addressLine,
    required this.city,
    required this.paymentKind,
    required this.paymentDetail,
  });

  final String id;

  /// Human-readable number, e.g. `#SH-20418`.
  final String number;
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final String recipient;
  final String addressLine;
  final String city;
  final OrderPaymentKind paymentKind;

  /// e.g. "Visa •••• 4242" (empty for cash on delivery).
  final String paymentDetail;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  OrderEntity copyWith({OrderStatus? status}) => OrderEntity(
    id: id,
    number: number,
    createdAt: createdAt,
    status: status ?? this.status,
    items: items,
    subtotal: subtotal,
    discount: discount,
    shipping: shipping,
    total: total,
    recipient: recipient,
    addressLine: addressLine,
    city: city,
    paymentKind: paymentKind,
    paymentDetail: paymentDetail,
  );

  @override
  List<Object?> get props => [
    id,
    number,
    createdAt,
    status,
    items,
    subtotal,
    discount,
    shipping,
    total,
    recipient,
    addressLine,
    city,
    paymentKind,
    paymentDetail,
  ];
}
