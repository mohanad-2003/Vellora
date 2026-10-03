import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/favorite_button.dart';
import '../../../../core/widgets/price_widget.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../cart/presentation/bloc/cart_badge_cubit.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../bloc/product_detail_bloc.dart';
import '../widgets/product_actions_bar.dart';
import '../widgets/product_gallery.dart';
import '../widgets/rating_summary.dart';
import '../widgets/related_products_list.dart';
import '../widgets/variant_selector.dart';
import '../widgets/write_review_sheet.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.productId, this.heroTag});

  final String productId;

  /// Tag of the card photo this page was opened from, for the shared-element
  /// transition. Null on deep links.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ProductDetailBloc>()..add(ProductDetailRequested(productId)),
      child: _ProductDetailView(productId: productId, heroTag: heroTag),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.productId, this.heroTag});

  final String productId;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlocConsumer<ProductDetailBloc, ProductDetailState>(
        listenWhen: (prev, curr) =>
            prev.addedToCartTick != curr.addedToCartTick ||
            prev.buyNowTick != curr.buyNowTick,
        listener: (context, state) {
          // Both ticks start at 0 and only ever increase on success.
          if (state.buyNowTick > 0 &&
              state.buyNowTick >= state.addedToCartTick) {
            context.pushNamed(RouteNames.nCheckout);
          } else if (state.addedToCartTick > 0) {
            AppSnackbar.show(
              context,
              message: l10n.addedToCart,
              type: SnackType.success,
              actionLabel: l10n.viewCart,
              onAction: () => context.goNamed(RouteNames.nCart),
            );
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            ProductDetailStatus.loading ||
            ProductDetailStatus.initial => const _DetailSkeleton(),
            ProductDetailStatus.error => Column(
              children: [
                AppBarWidget(title: l10n.productDetails),
                Expanded(
                  child: ErrorStateWidget(
                    message: state.failureKey != null
                        ? tr(context, state.failureKey!)
                        : l10n.somethingWentWrong,
                    onRetry: () => context.read<ProductDetailBloc>().add(
                      ProductDetailRequested(productId),
                    ),
                  ),
                ),
              ],
            ),
            ProductDetailStatus.loaded => _LoadedView(
              state: state,
              heroTag: heroTag,
            ),
          };
        },
      ),
    );
  }
}

/// Skeleton shaped like the loaded page: gallery block, title, price, chips.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return Column(
      children: [
        AppBarWidget(title: context.l10n.productDetails),
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: const AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: ShimmerBox(width: double.infinity),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  ShimmerBox(width: 80, height: 12),
                  SizedBox(height: AppSpacing.md),
                  ShimmerBox(width: 240, height: 22),
                  SizedBox(height: AppSpacing.lg),
                  ShimmerBox(width: 120, height: 14),
                  SizedBox(height: AppSpacing.lg),
                  ShimmerBox(width: 160, height: 28),
                  SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      ShimmerBox(width: 44, height: 44),
                      SizedBox(width: 12),
                      ShimmerBox(width: 44, height: 44),
                      SizedBox(width: 12),
                      ShimmerBox(width: 44, height: 44),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state, this.heroTag});

  final ProductDetailState state;
  final Object? heroTag;

  void _openRelated(BuildContext context, ProductEntity p, String tag) {
    context.pushReplacementNamed(
      RouteNames.nProduct,
      pathParameters: {'id': p.id},
      extra: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!;
    final bloc = context.read<ProductDetailBloc>();

    final actions = ProductActionsBar(
      inStock: detail.inStock,
      onAddToCart: () => bloc.add(const ProductAddToCartRequested()),
      onBuyNow: () => bloc.add(const ProductBuyNowRequested()),
    );

    final wide = context.screenWidth >= Breakpoints.medium;
    if (wide) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ProductGallery(
                          images: detail.gallery,
                          heroTag: heroTag,
                          semanticLabel: detail.product.name,
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _CircleBack(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SafeArea(
                    left: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ).copyWith(top: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _HeaderActions(state: state),
                          ),
                          _InfoSection(state: state),
                          const SizedBox(height: AppSpacing.xxl),
                          _RelatedSection(
                            state: state,
                            onOpen: (p, t) => _openRelated(context, p, t),
                            horizontalPadding: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions,
        ],
      );
    }

    final width = context.screenWidth;
    final galleryHeight = (width * 1.02).clamp(280.0, 460.0);
    final gutter = context.pageGutter;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: galleryHeight,
                backgroundColor: context.colors.surface,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: _CircleBack(),
                ),
                actions: [
                  _HeaderActions(state: state),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: ProductGallery(
                    images: detail.gallery,
                    heroTag: heroTag,
                    semanticLabel: detail.product.name,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.xl,
                    gutter,
                    0,
                  ),
                  child: _InfoSection(state: state),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xxl,
                    bottom: AppSpacing.xxl,
                  ),
                  child: _RelatedSection(
                    state: state,
                    onOpen: (p, t) => _openRelated(context, p, t),
                    horizontalPadding: gutter,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions,
      ],
    );
  }
}

class _CircleBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      iconSize: 18,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(RouteNames.nHome);
        }
      },
    );
  }
}

/// Favorite, share (copy link) and cart shortcuts.
class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = state.detail!.product;
    final bloc = context.read<ProductDetailBloc>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FavoriteButton(
          isFavorite: product.isFavorite,
          onToggle: () => bloc.add(const ProductFavoriteToggled()),
          size: 40,
          floating: false,
        ),
        AppIconButton(
          icon: Icons.ios_share_rounded,
          semanticLabel: l10n.copyLink,
          filled: false,
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: AppConstants.productUrl(product.id)),
            );
            if (context.mounted) {
              AppSnackbar.show(context, message: l10n.linkCopied);
            }
          },
        ),
        BlocBuilder<CartBadgeCubit, int>(
          builder: (context, count) => AppIconButton(
            icon: Icons.shopping_bag_outlined,
            semanticLabel: l10n.cart,
            filled: false,
            onPressed: () => context.goNamed(RouteNames.nCart),
            badge: count > 0 ? CountBadge(count: count) : null,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;
    final detail = state.detail!;
    final product = detail.product;
    final bloc = context.read<ProductDetailBloc>();
    final stockColor = detail.inStock ? context.vellora.success : colors.error;
    final savings = product.hasDiscount
        ? product.originalPrice! - product.price
        : 0.0;

    Widget gap([double h = AppSpacing.xl]) => SizedBox(height: h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: text.labelLarge?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(product.name, style: text.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RatingStars(rating: product.rating, size: 18),
            Text(
              '${product.rating.toStringAsFixed(1)} · ${l10n.reviewsCount(product.reviewCount)}',
              style: text.bodySmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.rSm,
              ),
              child: Text(
                detail.inStock ? l10n.inStock : l10n.outOfStock,
                style: text.labelSmall?.copyWith(
                  color: stockColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        gap(AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PriceWidget(
              price: product.price,
              originalPrice: product.originalPrice,
              large: true,
              color: colors.onSurface,
            ),
            if (product.hasDiscount)
              DiscountBadge.fromPrices(
                price: product.price,
                originalPrice: product.originalPrice!,
                large: true,
              ),
          ],
        ),
        if (savings > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.youSave(savings.toPrice()),
            style: text.bodySmall?.copyWith(color: context.vellora.success),
          ),
        ],
        gap(AppSpacing.lg),
        _ExpandableText(text: detail.description),
        if (detail.variant.colors.isNotEmpty) ...[
          gap(AppSpacing.xxl),
          ColorSwatchSelector(
            label: l10n.selectColor,
            options: detail.variant.colors,
            selected: state.selectedColor,
            onSelected: (c) => bloc.add(ProductColorSelected(c)),
          ),
        ],
        if (detail.variant.sizes.isNotEmpty) ...[
          gap(AppSpacing.xl),
          VariantSelector(
            label: l10n.selectSize,
            options: detail.variant.sizes,
            selected: state.selectedSize,
            onSelected: (s) => bloc.add(ProductSizeSelected(s)),
          ),
        ],
        gap(AppSpacing.xl),
        Row(
          children: [
            Expanded(child: Text(l10n.quantity, style: text.titleMedium)),
            QuantitySelector(
              quantity: state.quantity,
              onChanged: (q) => bloc.add(ProductQuantityChanged(q)),
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              (product.price * state.quantity).toPrice(),
              style: text.titleMedium?.copyWith(color: colors.primary),
            ),
          ],
        ),
        gap(AppSpacing.xxl),
        _PerkRow(
          icon: Icons.local_shipping_outlined,
          title: l10n.perkDeliveryTitle,
          body: l10n.perkDeliveryBody,
        ),
        const SizedBox(height: AppSpacing.md),
        _PerkRow(
          icon: Icons.autorenew_rounded,
          title: l10n.perkReturnsTitle,
          body: l10n.perkReturnsBody,
        ),
        const SizedBox(height: AppSpacing.md),
        _PerkRow(
          icon: Icons.verified_user_outlined,
          title: l10n.perkSecureTitle,
          body: l10n.perkSecureBody,
        ),
        gap(AppSpacing.xxl),
        Semantics(
          header: true,
          child: Text(l10n.reviews, style: text.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        RatingSummary(
          rating: product.rating,
          reviewCount: product.reviewCount,
          reviews: detail.reviews,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.writeReview,
          icon: Icons.rate_review_outlined,
          variant: AppButtonVariant.outline,
          onPressed: () => _writeReview(context),
        ),
      ],
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({
    required this.state,
    required this.onOpen,
    required this.horizontalPadding,
  });

  final ProductDetailState state;
  final void Function(ProductEntity product, String heroTag) onOpen;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (state.related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.relatedProducts,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        ),
        const SizedBox(height: AppSpacing.md),
        RelatedProductsList(
          products: state.related,
          onTap: onOpen,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        ),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: AppRadius.rMd,
          ),
          child: Icon(icon, size: 20, color: context.colors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              Text(body, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Description clamped to three lines with a "Read more" toggle.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textTheme.bodyMedium;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 3,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : 3,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.centerStart,
                ),
                child: Text(_expanded ? l10n.showLess : l10n.readMore),
              ),
          ],
        );
      },
    );
  }
}

/// Opens the review form. The sheet lives outside the page's providers, so the
/// bloc is read first and handed to it.
void _writeReview(BuildContext context) {
  final bloc = context.read<ProductDetailBloc>();
  final l10n = context.l10n;
  AppBottomSheet.show(
    context,
    child: WriteReviewSheet(
      onSubmit: (rating, comment) {
        final result = Completer<String?>();
        bloc.add(
          ProductReviewSubmitted(
            rating: rating,
            comment: comment,
            result: result,
          ),
        );
        return result.future;
      },
      onDone: () {
        Navigator.of(context).pop();
        AppSnackbar.success(context, l10n.reviewAdded);
      },
    ),
  );
}
