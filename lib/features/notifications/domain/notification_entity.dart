import 'package:equatable/equatable.dart';

enum NotificationKind { order, promo, system }

/// A user notification.
///
/// Server notifications carry ready-to-show [title] / [body] text. The mock
/// feed uses l10n keys ([titleKey] / [bodyKey]) instead; [resolveTitle] and
/// [resolveBody] pick whichever is present.
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.title,
    this.body,
    this.titleKey = '',
    this.bodyKey = '',
    this.isUnread = false,
    this.orderId,
  });

  final String id;
  final NotificationKind kind;
  final DateTime createdAt;
  final String? title;
  final String? body;
  final String titleKey;
  final String bodyKey;
  final bool isUnread;

  /// The order this notification is about, when it is an order update.
  final String? orderId;

  NotificationEntity markRead() => NotificationEntity(
    id: id,
    kind: kind,
    createdAt: createdAt,
    title: title,
    body: body,
    titleKey: titleKey,
    bodyKey: bodyKey,
    orderId: orderId,
  );

  String resolveTitle(String Function(String key) tr) => title ?? tr(titleKey);
  String resolveBody(String Function(String key) tr) => body ?? tr(bodyKey);

  @override
  List<Object?> get props => [
    id,
    kind,
    createdAt,
    title,
    body,
    titleKey,
    bodyKey,
    isUnread,
    orderId,
  ];
}
