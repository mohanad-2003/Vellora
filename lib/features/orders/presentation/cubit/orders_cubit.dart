import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/orders_remote_datasource.dart';
import '../../domain/order_entity.dart';
import '../../../../core/utils/safe_emit.dart';

enum OrdersStatus { loading, loaded, error }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const [],
    this.failureKey,
  });

  final OrdersStatus status;
  final List<OrderEntity> orders;

  /// Why loading failed (an l10n key), when [status] is error.
  final String? failureKey;

  List<OrderEntity> withStatus(OrderStatus? status) => status == null
      ? orders
      : orders.where((o) => o.status == status).toList(growable: false);

  @override
  List<Object?> get props => [status, orders, failureKey];
}

@injectable
class OrdersCubit extends Cubit<OrdersState> with SafeEmit<OrdersState> {
  OrdersCubit(this._remote) : super(const OrdersState());

  final OrdersRemoteDataSource _remote;

  /// Re-reads the list without the loading skeleton (after returning from an
  /// order that may have changed).
  Future<void> refresh() async {
    try {
      final orders = await _remote.getOrders();
      emit(OrdersState(status: OrdersStatus.loaded, orders: orders));
    } catch (_) {
      // Keep showing what is already on screen.
    }
  }

  Future<void> load() async {
    emit(const OrdersState());
    try {
      final orders = await _remote.getOrders();
      emit(OrdersState(status: OrdersStatus.loaded, orders: orders));
    } catch (e) {
      emit(
        OrdersState(
          status: OrdersStatus.error,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
    }
  }
}

/// Loads a single order for the details screen.
enum OrderDetailStatus { loading, loaded, notFound, error }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
    this.failureKey,
  });

  final OrderDetailStatus status;
  final OrderEntity? order;

  /// Why loading failed (an l10n key), when [status] is error.
  final String? failureKey;

  @override
  List<Object?> get props => [status, order, failureKey];
}

@injectable
class OrderDetailCubit extends Cubit<OrderDetailState> with SafeEmit<OrderDetailState> {
  OrderDetailCubit(this._remote) : super(const OrderDetailState());

  final OrdersRemoteDataSource _remote;

  /// Cancels the order. Returns a failure key, or null when it was cancelled.
  Future<String?> cancel() async {
    final order = state.order;
    if (order == null) return 'somethingWentWrong';
    try {
      final updated = await _remote.cancelOrder(order.id);
      emit(OrderDetailState(status: OrderDetailStatus.loaded, order: updated));
      return null;
    } on ValidationException catch (e) {
      // 409: the order moved past "processing" in the meantime.
      return e.code == 'conflict'
          ? 'orderNotCancellable'
          : 'somethingWentWrong';
    } catch (e) {
      return mapExceptionToFailure(e).l10nKey;
    }
  }

  Future<void> load(String id) async {
    emit(const OrderDetailState());
    try {
      final order = await _remote.getOrder(id);
      emit(OrderDetailState(status: OrderDetailStatus.loaded, order: order));
    } on NotFoundException {
      emit(const OrderDetailState(status: OrderDetailStatus.notFound));
    } catch (e) {
      // Offline, a slow server or a signed-out user is not "order not found".
      emit(
        OrderDetailState(
          status: OrderDetailStatus.error,
          failureKey: mapExceptionToFailure(e).l10nKey,
        ),
      );
    }
  }
}
