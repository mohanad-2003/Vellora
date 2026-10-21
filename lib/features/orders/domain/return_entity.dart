import 'package:equatable/equatable.dart';

enum ReturnStatus { requested, approved, rejected, received, completed }

class ReturnItemEntity extends Equatable {
  const ReturnItemEntity({
    required this.orderItemId,
    required this.name,
    required this.quantity,
  });

  final String orderItemId;
  final String name;
  final int quantity;

  @override
  List<Object?> get props => [orderItemId, name, quantity];
}

/// A customer's request to send items of a delivered order back.
class ReturnEntity extends Equatable {
  const ReturnEntity({
    required this.id,
    required this.orderId,
    required this.status,
    required this.reason,
    required this.items,
    required this.createdAt,
    this.adminNote,
  });

  final String id;
  final String orderId;
  final ReturnStatus status;
  final String reason;

  /// What the shop wrote back (the reason for a rejection, or how to send the items).
  final String? adminNote;
  final List<ReturnItemEntity> items;
  final DateTime createdAt;

  /// A rejected return gives its units back to be requested again.
  bool get holdsItems => status != ReturnStatus.rejected;

  @override
  List<Object?> get props => [
    id,
    orderId,
    status,
    reason,
    adminNote,
    items,
    createdAt,
  ];
}

/// Why the customer sends something back. The key is sent to the shop as the reason text.
enum ReturnReason { wrongSize, damaged, notAsDescribed, changedMind, other }
