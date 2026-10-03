import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'product_card.dart';
import 'product_grid.dart';

/// Wraps skeleton blocks in a themed shimmer sweep.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vellora = context.vellora;
    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: vellora.skeletonBase,
        highlightColor: vellora.skeletonHighlight,
        child: child,
      ),
    );
  }
}

/// A plain skeleton block. Must live under an [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius});

  final double? width;
  final double? height;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius ?? AppRadius.rMd,
      ),
    );
  }
}

/// Skeleton shaped like a [ProductCard] (photo + three text lines).
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1 / ProductCard.imageRatio,
          child: const ShimmerBox(radius: AppRadius.rLg),
        ),
        const SizedBox(height: 10),
        const ShimmerBox(width: 56, height: 10, radius: AppRadius.rSm),
        const SizedBox(height: 8),
        const ShimmerBox(height: 12, radius: AppRadius.rSm),
        const SizedBox(height: 8),
        const ShimmerBox(width: 90, height: 12, radius: AppRadius.rSm),
      ],
    );
  }
}

/// Placeholder grid used while a product list loads (sliver).
class SliverProductGridSkeleton extends StatelessWidget {
  const SliverProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverProductGrid(
      itemCount: itemCount,
      reveal: false,
      itemBuilder: (_, _) => const AppShimmer(child: ProductCardSkeleton()),
    );
  }
}

/// Non-sliver convenience wrapper with page padding.
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          sliver: SliverProductGridSkeleton(itemCount: itemCount),
        ),
      ],
    );
  }
}

/// Horizontal rail of product skeletons for Home sections.
class HorizontalListShimmer extends StatelessWidget {
  const HorizontalListShimmer({super.key, this.cardWidth = 160});

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return ProductRail(
      itemCount: 4,
      cardWidth: cardWidth,
      itemBuilder: (_, _) => const AppShimmer(child: ProductCardSkeleton()),
    );
  }
}

/// Skeleton for a list row with a thumbnail and two text lines (cart, orders,
/// notifications).
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key, this.thumb = 88});

  final double thumb;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: [
          ShimmerBox(width: thumb, height: thumb, radius: AppRadius.rMd),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, radius: AppRadius.rSm),
                SizedBox(height: 10),
                ShimmerBox(width: 120, height: 12, radius: AppRadius.rSm),
                SizedBox(height: 14),
                ShimmerBox(width: 80, height: 16, radius: AppRadius.rSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical list of [ListRowSkeleton]s.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 5, this.thumb = 88});

  final int itemCount;
  final double thumb;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenH),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
      itemBuilder: (_, _) => ListRowSkeleton(thumb: thumb),
    );
  }
}
