import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Row of star icons rendering a fractional rating (0–5).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.count = 5,
  });

  final double rating;
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    final star = context.vellora.star;
    return Semantics(
      label: '${rating.toStringAsFixed(1)} / $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final filled = i + 1 <= rating;
          final half = !filled && i + 0.5 <= rating;
          return Icon(
            half
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            color: star,
            size: size,
            // Stars are symmetric, but half-stars must not mirror in RTL.
            textDirection: TextDirection.ltr,
          );
        }),
      ),
    );
  }
}

/// Compact "★ 4.6 (214)" summary used on cards and headers.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 14,
  });

  final double rating;
  final int reviewCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      label: '${rating.toStringAsFixed(1)} ($reviewCount)',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: size + 2, color: context.vellora.star),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: text.labelMedium?.copyWith(color: context.colors.onSurface),
          ),
          if (reviewCount > 0) ...[
            const SizedBox(width: 3),
            Text('($reviewCount)', style: text.labelSmall),
          ],
        ],
      ),
    );
  }
}
