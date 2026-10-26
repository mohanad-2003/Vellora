import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A quiet, bounded stage for the transparent brand illustrations.
class BrandArtwork extends StatelessWidget {
  const BrandArtwork({super.key, required this.imagePath, this.offset = 0});

  final String imagePath;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 430),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF245348),
                    kBrandNavy.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FractionalTranslation(
                  translation: Offset(reduceMotion ? 0 : -offset * 0.04, 0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
