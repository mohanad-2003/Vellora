import 'package:equatable/equatable.dart';

enum NotificationKind { order, promo, system }

/// A user notification. Title/body are l10n keys while the feed is mocked; a
/// real feed will carry server text instead.
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.isUnread = false,
  });

  final String id;
  final NotificationKind kind;
  final String titleKey;
  final String bodyKey;
  final DateTime createdAt;
  final bool isUnread;

  @override
  List<Object?> get props => [id, kind, titleKey, bodyKey, createdAt, isUnread];
}
