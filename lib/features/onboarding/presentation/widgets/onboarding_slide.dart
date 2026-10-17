import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../domain/entities/onboarding_page_entity.dart';

/// Brand colour the slides sit on. Onboarding is a brand moment, so it stays
/// dark in both light and dark themes.
const Color kOnboardingNavy = kBrandNavy;

/// One immersive onboarding page: transparent artwork floating over the brand
/// backdrop, and the copy underneath. In wide/landscape windows the artwork
/// takes one half and the copy sits in the other.
///
/// The artwork is a cut-out (PNG with alpha), so the colours come only from
/// [BrandBackdrop]. The page-level controls (indicator, button) live outside
/// this widget and float above its bottom edge; [bottomInset] reserves their
/// space.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.page,
    required this.bottomInset,
    this.pageOffset = 0,
  });

  final OnboardingPageEntity page;

  /// Height the floating controls occupy at the bottom.
  final double bottomInset;

  /// Distance from the centred page (0 = active, ±1 = a swipe away). Drives a
  /// gentle parallax: the artwork drifts slower than the copy.
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final distance = pageOffset.abs().clamp(0.0, 1.0);
    final text = context.textTheme;

    final artwork = FractionalTranslation(
      translation: Offset(-pageOffset * 0.05, 0),
      child: Transform.scale(
        scale: 1 - distance * 0.04,
        child: Image.asset(
          page.imagePath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );

    final copy = Opacity(
      opacity: (1 - distance * 1.4).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(pageOffset * -60, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                tr(context, page.titleKey),
                style: text.displaySmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, page.bodyKey),
              style: text.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight * 1.15;
        final top = MediaQuery.paddingOf(context).top;

        if (landscape) {
          return Row(
            children: [
              Expanded(
                child: BrandBackdrop(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, top + 24, 24, 24),
                    child: Center(child: ClipRect(child: artwork)),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: kOnboardingNavy,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, 72, 32, bottomInset),
                    child: Center(child: SingleChildScrollView(child: copy)),
                  ),
                ),
              ),
            ],
          );
        }

        return BrandBackdrop(
          child: Column(
            children: [
              // Room above for the logo and the Skip / language pills.
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, top + 64, 28, 12),
                  child: Center(child: artwork),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
                child: copy,
              ),
            ],
          ),
        );
      },
    );
  }
}
