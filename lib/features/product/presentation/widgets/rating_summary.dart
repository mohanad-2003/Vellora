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
        ],
      ),
    );
  }
}
