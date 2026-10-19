import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../cart/domain/entities/cart_item_entity.dart';
import '../../cart/domain/usecases/add_to_cart_usecase.dart';
import '../domain/order_entity.dart';

/// "Order again": puts the order's items back into the bag and opens it.
/// The shop checks stock and prices when the order is placed, so the bag
/// shows today's prices.
Future<void> reorder(BuildContext context, OrderEntity order) async {
  final router = GoRouter.of(context);
  final l10n = context.l10n;
  final add = sl<AddToCartUseCase>();
  var added = 0;
  for (final i in order.items) {
    if (i.productId.isEmpty) continue;
    final result = await add(
      CartItemEntity(
        id: '${i.productId}_${i.color ?? ''}_${i.size ?? ''}',
        productId: i.productId,
        name: i.name,
        imagePath: i.imagePath,
        price: i.price,
        quantity: i.quantity,
        color: i.color,
        size: i.size,
      ),
    );
    if (result.isRight()) added++;
  }
  if (!context.mounted) return;
  if (added == 0) {
    AppSnackbar.error(context, l10n.somethingWentWrong);
    return;
  }
  router.goNamed(RouteNames.nCart);
}
