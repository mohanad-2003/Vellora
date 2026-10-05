import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/domain/entities/cart_item_entity.dart';
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart';
import '../../features/home/domain/entities/product_entity.dart';
import '../../features/product/domain/usecases/get_product_details_usecase.dart';
import '../di/injection.dart';
import '../extensions/context_extensions.dart';
import '../routing/route_names.dart';
import '../widgets/custom_snackbar.dart';

/// The "add to bag" button on a product card.
///
/// A card has no size or colour to pick, but the shop rejects an order line for
/// a product that has them without one. So the product is looked up first:
/// when it needs a choice, the product page opens so the shopper can make it;
/// otherwise it goes straight into the bag.
Future<void> quickAddToCart(BuildContext context, ProductEntity product) async {
  final l10n = context.l10n;
  final router = GoRouter.of(context);

  final details = await sl<GetProductDetailsUseCase>()(product.id);
  if (!context.mounted) return;

  final detail = details.toNullable();
  if (detail == null) {
    AppSnackbar.error(context, l10n.somethingWentWrong);
    return;
  }

  final variant = detail.variant;
  if (variant.sizes.isNotEmpty || variant.colors.isNotEmpty) {
    router.pushNamed(
      RouteNames.nProduct,
      pathParameters: {'id': product.id},
      extra: 'quick_${product.id}',
    );
    // Navigating clears snackbars, so show the hint once the page is up.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (context.mounted) {
      AppSnackbar.show(context, message: l10n.chooseOptionsFirst);
    }
    return;
  }

  final added = await sl<AddToCartUseCase>()(
    CartItemEntity(
      id: '${product.id}__',
      productId: product.id,
      name: product.name,
      imagePath: product.imagePath,
      price: product.price,
      quantity: 1,
    ),
  );
  if (!context.mounted) return;
  if (added.isLeft()) {
    AppSnackbar.error(context, l10n.somethingWentWrong);
    return;
  }
  AppSnackbar.show(
    context,
    message: l10n.addedToCart,
    type: SnackType.success,
    actionLabel: l10n.viewCart,
    onAction: () => router.goNamed(RouteNames.nCart),
  );
}
