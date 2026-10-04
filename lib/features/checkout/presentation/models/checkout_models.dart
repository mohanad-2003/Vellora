import 'package:equatable/equatable.dart';

/// A saved shipping address (stored on the server for the signed-in user).
class ShippingAddress extends Equatable {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.line,
    required this.city,
    required this.phone,
  });

  final String id;

  /// Short tag such as "Home" or "Work".
  final String label;
  final String recipient;
  final String line;
  final String city;
  final String phone;

  @override
  List<Object?> get props => [id, label, recipient, line, city, phone];
}

/// Supported payment rails. Each is shown with a Material icon.
enum PaymentKind { card, paypal, cashOnDelivery }

class PaymentMethodOption extends Equatable {
  const PaymentMethodOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  /// Cash on delivery needs no saved details, so it is always on offer.
  static const PaymentMethodOption cashOnDelivery = PaymentMethodOption(
    id: 'pay_cod',
    kind: PaymentKind.cashOnDelivery,
    title: '',
    subtitle: '',
  );

  final String id;
  final PaymentKind kind;

  /// e.g. `Visa •••• 4242`.
  final String title;

  /// A card's expiry (`08/28`); the tile adds the localized "Expires".
  final String subtitle;

  @override
  List<Object?> get props => [id, kind, title, subtitle];
}

/// How the order is delivered.
enum DeliveryKind { standard, express }

class DeliveryOption extends Equatable {
  const DeliveryOption({
    required this.id,
    required this.kind,
    required this.minDays,
    required this.maxDays,
    this.flatFee,
  });

  final String id;
  final DeliveryKind kind;
  final int minDays;
  final int maxDays;

  /// Fixed fee. Null means "use the cart's standard shipping rule" (free over
  /// the free-shipping threshold).
  final double? flatFee;

  @override
  List<Object?> get props => [id, kind, minDays, maxDays, flatFee];
}

/// Delivery speeds used when the server's list is unavailable (and in the
/// mock environment). Mirrors `GET /delivery-options`.
class DeliveryDefaults {
  DeliveryDefaults._();

  static const List<DeliveryOption> options = [
    DeliveryOption(
      id: 'del_standard',
      kind: DeliveryKind.standard,
      minDays: 3,
      maxDays: 5,
    ),
    DeliveryOption(
      id: 'del_express',
      kind: DeliveryKind.express,
      minDays: 1,
      maxDays: 2,
      flatFee: 14.99,
    ),
  ];
}
