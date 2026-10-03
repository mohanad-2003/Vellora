import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/domain/entities/cart_summary_entity.dart';
import '../../../cart/domain/entities/promo_code_entity.dart';
import '../../../cart/domain/usecases/get_cart_usecase.dart';
import '../../../cart/domain/usecases/remove_from_cart_usecase.dart';
import '../../../orders/data/orders_remote_datasource.dart';
import '../../../orders/domain/order_entity.dart';
import '../../../orders/domain/place_order_request.dart';
import '../models/checkout_models.dart';

part 'checkout_state.dart';

/// Drives the checkout screen: loads the cart, tracks the chosen address,
/// delivery method and payment method, then simulates placing the order —
/// sending it to the orders API and emptying the bag.
@injectable
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._getCart, this._removeItem, this._orders)
      : super(const CheckoutState());

  final GetCartUseCase _getCart;
  final RemoveFromCartUseCase _removeItem;
  final OrdersRemoteDataSource _orders;

  PromoCodeEntity? _promo;

  /// [promo] is forwarded from the cart so any applied discount carries over.
  Future<void> load(PromoCodeEntity? promo) async {
    _promo = promo;
    emit(state.copyWith(status: CheckoutStatus.loading));

    final result = await _getCart(const NoParams());
    result.match(
      (failure) => emit(state.copyWith(
        status: CheckoutStatus.error,
        failureKey: failure.l10nKey,
      )),
      (items) {
        const addresses = CheckoutMockData.addresses;
        const methods = CheckoutMockData.paymentMethods;
        const delivery = CheckoutMockData.deliveryOptions;
        emit(state.copyWith(
          status: CheckoutStatus.ready,
          items: items,
          summary: _summaryFor(items, delivery.first),
          addresses: addresses,
          selectedAddressId: addresses.first.id,
          paymentMethods: methods,
          selectedPaymentId: methods.first.id,
          deliveryOptions: delivery,
          selectedDeliveryId: delivery.first.id,
        ));
      },
    );
  }

  /// Shipping cost of [delivery] for the current cart.
  double shippingFor(DeliveryOption delivery) {
    final base = CartSummaryEntity.from(state.items, _promo);
    return base.subtotal == 0 ? 0.0 : (delivery.flatFee ?? base.shipping);
  }

  CartSummaryEntity _summaryFor(
    List<CartItemEntity> items,
    DeliveryOption delivery,
  ) {
    final base = CartSummaryEntity.from(items, _promo);
    final shipping =
        base.subtotal == 0 ? 0.0 : (delivery.flatFee ?? base.shipping);
    return CartSummaryEntity(
      subtotal: base.subtotal,
      discount: base.discount,
      shipping: shipping,
      total: base.subtotal - base.discount + shipping,
      itemCount: base.itemCount,
    );
  }

  void selectAddress(String id) =>
      emit(state.copyWith(selectedAddressId: id));

  void selectPayment(String id) =>
      emit(state.copyWith(selectedPaymentId: id));

  void selectDelivery(String id) {
    final option = state.deliveryOptions.firstWhere(
      (d) => d.id == id,
      orElse: () => state.deliveryOptions.first,
    );
    emit(state.copyWith(
      selectedDeliveryId: option.id,
      summary: _summaryFor(state.items, option),
    ));
  }

  Future<void> placeOrder() async {
    if (state.status != CheckoutStatus.ready) return;
    emit(state.copyWith(status: CheckoutStatus.placing));

    final OrderEntity order;
    try {
      order = await _orders.placeOrder(_buildRequest());
    } catch (e) {
      // Back to the form with the cart intact so the user can retry.
      emit(state.copyWith(
        status: CheckoutStatus.ready,
        failureKey: mapExceptionToFailure(e).l10nKey,
      ));
      return;
    }

    // Empty the bag now that the order is confirmed.
    for (final item in state.items) {
      await _removeItem(item.id);
    }

    emit(state.copyWith(status: CheckoutStatus.success, order: order));
  }

  PlaceOrderRequest _buildRequest() {
    final address = state.selectedAddress!;
    final preview = _buildOrder();
    return PlaceOrderRequest(
      items: [
        for (final i in state.items)
          PlaceOrderItem(
            productId: i.productId,
            quantity: i.quantity,
            color: i.color,
            size: i.size,
          ),
      ],
      express: state.selectedDelivery?.kind == DeliveryKind.express,
      promoCode: _promo?.code,
      recipient: address.recipient,
      phone: address.phone,
      addressLine: address.line,
      city: address.city,
      paymentKind: preview.paymentKind,
      paymentDetail: preview.paymentDetail,
      preview: preview,
    );
  }

  OrderEntity _buildOrder() {
    final summary = state.summary!;
    final address = state.selectedAddress!;
    final payment = state.selectedPayment!;
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final digits = stamp.toString().padLeft(5, '0');
    return OrderEntity(
      id: 'o-$digits',
      number: '#SH-$digits',
      createdAt: DateTime.now(),
      status: OrderStatus.processing,
      items: [
        for (final i in state.items)
          OrderItemEntity(
            name: i.name,
            imagePath: i.imagePath,
            quantity: i.quantity,
            price: i.price,
            color: i.color,
            size: i.size,
          ),
      ],
      subtotal: summary.subtotal,
      discount: summary.discount,
      shipping: summary.shipping,
      total: summary.total,
      recipient: address.recipient,
      addressLine: address.line,
      city: address.city,
      paymentKind: switch (payment.kind) {
        PaymentKind.card => OrderPaymentKind.card,
        PaymentKind.paypal => OrderPaymentKind.paypal,
        PaymentKind.cashOnDelivery => OrderPaymentKind.cashOnDelivery,
      },
      paymentDetail:
          payment.kind == PaymentKind.cashOnDelivery ? '' : payment.title,
    );
  }

  ShippingAddress? get selectedAddress => state.selectedAddress;
}
