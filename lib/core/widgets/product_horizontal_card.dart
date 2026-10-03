import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import 'favorite_button.dart';
import 'price_widget.dart';
import 'product_image.dart';
import 'rating_stars.dart';

/// Compact list-style product row: square photo on the start side, details on
/// the end. Used for ranked lists (Best Sellers) and search results in list
/// mode.
class ProductHorizontalCard extends StatelessWidget {
  const ProductHorizontalCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    this.brand,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.rank,
    this.onTap,
    this.onFavoriteToggle,
    this.heroTag,
    this.imageSize = 88,
  });

  final String imagePath;
  final String title;
  final double price;
  final String? brand;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final bool isFavorite;

  /// 1-based rank badge drawn on the photo (Best Sellers).
  final int? rank;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final Object? heroTag;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    Widget photo = ProductImage(path: imagePath, semanticLabel: title);
    if (heroTag != null) photo = Hero(tag: heroTag!, child: photo);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: imageSize),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: imageSize,
              child: ClipRRect(
                borderRadius: AppRadius.rMd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo,
                    if (rank != null)
                      PositionedDirectional(
                        top: 0,
                        start: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.secondary,
                            borderRadius: const BorderRadiusDirectional.only(
                              bottomEnd: Radius.circular(AppRadius.sm),
                            ),
                          ),
                          child: Text(
                            '#$rank',
                            style: text.labelSmall?.copyWith(
                              color: context.colors.onSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand != null && brand!.isNotEmpty)
                    Text(
                      brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall,
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    RatingBadge(rating: rating, reviewCount: reviewCount),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: PriceWidget(
                          price: price,
                          originalPrice: originalPrice,
                        ),
                      ),
                      if (onFavoriteToggle != null)
                        FavoriteButton(
                          isFavorite: isFavorite,
                          onToggle: onFavoriteToggle,
                          size: 32,
                          floating: false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
