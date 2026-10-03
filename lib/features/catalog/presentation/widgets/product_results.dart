import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_grid.dart';
import '../../../../core/widgets/product_horizontal_card.dart';
import '../../../home/domain/entities/product_entity.dart';
import 'catalog_toolbar.dart';

/// Sliver that renders [products] as a responsive grid or as list rows.
/// Shared by Catalog and Search so both behave identically.
class SliverProductResults extends StatelessWidget {
  const SliverProductResults({
    super.key,
    required this.products,
    required this.viewMode,
    required this.heroPrefix,
    required this.onTap,
    required this.onFavorite,
    this.onAddToCart,
  });

  final List<ProductEntity> products;
  final CatalogViewMode viewMode;
  final String heroPrefix;
  final void Function(ProductEntity product, String heroTag) onTap;
  final void Function(ProductEntity product) onFavorite;
  final void Function(ProductEntity product)? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH);

    if (viewMode == CatalogViewMode.list) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, i) {
            final p = products[i];
            final tag = '${heroPrefix}_${p.id}';
            return ProductHorizontalCard(
              heroTag: tag,
              imageSize: 104,
              imagePath: p.imagePath,
              title: p.name,
              brand: p.brand,
              price: p.price,
              originalPrice: p.originalPrice,
              rating: p.rating,
              reviewCount: p.reviewCount,
              isFavorite: p.isFavorite,
              onTap: () => onTap(p, tag),
              onFavoriteToggle: () => onFavorite(p),
            );
          },
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverProductGrid(
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final tag = '${heroPrefix}_${p.id}';
          return ProductCard(
            heroTag: tag,
            imagePath: p.imagePath,
            title: p.name,
            brand: p.brand,
            price: p.price,
            originalPrice: p.originalPrice,
            rating: p.rating,
            reviewCount: p.reviewCount,
            isFavorite: p.isFavorite,
            onTap: () => onTap(p, tag),
            onFavoriteToggle: () => onFavorite(p),
            onAddToCart:
                onAddToCart == null ? null : () => onAddToCart!(p),
          );
        },
      ),
    );
  }
}
