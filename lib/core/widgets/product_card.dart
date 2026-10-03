import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../utils/haptics.dart';
import 'favorite_button.dart';
import 'price_widget.dart';
import 'product_image.dart';
import 'rating_stars.dart';

/// The shared product tile (Home rails, catalog, search, related, wishlist).
///
/// Deliberately decoupled from any feature entity — it takes primitives — and
/// deliberately flat: the photo is the focus, there is no border or shadow.
///
/// Height is content-driven. When placed in a grid or rail give it a bounded
/// height from [ProductCard.extentFor] so text scaling is honoured.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    this.brand,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.heroTag,
    this.titleLines = 2,
  });

  final String imagePath;
  final String title;
  final double price;
  final String? brand;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  /// When provided, a compact quick-add button is shown beside the price.
  final VoidCallback? onAddToCart;

  /// Shared-element tag for the photo; must be unique on screen.
  final Object? heroTag;
  final int titleLines;

  /// Photo aspect (height / width).
  static const double imageRatio = 1.12;

  /// The height a card of [width] needs under the ambient text scale.
  static double extentFor(
    BuildContext context,
    double width, {
    int titleLines = 2,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final image = width * imageRatio;
    final info = 10 + // gap under photo
        scaler.scale(15) + // brand
        2 +
        scaler.scale(14 * 1.4 * titleLines) + // name
        6 +
        scaler.scale(18) + // rating
        8 +
        scaler.scale(44); // price row (also fits the 36dp add button)
    return image + info;
  }

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        widget.originalPrice != null && widget.originalPrice! > widget.price;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1 / ProductCard.imageRatio,
              child: _buildImage(context, hasDiscount),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildInfo(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool hasDiscount) {
    Widget photo = ProductImage(
      path: widget.imagePath,
      semanticLabel: widget.title,
    );
    if (widget.heroTag != null) {
      photo = Hero(tag: widget.heroTag!, child: photo);
    }

    return ClipRRect(
      borderRadius: AppRadius.rLg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          if (hasDiscount)
            PositionedDirectional(
              top: 8,
              start: 8,
              child: DiscountBadge.fromPrices(
                price: widget.price,
                originalPrice: widget.originalPrice!,
              ),
            ),
          if (widget.onFavoriteToggle != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: FavoriteButton(
                isFavorite: widget.isFavorite,
                onToggle: widget.onFavoriteToggle,
                size: 34,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final hasBrand = widget.brand != null && widget.brand!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBrand)
          Text(
            widget.brand!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall,
          ),
        Text(
          widget.title,
          maxLines: widget.titleLines,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (widget.rating > 0) ...[
          const SizedBox(height: 4),
          RatingBadge(rating: widget.rating, reviewCount: widget.reviewCount),
        ],
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PriceWidget(
                price: widget.price,
                originalPrice: widget.originalPrice,
                color: colors.onSurface,
              ),
            ),
            if (widget.onAddToCart != null)
              _AddButton(
                onTap: () {
                  Haptics.light();
                  widget.onAddToCart!();
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.addToCart,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Material(
            color: context.colors.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: 34,
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
