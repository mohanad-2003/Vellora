import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_spacing.dart';
import 'product_card.dart';
import 'staggered_reveal.dart';

/// Item builder shared by the grid and rail: gets the index and the width the
/// card will occupy.
typedef ProductItemBuilder = Widget Function(BuildContext context, int index);

/// Responsive sliver grid of [ProductCard]s. Column count follows the width
/// available to the sliver and the row height follows the text scale, so cards
/// never overflow on small phones, large fonts, tablets or landscape.
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisSpacing = AppSpacing.md,
    this.mainAxisSpacing = AppSpacing.xl,
    this.reveal = true,
  });

  final int itemCount;
  final ProductItemBuilder itemBuilder;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// Staggers the first rows in. Off for lists that rebuild often.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = gridColumnsForWidth(constraints.crossAxisExtent);
        final cardWidth = (constraints.crossAxisExtent -
                crossAxisSpacing * (columns - 1)) /
            columns;
        final extent = ProductCard.extentFor(context, cardWidth);
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: extent,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: (context, i) {
            final child = itemBuilder(context, i);
            if (!reveal || i >= columns * 3) return child;
            return StaggeredReveal(
              delay: Duration(milliseconds: (i % columns) * 50 + (i ~/ columns) * 60),
              child: child,
            );
          },
        );
      },
    );
  }
}

/// Horizontally scrolling rail of [ProductCard]s with a content-driven height.
class ProductRail extends StatelessWidget {
  const ProductRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardWidth = 160,
    this.titleLines = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
  });

  final int itemCount;
  final ProductItemBuilder itemBuilder;
  final double cardWidth;
  final int titleLines;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final height =
        ProductCard.extentFor(context, cardWidth, titleLines: titleLines);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) =>
            SizedBox(width: cardWidth, child: itemBuilder(context, i)),
      ),
    );
  }
}
