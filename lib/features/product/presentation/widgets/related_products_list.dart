import 'package:flutter/material.dart';
import 'package:vellora/core/widgets/product_card.dart';
import 'package:vellora/core/widgets/product_grid.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';

/// "You may also like" rail on the product page.
class RelatedProductsList extends StatelessWidget {
  const RelatedProductsList({
    super.key,
    required this.products,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final List<ProductEntity> products;
  final void Function(ProductEntity product, String heroTag) onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return ProductRail(
      padding: padding,
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        final tag = 'related_${p.id}';
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
          titleLines: 1,
          onTap: () => onTap(p, tag),
        );
      },
    );
  }
}
