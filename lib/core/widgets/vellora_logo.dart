import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/asset_paths.dart';
import '../extensions/context_extensions.dart';

/// Vellora app mark: the "V" tile used as the launcher icon. It carries its
/// own navy-to-violet background, so it reads on light and dark surfaces alike.
///
/// Brand art is never mirrored in RTL.
class VelloraMark extends StatelessWidget {
  const VelloraMark({super.key, this.size = 56, this.glow = false});

  final double size;

  /// Adds a soft gold glow (splash / hero use).
  final bool glow;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      AssetPaths.brandMark,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => _Fallback(size: size),
    );
    if (glow) {
      image = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE9B861).withValues(alpha: 0.28),
              blurRadius: size * 0.45,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: image,
      );
    }
    return Semantics(
      image: true,
      label: AppConstants.appName,
      excludeSemantics: true,
      child: image,
    );
  }
}

/// White "Vellora" wordmark for use over dark imagery or the brand gradient.
class VelloraWordmark extends StatelessWidget {
  const VelloraWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppConstants.appName,
      excludeSemantics: true,
      child: Image.asset(
        AssetPaths.brandWordmarkLight,
        height: height,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Text(
          AppConstants.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: height,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Horizontal Vellora logo (symbol + wordmark).
///
/// Picks the artwork that contrasts with its background: the navy-wordmark
/// version on light themes and the gold-and-white version on dark ones. Set
/// [onDark] to force the dark-surface artwork (e.g. over a photo).
class VelloraLogo extends StatelessWidget {
  const VelloraLogo({super.key, this.height = 44, this.onDark});

  final double height;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? context.isDark;
    return Semantics(
      image: true,
      label: AppConstants.appName,
      excludeSemantics: true,
      child: Image.asset(
        dark ? AssetPaths.brandLogoDark : AssetPaths.brandLogo,
        height: height,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Text(
          AppConstants.appName,
          style: context.textTheme.headlineSmall?.copyWith(
            color: dark ? Colors.white : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1560),
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Text(
        'V',
        style: TextStyle(
          color: const Color(0xFFE9B861),
          fontSize: size * 0.55,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
