import '../domain/notification_entity.dart';

/// **Mock data.** There is no notifications backend yet; this static list
/// drives the Notifications screen and the unread dot on Home. Replace the
/// data source (not the UI) when a real feed exists.
class MockNotifications {
  MockNotifications._();

  /// Fixed "now" anchor so grouping (Today / Yesterday / Earlier) is stable.
  static List<NotificationEntity> build(DateTime now) {
    DateTime ago({int days = 0, int hours = 0, int minutes = 0}) =>
        now.subtract(Duration(days: days, hours: hours, minutes: minutes));
    return [
      NotificationEntity(
        id: 'n1',
        kind: NotificationKind.order,
        titleKey: 'notifOrderShippedTitle',
        bodyKey: 'notifOrderShippedBody',
        createdAt: ago(hours: 2),
        isUnread: true,
      ),
      NotificationEntity(
        id: 'n2',
        kind: NotificationKind.promo,
        titleKey: 'notifFlashSaleTitle',
        bodyKey: 'notifFlashSaleBody',
        createdAt: ago(hours: 5),
        isUnread: true,
      ),
      NotificationEntity(
        id: 'n3',
        kind: NotificationKind.order,
        titleKey: 'notifOrderDeliveredTitle',
        bodyKey: 'notifOrderDeliveredBody',
        createdAt: ago(days: 1, hours: 3),
      ),
      NotificationEntity(
        id: 'n4',
        kind: NotificationKind.system,
        titleKey: 'notifWelcomeTitle',
        bodyKey: 'notifWelcomeBody',
        createdAt: ago(days: 4),
      ),
      NotificationEntity(
        id: 'n5',
        kind: NotificationKind.promo,
        titleKey: 'notifNewArrivalsTitle',
        bodyKey: 'notifNewArrivalsBody',
        createdAt: ago(days: 9),
      ),
    ];
  }

  static int get unreadCount =>
      build(DateTime.now()).where((n) => n.isUnread).length;
}
