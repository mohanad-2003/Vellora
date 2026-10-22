import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/rating_stars.dart';
import 'package:vellora/features/product/domain/entities/review_entity.dart';

/// Overall rating headline followed by individual reviews.
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });

  final double rating;
  final int reviewCount;
  final List<ReviewEntity> reviews;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: context.textTheme.displaySmall,
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(rating: rating, size: 18),
                const SizedBox(height: 2),
                Text(
                  l10n.reviewsCount(reviewCount),
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        for (final r in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ReviewTile(review: r),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewEntity review;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.primaryContainer,
                child: Text(
                  review.author.characters.first,
                  style: text.labelLarge?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  review.author,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(review.timeAgo, style: text.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RatingStars(rating: review.rating, size: 14),
          const SizedBox(height: AppSpacing.sm),
          Text(review.comment, style: text.bodyMedium),
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _ReviewPhotos(photos: review.photos),
          ],
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ShopReply(reply: review.reply!),
          ],
        ],
      ),
    );
  }
}

/// The shop's answer under a review: a tinted block with the shop's mark, so it reads as the seller
/// speaking and not as another customer.
class _ShopReply extends StatelessWidget {
  const _ShopReply({required this.reply});

  final String reply;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Semantics(
      container: true,
      label: context.l10n.shopReply,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.55),
          borderRadius: AppRadius.rMd,
          border: BorderDirectional(
            start: BorderSide(color: colors.primary, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.shopReply,
                  style: text.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(reply, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// The pictures a reviewer added: small squares that open full screen.
class _ReviewPhotos extends StatelessWidget {
  const _ReviewPhotos({required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final url in photos)
          Semantics(
            button: true,
            image: true,
            label: context.l10n.reviewPhoto,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _PhotoViewer(url: url),
              ),
              borderRadius: AppRadius.rMd,
              child: ClipRRect(
                borderRadius: AppRadius.rMd,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
