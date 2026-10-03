import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/environments.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_mappers.dart';
import '../domain/notification_entity.dart';
import 'mock_notifications.dart';

/// The signed-in user's notification feed.
abstract class NotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markAllRead();
  Future<void> delete(String id);
}

@mockOnly
@LazySingleton(as: NotificationsRemoteDataSource)
class MockNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  @override
  Future<List<NotificationEntity>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MockNotifications.build(DateTime.now());
  }

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> delete(String id) async {}
}

@apiOnly
@LazySingleton(as: NotificationsRemoteDataSource)
class ApiNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  ApiNotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
    );
    return [
      for (final n in res.data!['items'] as List)
        ApiMappers.notification(n as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> markAllRead() async {
    await _dio.post<void>(ApiEndpoints.notificationsReadAll);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>(ApiEndpoints.notification(id));
  }
}
