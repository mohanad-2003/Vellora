import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_artwork.dart';
import '../../domain/entities/onboarding_page_entity.dart';

const Color kOnboardingNavy = kBrandNavy;

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.page,
    this.bottomInset = 0,
    this.pageOffset = 0,
  });

  final OnboardingPageEntity page;
  final double bottomInset;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final distance = reduceMotion ? 0.0 : pageOffset.abs().clamp(0.0, 1.0);
    final copy = Opacity(
      opacity: (1 - distance).clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: kBrandAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              tr(context, page.titleKey),
              style: context.textTheme.displayLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr(context, page.bodyKey),
            style: context.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFBDCEC8),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > constraints.maxHeight * 1.35;
        final artwork = BrandArtwork(
          imagePath: page.imagePath,
          offset: pageOffset,
        );
        if (wide) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
            child: Row(
              children: [
                Expanded(child: artwork),
                const SizedBox(width: 32),
                Expanded(child: SingleChildScrollView(child: copy)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 8, 28, 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 24 - bottomInset).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: (constraints.maxHeight * 0.56).clamp(120.0, 370.0),
                  child: artwork,
                ),
                const SizedBox(height: 24),
                copy,
              ],
            ),
          ),
        );
      },
    );
  }
}
