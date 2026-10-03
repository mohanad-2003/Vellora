part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

class HomeFavoriteToggled extends HomeEvent {
  const HomeFavoriteToggled(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class HomeAddToCartRequested extends HomeEvent {
  const HomeAddToCartRequested(this.product);

  final ProductEntity product;

  @override
  List<Object?> get props => [product];
}

/// Another screen changed the favourites; re-mark the hearts.
class HomeFavoritesSynced extends HomeEvent {
  const HomeFavoritesSynced();
}
