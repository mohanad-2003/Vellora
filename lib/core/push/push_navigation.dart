import '../routing/app_router.dart';
import '../routing/route_names.dart';

/// Where a tapped push notification leads: an order, a product, or nowhere.
({String route, String id})? pushTarget(Map<String, String> data) {
  final orderId = data['orderId'];
  if (orderId != null && orderId.isNotEmpty) {
    return (route: RouteNames.nOrderDetails, id: orderId);
  }
  final productId = data['productId'];
  if (productId != null && productId.isNotEmpty) {
    return (route: RouteNames.nProduct, id: productId);
  }
  return null;
}

/// Opens what a tapped notification is about. When the tap started the app the
/// router may not be ready yet, so it waits a moment.
void openFromPush(Map<String, String> data) {
  final target = pushTarget(data);
  if (target == null) return;
  Future<void>.delayed(const Duration(milliseconds: 700), () {
    try {
      AppRouter.router.pushNamed(
        target.route,
        pathParameters: {'id': target.id},
      );
    } catch (_) {}
  });
}
