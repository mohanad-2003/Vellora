import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';
import 'package:vellora/core/widgets/shimmer_widgets.dart';
import 'package:vellora/core/widgets/slow_load_hint.dart';

/// Skeleton shaped like the loaded page: gallery block, title, price, chips.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return Column(
      children: [
        AppBarWidget(title: context.l10n.productDetails),
        const SlowLoadHint(),
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
