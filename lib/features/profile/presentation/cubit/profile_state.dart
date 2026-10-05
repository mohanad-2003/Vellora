part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, loggedOut, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.failureKey,
    this.ordersCount,
    this.activeOrdersCount = 0,
    this.wishlistCount = 0,
  });

  final ProfileStatus status;
  final UserEntity? user;
  final String? failureKey;

  /// All orders on the account; null until loaded (or when signed out).
  final int? ordersCount;

  /// Orders still processing or on their way.
  final int activeOrdersCount;
  final int wishlistCount;

  ProfileState copyWith({
    ProfileStatus? status,
    UserEntity? user,
    String? failureKey,
    int? ordersCount,
    int? activeOrdersCount,
    int? wishlistCount,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      failureKey: failureKey,
      ordersCount: ordersCount ?? this.ordersCount,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      wishlistCount: wishlistCount ?? this.wishlistCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        failureKey,
        ordersCount,
        activeOrdersCount,
        wishlistCount,
      ];
}
