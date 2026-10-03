import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/favorite_button.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_grid.dart';
import '../../../../core/widgets/product_horizontal_card.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/product_entity.dart';

/// Callbacks shared by every Home product section.
class ProductActions {
  const ProductActions({
    required this.onTap,
    required this.onFavorite,
    this.onAddToCart,
  });

  /// Opens a product; [heroTag] ties the photo to the details page.
  final void Function(ProductEntity product, String heroTag) onTap;
  final void Function(ProductEntity product) onFavorite;
  final void Function(ProductEntity product)? onAddToCart;
}

/// Flash Sale: the page's strongest accent — a tinted panel, a live countdown
/// and a rail of discounted products.
class FlashSaleSection extends StatelessWidget {
  const FlashSaleSection({
    super.key,
    required this.products,
    required this.actions,
    required this.onSeeAll,
  });

  final List<ProductEntity> products;
  final ProductActions actions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final accent = context.vellora.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: context.isDark ? 0.12 : 0.08),
          borderRadius: AppRadius.rXxl,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.flashSale,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                actionLabel: l10n.seeAll,
                onAction: onSeeAll,
                trailing: CountdownTimer.untilEndOfDay(),
              ),
              const SizedBox(height: AppSpacing.md),
              ProductRail(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  final tag = 'home_flash_${p.id}';
                  return _card(p, tag);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(ProductEntity p, String tag) => ProductCard(
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
        onTap: () => actions.onTap(p, tag),
        onFavoriteToggle: () => actions.onFavorite(p),
        onAddToCart:
            actions.onAddToCart == null ? null : () => actions.onAddToCart!(p),
      );
}

/// Featured: large editorial cards — the photo carries the card, copy sits on
/// a scrim at the bottom.
class FeaturedSection extends StatelessWidget {
  const FeaturedSection({
    super.key,
    required this.products,
    required this.actions,
    required this.onSeeAll,
  });

  final List<ProductEntity> products;
  final ProductActions actions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final width = (MediaQuery.sizeOf(context).width * 0.74).clamp(240.0, 320.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.featured,
          subtitle: l10n.featuredSubtitle,
          actionLabel: l10n.seeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: width * 1.22,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final p = products[i];
              final tag = 'home_featured_${p.id}';
              return SizedBox(
                width: width,
                child: _FeaturedCard(
                  product: p,
                  heroTag: tag,
                  onTap: () => actions.onTap(p, tag),
                  onFavorite: () => actions.onFavorite(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.product,
    required this.heroTag,
    required this.onTap,
    required this.onFavorite,
  });

  final ProductEntity product;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      label: '${product.name}, ${product.price.toPrice()}',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.rXl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: ProductImage(
                  path: product.imagePath,
                  fit: BoxFit.cover,
                  padding: EdgeInsets.zero,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 4,
                end: 4,
                child: FavoriteButton(
                  isFavorite: product.isFavorite,
                  onToggle: onFavorite,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand,
                          style: text.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              product.price.toPrice(),
                              style: text.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 8),
                              Text(
                                product.originalPrice!.toPrice(),
                                style: text.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Best Sellers: ranked, list-style rows (two per column) scrolling sideways —
/// deliberately different from the card rails above.
class BestSellersSection extends StatelessWidget {
  const BestSellersSection({
    super.key,
    required this.products,
    required this.actions,
    required this.onSeeAll,
  });

  final List<ProductEntity> products;
  final ProductActions actions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final rowHeight = scaler.scale(118).clamp(100.0, 220.0);
    final columnWidth =
        (MediaQuery.sizeOf(context).width * 0.82).clamp(280.0, 360.0);
    final columns = (products.length / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.bestSellers,
          actionLabel: l10n.seeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: rowHeight * 2 + AppSpacing.lg,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: columns,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xl),
            itemBuilder: (context, col) {
              Widget row(int index) {
                if (index >= products.length) return const SizedBox.shrink();
                final p = products[index];
                final tag = 'home_best_${p.id}';
                return SizedBox(
                  height: rowHeight,
                  child: ProductHorizontalCard(
                    heroTag: tag,
                    rank: index + 1,
                    imagePath: p.imagePath,
                    title: p.name,
                    brand: p.brand,
                    price: p.price,
                    originalPrice: p.originalPrice,
                    rating: p.rating,
                    reviewCount: p.reviewCount,
                    isFavorite: p.isFavorite,
                    onTap: () => actions.onTap(p, tag),
                    onFavoriteToggle: () => actions.onFavorite(p),
                  ),
                );
              }

              return SizedBox(
                width: columnWidth,
                child: Column(
                  children: [
                    row(col * 2),
                    const SizedBox(height: AppSpacing.lg),
                    row(col * 2 + 1),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A titled responsive grid of product cards (New Arrivals, For You). Emits
/// slivers so it composes into the Home scroll view and builds lazily.
class SliverProductSection extends StatelessWidget {
  const SliverProductSection({
    super.key,
    required this.title,
    required this.products,
    required this.actions,
    required this.heroPrefix,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final List<ProductEntity> products;
  final ProductActions actions;
  final String heroPrefix;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SliverToBoxAdapter();
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SectionHeader(
              title: title,
              subtitle: subtitle,
              actionLabel: onSeeAll != null ? context.l10n.seeAll : null,
              onAction: onSeeAll,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
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
                onTap: () => actions.onTap(p, tag),
                onFavoriteToggle: () => actions.onFavorite(p),
                onAddToCart: actions.onAddToCart == null
                    ? null
                    : () => actions.onAddToCart!(p),
              );
            },
          ),
        ),
      ],
    );
  }
}
