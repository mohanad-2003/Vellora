import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_cached_user_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../orders/data/orders_remote_datasource.dart';
import '../../../orders/domain/order_entity.dart';
import '../../../product/domain/usecases/get_favorite_ids_usecase.dart';
import '../../../../core/utils/safe_emit.dart';

part 'profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> with SafeEmit<ProfileState> {
  ProfileCubit(
    this._getCachedUser,
    this._logout,
    this._getFavoriteIds,
    this._orders,
  ) : super(const ProfileState());

  final GetCachedUserUseCase _getCachedUser;
  final LogoutUseCase _logout;
  final GetFavoriteIdsUseCase _getFavoriteIds;
  final OrdersRemoteDataSource _orders;

  Future<void> loadUser() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getCachedUser(const NoParams());
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (user) => emit(
        ProfileState(
          status: ProfileStatus.loaded,
          user: user,
          wishlistCount: _favoriteCount(),
        ),
      ),
    );
    if (state.user != null) await refreshOrders();
  }

  /// Re-reads the favourites count (they change from anywhere in the app).
  void refreshWishlist() =>
      emit(state.copyWith(wishlistCount: _favoriteCount()));

  /// Order totals for the stats row. Signed-in users only; a failure keeps
  /// whatever is already shown.
  Future<void> refreshOrders() async {
    if (state.user == null) return;
    try {
      final orders = await _orders.getOrders();
      emit(
        state.copyWith(
          ordersCount: orders.length,
          activeOrdersCount: orders
              .where(
                (o) =>
                    o.status == OrderStatus.processing ||
                    o.status == OrderStatus.shipped,
              )
              .length,
        ),
      );
    } catch (_) {
      // Stats are a nicety; the page works without them.
    }
  }

  int _favoriteCount() =>
      _getFavoriteIds().getOrElse((_) => <String>{}).length;

  Future<void> logout() async {
    final result = await _logout(const NoParams());
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          failureKey: failure.l10nKey,
        ),
      ),
      (_) => emit(state.copyWith(status: ProfileStatus.loggedOut)),
    );
  }
}
