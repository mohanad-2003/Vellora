import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/notifications_remote_datasource.dart';
import '../../domain/notification_entity.dart';
import '../../../../core/utils/safe_emit.dart';

enum NotificationsStatus { loading, loaded, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
  });

  final NotificationsStatus status;
  final List<NotificationEntity> items;

  bool get hasUnread => items.any((n) => n.isUnread);

  @override
  List<Object?> get props => [status, items];
}

/// Number of unread notifications, for the dot on Home's bell. Kept in sync by
/// [NotificationsCubit] and refreshed by Home.
@lazySingleton
class UnreadNotificationsCubit extends Cubit<int> with SafeEmit<int> {
  UnreadNotificationsCubit(this._remote) : super(0);

  final NotificationsRemoteDataSource _remote;

  /// Silent: a guest or an offline device simply shows no dot.
  Future<void> refresh() async {
    try {
      final items = await _remote.getNotifications();
      emit(items.where((n) => n.isUnread).length);
    } catch (_) {
      emit(0);
    }
  }

  void set(int count) => emit(count);
}

/// Drives the Notifications screen. Read / dismiss changes are applied
/// immediately and sent to the server in the background.
@injectable
class NotificationsCubit extends Cubit<NotificationsState> with SafeEmit<NotificationsState> {
  NotificationsCubit(this._remote, this._unread)
      : super(const NotificationsState());

  final NotificationsRemoteDataSource _remote;
  final UnreadNotificationsCubit _unread;

  Future<void> load() async {
    emit(const NotificationsState());
    try {
      final items = await _remote.getNotifications();
      emit(NotificationsState(
        status: NotificationsStatus.loaded,
        items: items,
      ));
      _unread.set(items.where((n) => n.isUnread).length);
    } catch (_) {
      emit(const NotificationsState(status: NotificationsStatus.error));
    }
  }

  Future<void> markAllRead() async {
    final previous = state;
    emit(NotificationsState(
      status: NotificationsStatus.loaded,
      items: [for (final n in state.items) n.markRead()],
    ));
    _unread.set(0);
    try {
      await _remote.markAllRead();
    } catch (_) {
      emit(previous);
      _unread.set(previous.items.where((n) => n.isUnread).length);
    }
  }

  Future<void> dismiss(String id) async {
    final previous = state;
    final remaining = state.items.where((n) => n.id != id).toList();
    emit(NotificationsState(
      status: NotificationsStatus.loaded,
      items: remaining,
    ));
    _unread.set(remaining.where((n) => n.isUnread).length);
    try {
      await _remote.delete(id);
    } catch (_) {
      emit(previous);
      _unread.set(previous.items.where((n) => n.isUnread).length);
    }
  }
}
