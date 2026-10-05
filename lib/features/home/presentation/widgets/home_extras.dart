import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/product_card.dart';
import 'package:vellora/core/widgets/product_grid.dart';
import 'package:vellora/core/widgets/product_image.dart';
import 'package:vellora/core/widgets/section_header.dart';
import 'package:vellora/features/home/domain/entities/brand_entity.dart';
import 'package:vellora/features/home/domain/entities/home_offer_entity.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';

import 'home_sections.dart';

/// Order threshold for free delivery (matches the cart's progress bar).
const double kFreeShippingThreshold = 100;

/// Three shopping promises (free shipping, returns, secure payment) in one
/// quiet card under the banners.
class ValuePropsStrip extends StatelessWidget {
  const ValuePropsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brand = context.vellora;
    final items = [
      (
        Icons.local_shipping_outlined,
        l10n.valueFreeShipping,
        l10n.valueFreeShippingBody(kFreeShippingThreshold.toPrice()),
        context.colors.primary,
      ),
      (
        Icons.autorenew_rounded,
        l10n.valueEasyReturns,
        l10n.valueEasyReturnsBody,
        brand.accent,
      ),
      (
        Icons.verified_user_outlined,
        l10n.valueSecurePayment,
        l10n.valueSecurePaymentBody,
        brand.success,
      ),
    ];

    // Three separate tiles, each tinted with its own colour, so they read as
    // distinct reasons to buy instead of one crowded strip.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ValueProp(
                  icon: items[i].$1,
                  title: items[i].$2,
                  body: items[i].$3,
                  color: items[i].$4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  const _ValueProp({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      label: '$title, $body',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDark ? 0.14 : 0.08),
          borderRadius: AppRadius.rLg,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Coupons for you": ticket-style cards; tapping one copies its code.
class CouponsSection extends StatelessWidget {
  const CouponsSection({super.key, required this.offers});

  final List<HomeOfferEntity> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final height = scaler.scale(96).clamp(96.0, 150.0);
    final width = (MediaQuery.sizeOf(context).width * 0.72).clamp(250.0, 300.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.couponsForYou,
          subtitle: l10n.couponsSubtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => SizedBox(
              width: width,
              child: _CouponCard(offer: offers[i], index: i),
            ),
          ),
        ),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.offer, required this.index});

  final HomeOfferEntity offer;
  final int index;

  static const _palettes = [
    [Color(0xFF4553D8), Color(0xFF7B5CE0)],
    [Color(0xFFFF5A5F), Color(0xFFFF8A5B)],
    [Color(0xFF0E9F8F), Color(0xFF39C29A)],
  ];

  String get _percent {
    final p = offer.discountPercent;
    return p == p.roundToDouble() ? p.toInt().toString() : p.toString();
  }

  Future<void> _copy(BuildContext context) async {
    final message = context.l10n.codeCopied(offer.code);
    await Clipboard.setData(ClipboardData(text: offer.code));
    Haptics.selection();
    if (!context.mounted) return;
    AppSnackbar.show(context, message: message, type: SnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;
    final palette = _palettes[index % _palettes.length];

    return Semantics(
      button: true,
      label: '${l10n.couponOff(_percent)}, ${offer.code}, ${l10n.copyCode}',
      excludeSemantics: true,
      onTap: () => _copy(context),
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _copy(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                // Discount stub.
                Container(
                  width: 92,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: palette,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_percent%',
                          style: text.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.couponOffShort,
                          style: text.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _DashedDivider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.couponCaption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Flexible(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  offer.code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical perforation between a coupon's stub and its body.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.outlineVariant;
    return LayoutBuilder(
      builder: (context, c) {
        final dashes = (c.maxHeight / 8).floor().clamp(0, 40);
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < dashes; i++)
              Container(width: 1.5, height: 4, color: color),
          ],
        );
      },
    );
  }
}

/// "Top brands": round brand portraits with the product count beneath.
class BrandsSection extends StatelessWidget {
  const BrandsSection({super.key, required this.brands, required this.onTap});

  final List<BrandEntity> brands;
  final ValueChanged<BrandEntity> onTap;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    const avatar = 68.0;
    final height = avatar + 12 + scaler.scale(36);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.topBrands, subtitle: l10n.topBrandsSubtitle),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: brands.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, i) => _BrandBubble(
              brand: brands[i],
              size: avatar,
              onTap: () => onTap(brands[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandBubble extends StatelessWidget {
  const _BrandBubble({
    required this.brand,
    required this.size,
    required this.onTap,
  });

  final BrandEntity brand;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final caption = context.l10n.productsCount(brand.productCount);

    return Semantics(
      button: true,
      label: '${brand.name}, $caption',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: SizedBox(
          width: size + 16,
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.primary, context.vellora.accent],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(child: ProductImage(path: brand.imagePath)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                brand.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled sideways rail of product cards (Top rated, Under $25).
class ProductRailSection extends StatelessWidget {
  const ProductRailSection({
    super.key,
    required this.title,
    required this.products,
    required this.actions,
    required this.heroPrefix,
    this.subtitle,
    this.icon,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<ProductEntity> products;
  final ProductActions actions;
  final String heroPrefix;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: onSeeAll != null ? context.l10n.seeAll : null,
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(
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
              titleLines: 1,
              onTap: () => actions.onTap(p, tag),
              onFavoriteToggle: () => actions.onFavorite(p),
              onAddToCart: actions.onAddToCart == null
                  ? null
                  : () => actions.onAddToCart!(p),
            );
          },
        ),
      ],
    );
  }
}

/// Closing card: catalogue totals and a way into Explore.
class CatalogueStatsCard extends StatelessWidget {
  const CatalogueStatsCard({
    super.key,
    required this.productCount,
    required this.brandCount,
    required this.categoryCount,
    required this.onExplore,
  });

  final int productCount;
  final int brandCount;
  final int categoryCount;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;

    Widget stat(int value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            maxLines: 1,
            style: text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          borderRadius: AppRadius.rXl,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B1F5E), Color(0xFF4553D8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.discoverMore,
                style: text.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.discoverMoreBody,
              style: text.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                stat(productCount, l10n.products),
                stat(brandCount, l10n.brands),
                stat(categoryCount, l10n.categories),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B1F5E),
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.rMd,
                ),
              ),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: Text(l10n.browseAll),
            ),
          ],
        ),
      ),
    );
  }
}
