import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../domain/entities/onboarding_page_entity.dart';

/// Brand navy the artwork fades into. Onboarding is a brand moment, so it stays
/// dark in both light and dark themes.
const Color kOnboardingNavy = Color(0xFF0B0E2E);

/// One immersive onboarding page: full-bleed artwork, a soft scrim that melts
/// into brand navy, and the copy on top of it. In wide/landscape windows the
/// artwork takes one half and the copy sits in the other.
///
/// The page-level controls (indicator, button) live outside this widget and
/// float above its bottom edge; [bottomInset] reserves their space.
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

    // Lifted ~7% so the podium sits clear of the copy; the navy backdrop and
    // scrim cover whatever the lift uncovers at the bottom.
    final artwork = FractionalTranslation(
      translation: Offset(-pageOffset * 0.05, -0.07),
      child: Transform.scale(
        scale: 1.06 - distance * 0.02,
        child: SizedBox.expand(
          child: Image.asset(
            page.imagePath,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.35),
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const ColoredBox(color: kOnboardingNavy),
          ),
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

        if (landscape) {
          return Row(
            children: [
              Expanded(child: ClipRect(child: artwork)),
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

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: artwork),
            // Scrim: clear over the artwork, solid navy behind the copy.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xE60B0E2E),
                    kOnboardingNavy,
                  ],
                  stops: [0, 0.18, 0.5, 0.78, 0.92],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: copy,
              ),
            ),
          ],
        );
      },
    );
  }
}
