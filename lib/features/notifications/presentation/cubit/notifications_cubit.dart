import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/mock_notifications.dart';
import '../../domain/notification_entity.dart';

enum NotificationsStatus { loading, loaded }

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

/// Mock-backed notification feed (see [MockNotifications]). Read / dismiss
/// state lives only in memory.
@injectable
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(const NotificationsState());

  Future<void> load() async {
    emit(const NotificationsState());
    await Future<void>.delayed(const Duration(milliseconds: 350));
    emit(NotificationsState(
      status: NotificationsStatus.loaded,
      items: MockNotifications.build(DateTime.now()),
    ));
  }

  void markAllRead() => emit(NotificationsState(
        status: NotificationsStatus.loaded,
        items: [
          for (final n in state.items)
            NotificationEntity(
              id: n.id,
              kind: n.kind,
              titleKey: n.titleKey,
              bodyKey: n.bodyKey,
              createdAt: n.createdAt,
            ),
        ],
      ));

  void dismiss(String id) => emit(NotificationsState(
        status: NotificationsStatus.loaded,
        items: state.items.where((n) => n.id != id).toList(),
      ));
}
