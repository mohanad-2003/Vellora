import 'package:equatable/equatable.dart';

/// A saved shipping address. Presentation-level mock data — there is no
/// backend in Phase 1, so these are provided by [CheckoutMockData].
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

  final String id;
  final PaymentKind kind;
  final String title;
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

/// Static checkout options standing in for a real account/backend.
class CheckoutMockData {
  CheckoutMockData._();

  static const List<ShippingAddress> addresses = [
    ShippingAddress(
      id: 'addr_home',
      label: 'Home',
      recipient: 'Alex Johnson',
      line: '24 Maple Avenue, Apt 5B',
      city: 'San Francisco, CA 94103',
      phone: '+1 415 555 0142',
    ),
    ShippingAddress(
      id: 'addr_work',
      label: 'Work',
      recipient: 'Alex Johnson',
      line: '900 Market Street, Floor 7',
      city: 'San Francisco, CA 94102',
      phone: '+1 415 555 0199',
    ),
  ];

  static const List<DeliveryOption> deliveryOptions = [
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

  static const List<PaymentMethodOption> paymentMethods = [
    PaymentMethodOption(
      id: 'pay_visa',
      kind: PaymentKind.card,
      title: 'Visa •••• 4242',
      subtitle: 'Expires 08/28',
    ),
    PaymentMethodOption(
      id: 'pay_paypal',
      kind: PaymentKind.paypal,
      title: 'PayPal',
      subtitle: 'alex.johnson@email.com',
    ),
    PaymentMethodOption(
      id: 'pay_cod',
      kind: PaymentKind.cashOnDelivery,
      title: 'Cash on Delivery',
      subtitle: 'Pay when your order arrives',
    ),
  ];
}
