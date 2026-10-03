import '../../features/home/domain/entities/banner_entity.dart';
import '../../features/home/domain/entities/category_entity.dart';
import '../../features/home/domain/entities/product_entity.dart';
import '../../features/notifications/domain/notification_entity.dart';
import '../../features/orders/domain/order_entity.dart';
import '../../features/product/domain/entities/review_entity.dart';

/// JSON → domain mappers for the Vellora API payloads. Kept in one place so the
/// datasources stay thin and the wire format is easy to audit.
///
/// Image fields arrive as absolute URLs and are stored in the entities'
/// `imagePath`, which `ProductImage` already renders for both assets and URLs.
class ApiMappers {
  ApiMappers._();

  static ProductEntity product(Map<String, dynamic> j) => ProductEntity(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String,
        imagePath: j['imageUrl'] as String,
        price: (j['price'] as num).toDouble(),
        originalPrice: (j['originalPrice'] as num?)?.toDouble(),
        rating: (j['rating'] as num).toDouble(),
        reviewCount: (j['reviewCount'] as num).toInt(),
        category: j['category'] as String,
      );

  static List<ProductEntity> products(Object? list) => [
        for (final p in (list as List? ?? const []))
          product(p as Map<String, dynamic>),
      ];

  static CategoryEntity category(Map<String, dynamic> j) => CategoryEntity(
        id: j['id'] as String,
        name: j['name'] as String,
        imagePath: j['imageUrl'] as String,
        productCount: (j['productCount'] as num?)?.toInt() ?? 0,
      );

  static BannerEntity banner(Map<String, dynamic> j) => BannerEntity(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        imagePath: j['imageUrl'] as String,
      );

  static ReviewEntity review(Map<String, dynamic> j) => ReviewEntity(
        author: j['author'] as String,
        rating: (j['rating'] as num).toDouble(),
        comment: j['comment'] as String,
        timeAgo: timeAgo(DateTime.parse(j['createdAt'] as String)),
      );

  static NotificationEntity notification(Map<String, dynamic> j) =>
      NotificationEntity(
        id: j['id'] as String,
        kind: switch (j['kind']) {
          'order' => NotificationKind.order,
          'promo' => NotificationKind.promo,
          _ => NotificationKind.system,
        },
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        isUnread: j['isUnread'] as bool? ?? false,
      );

  static OrderEntity order(Map<String, dynamic> j) {
    final address = j['address'] as Map<String, dynamic>;
    final payment = j['payment'] as Map<String, dynamic>;
    return OrderEntity(
      id: j['id'] as String,
      number: j['number'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      status: switch (j['status']) {
        'shipped' => OrderStatus.shipped,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.processing,
      },
      items: [
        for (final i in j['items'] as List)
          OrderItemEntity(
            name: (i as Map<String, dynamic>)['name'] as String,
            imagePath: i['imageUrl'] as String,
            quantity: (i['quantity'] as num).toInt(),
            price: (i['price'] as num).toDouble(),
            color: i['color'] as String?,
            size: i['size'] as String?,
          ),
      ],
      subtotal: (j['subtotal'] as num).toDouble(),
      discount: (j['discount'] as num).toDouble(),
      shipping: (j['shipping'] as num).toDouble(),
      total: (j['total'] as num).toDouble(),
      recipient: address['recipient'] as String,
      addressLine: address['line'] as String,
      city: address['city'] as String,
      paymentKind: switch (payment['kind']) {
        'paypal' => OrderPaymentKind.paypal,
        'cashOnDelivery' => OrderPaymentKind.cashOnDelivery,
        _ => OrderPaymentKind.card,
      },
      paymentDetail: payment['detail'] as String? ?? '',
    );
  }

  /// Compact English relative time for reviews ("3 days ago").
  static String timeAgo(DateTime then, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(then);
    String unit(int n, String word) => '$n $word${n == 1 ? '' : 's'} ago';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return unit(diff.inMinutes, 'minute');
    if (diff.inDays < 1) return unit(diff.inHours, 'hour');
    if (diff.inDays < 7) return unit(diff.inDays, 'day');
    if (diff.inDays < 30) return unit(diff.inDays ~/ 7, 'week');
    if (diff.inDays < 365) return unit(diff.inDays ~/ 30, 'month');
    return unit(diff.inDays ~/ 365, 'year');
  }
}
