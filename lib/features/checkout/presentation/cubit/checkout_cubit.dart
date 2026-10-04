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
import '../../../profile/data/wallet_remote_datasource.dart';
import '../../data/delivery_remote_datasource.dart';
import '../models/checkout_models.dart';
import '../../../../core/utils/safe_emit.dart';

part 'checkout_state.dart';

/// Drives the checkout screen: loads the cart, tracks the chosen address,
/// delivery method and payment method, then places the order through the
/// orders API and empties the bag. Addresses and saved cards come from the
/// signed-in user's account.
@injectable
class CheckoutCubit extends Cubit<CheckoutState> with SafeEmit<CheckoutState> {
  CheckoutCubit(
    this._getCart,
    this._removeItem,
    this._orders,
    this._wallet,
    this._deliveryOptions,
  ) : super(const CheckoutState());

  final GetCartUseCase _getCart;
  final RemoveFromCartUseCase _removeItem;
  final OrdersRemoteDataSource _orders;
  final WalletRemoteDataSource _wallet;
  final DeliveryRemoteDataSource _deliveryOptions;

  PromoCodeEntity? _promo;

  /// [promo] is forwarded from the cart so any applied discount carries over.
  Future<void> load(PromoCodeEntity? promo) async {
    _promo = promo;
    emit(state.copyWith(status: CheckoutStatus.loading));

    final result = await _getCart(const NoParams());
    final items = result.fold<List<CartItemEntity>?>((failure) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          failureKey: failure.l10nKey,
        ),
      );
      return null;
    }, (items) => items);
    if (items == null) return;

    try {
      final book = await _wallet.getAddresses();
      final wallet = await _wallet.getWallet();
      final delivery = await _loadDeliveryOptions();
      final methods = [...wallet.methods, PaymentMethodOption.cashOnDelivery];
      emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          items: items,
          summary: _summaryFor(items, delivery.first),
          addresses: book.addresses,
          selectedAddressId:
              book.defaultId ??
              (book.addresses.isEmpty ? null : book.addresses.first.id),
          paymentMethods: methods,
          selectedPaymentId:
              wallet.defaultId ?? PaymentMethodOption.cashOnDelivery.id,
          deliveryOptions: delivery,
          selectedDeliveryId: delivery.first.id,
        ),
      );
    } catch (e) {
      // Not signed in, or the server cannot be reached.
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
    }
  }

  /// The server's delivery speeds; the built-in ones if it cannot be asked.
  Future<List<DeliveryOption>> _loadDeliveryOptions() async {
    try {
      final options = await _deliveryOptions.getOptions();
      if (options.isNotEmpty) return options;
    } catch (_) {}
    return DeliveryDefaults.options;
  }

  /// Re-reads the addresses and saved cards after the user added one on its own
  /// screen, keeping the current choice when it still exists.
  Future<void> refreshWallet() async {
    if (state.status != CheckoutStatus.ready) return;
    try {
      final book = await _wallet.getAddresses();
      final wallet = await _wallet.getWallet();
      final methods = [...wallet.methods, PaymentMethodOption.cashOnDelivery];
      final keepAddress = book.addresses.any(
        (a) => a.id == state.selectedAddressId,
      );
      final keepPayment = methods.any((m) => m.id == state.selectedPaymentId);
      emit(
        state.copyWith(
          addresses: book.addresses,
          selectedAddressId: keepAddress
              ? state.selectedAddressId
              : (book.defaultId ??
                    (book.addresses.isEmpty ? null : book.addresses.first.id)),
          paymentMethods: methods,
          selectedPaymentId: keepPayment
              ? state.selectedPaymentId
              : (wallet.defaultId ?? PaymentMethodOption.cashOnDelivery.id),
        ),
      );
    } catch (_) {
      // Keep what is on screen; the next place-order attempt reports problems.
    }
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
    final shipping = base.subtotal == 0
        ? 0.0
        : (delivery.flatFee ?? base.shipping);
    return CartSummaryEntity(
      subtotal: base.subtotal,
      discount: base.discount,
      shipping: shipping,
      total: base.subtotal - base.discount + shipping,
      itemCount: base.itemCount,
    );
  }

  void selectAddress(String id) => emit(state.copyWith(selectedAddressId: id));

  void selectPayment(String id) => emit(state.copyWith(selectedPaymentId: id));

  void selectDelivery(String id) {
    final option = state.deliveryOptions.firstWhere(
      (d) => d.id == id,
      orElse: () => state.deliveryOptions.first,
    );
    emit(
      state.copyWith(
        selectedDeliveryId: option.id,
        summary: _summaryFor(state.items, option),
      ),
    );
  }

  Future<void> placeOrder() async {
    if (state.status != CheckoutStatus.ready) return;
    emit(state.copyWith(status: CheckoutStatus.placing));

    if (state.selectedAddress == null) {
      // An order needs somewhere to go.
      emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          failureKey: 'addressRequired',
        ),
      );
      return;
    }

    final OrderEntity order;
    try {
      order = await _orders.placeOrder(_buildRequest());
    } catch (e) {
      // Back to the form with the cart intact so the user can retry.
      emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
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
      paymentDetail: payment.kind == PaymentKind.cashOnDelivery
          ? ''
          : payment.title,
    );
  }

  ShippingAddress? get selectedAddress => state.selectedAddress;
}
