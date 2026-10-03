import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/orders_remote_datasource.dart';
import '../../domain/order_entity.dart';

enum OrdersStatus { loading, loaded, error }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const [],
  });

  final OrdersStatus status;
  final List<OrderEntity> orders;

  List<OrderEntity> withStatus(OrderStatus? status) => status == null
      ? orders
      : orders.where((o) => o.status == status).toList(growable: false);

  @override
  List<Object?> get props => [status, orders];
}

@injectable
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._remote) : super(const OrdersState());

  final OrdersRemoteDataSource _remote;

  Future<void> load() async {
    emit(const OrdersState());
    try {
      final orders = await _remote.getOrders();
      emit(OrdersState(status: OrdersStatus.loaded, orders: orders));
    } catch (_) {
      emit(const OrdersState(status: OrdersStatus.error));
    }
  }
}

/// Loads a single order for the details screen.
enum OrderDetailStatus { loading, loaded, notFound }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
  });

  final OrderDetailStatus status;
  final OrderEntity? order;

  @override
  List<Object?> get props => [status, order];
}

@injectable
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit(this._remote) : super(const OrderDetailState());

  final OrdersRemoteDataSource _remote;

  Future<void> load(String id) async {
    emit(const OrderDetailState());
    try {
      final order = await _remote.getOrder(id);
      emit(OrderDetailState(status: OrderDetailStatus.loaded, order: order));
    } catch (_) {
      emit(const OrderDetailState(status: OrderDetailStatus.notFound));
    }
  }
}
