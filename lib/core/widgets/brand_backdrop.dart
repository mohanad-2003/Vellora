import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The dark brand canvas behind the cut-out artwork on onboarding and welcome.
///
/// Built only from [kBrandNavy], [AppColors.primary] and [kBrandAccent], so
/// changing the brand colours there recolours every screen that uses it. The
/// artwork itself is transparent and never needs to change.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final lifted = Color.lerp(kBrandNavy, AppColors.primary, 0.18)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lifted, kBrandNavy],
          stops: const [0, 0.8],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // A soft gold light behind the artwork.
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 0.75,
            colors: [
              kBrandAccent.withValues(alpha: 0.035),
              kBrandAccent.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
