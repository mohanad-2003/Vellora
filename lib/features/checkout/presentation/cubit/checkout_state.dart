part of 'checkout_cubit.dart';

enum CheckoutStatus { loading, ready, placing, success, error }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.loading,
    this.items = const [],
    this.summary,
    this.addresses = const [],
    this.selectedAddressId,
    this.paymentMethods = const [],
    this.selectedPaymentId,
    this.deliveryOptions = const [],
    this.selectedDeliveryId,
    this.order,
    this.failureKey,
  });

  final CheckoutStatus status;
  final List<CartItemEntity> items;
  final CartSummaryEntity? summary;
  final List<ShippingAddress> addresses;
  final String? selectedAddressId;
  final List<PaymentMethodOption> paymentMethods;
  final String? selectedPaymentId;
  final List<DeliveryOption> deliveryOptions;
  final String? selectedDeliveryId;

  /// The order that was just placed (set on [CheckoutStatus.success]).
  final OrderEntity? order;
  final String? failureKey;

  ShippingAddress? get selectedAddress {
    for (final a in addresses) {
      if (a.id == selectedAddressId) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  DeliveryOption? get selectedDelivery {
    for (final d in deliveryOptions) {
      if (d.id == selectedDeliveryId) return d;
    }
    return deliveryOptions.isEmpty ? null : deliveryOptions.first;
  }

  PaymentMethodOption? get selectedPayment {
    for (final p in paymentMethods) {
      if (p.id == selectedPaymentId) return p;
    }
    return paymentMethods.isEmpty ? null : paymentMethods.first;
  }

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<CartItemEntity>? items,
    CartSummaryEntity? summary,
    List<ShippingAddress>? addresses,
    String? selectedAddressId,
    List<PaymentMethodOption>? paymentMethods,
    String? selectedPaymentId,
    List<DeliveryOption>? deliveryOptions,
    String? selectedDeliveryId,
    OrderEntity? order,
    String? failureKey,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentId: selectedPaymentId ?? this.selectedPaymentId,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      selectedDeliveryId: selectedDeliveryId ?? this.selectedDeliveryId,
      order: order ?? this.order,
      failureKey: failureKey,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        summary,
        addresses,
        selectedAddressId,
        paymentMethods,
        selectedPaymentId,
        deliveryOptions,
        selectedDeliveryId,
        order,
        failureKey,
      ];
}
