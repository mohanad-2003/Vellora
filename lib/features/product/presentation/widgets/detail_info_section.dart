import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/custom_bottom_sheet.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/price_widget.dart';
import 'package:vellora/core/widgets/quantity_selector.dart';
import 'package:vellora/core/widgets/rating_stars.dart';
import 'package:vellora/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:vellora/features/product/presentation/widgets/rating_summary.dart';
import 'package:vellora/features/product/presentation/widgets/variant_selector.dart';
import 'package:vellora/features/product/presentation/widgets/write_review_sheet.dart';

class DetailInfoSection extends StatelessWidget {
  const DetailInfoSection({super.key, required this.state});

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
              max: AppConstants.maxLineQuantity,
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
            color: context.colors.primary.withValues(alpha: 0.14),
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
      onSubmit: (rating, comment, photos) {
        final result = Completer<String?>();
        bloc.add(
          ProductReviewSubmitted(
            rating: rating,
            comment: comment,
            photos: photos,
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

