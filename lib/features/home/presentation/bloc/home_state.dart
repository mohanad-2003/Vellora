part of 'home_bloc.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.data,
    this.failureKey,
    this.refreshCount = 0,
  });

  final HomeStatus status;
  final HomeDataEntity? data;
  final String? failureKey;

  /// Bumped every time a pull-to-refresh completes, so the UI can await it
  /// even when the reloaded data is identical.
  final int refreshCount;

  HomeState copyWith({
    HomeStatus? status,
    HomeDataEntity? data,
    String? failureKey,
    int? refreshCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      failureKey: failureKey,
      refreshCount: refreshCount ?? this.refreshCount,
    );
  }

  @override
  List<Object?> get props => [status, data, failureKey, refreshCount];
}
