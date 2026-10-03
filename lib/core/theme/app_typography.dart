import 'package:flutter/material.dart';

/// Vellora type system: Inter for Latin, Cairo for Arabic, switched by locale.
///
/// Sizes are fixed logical pixels — accessibility scaling comes from the
/// system text scaler, never from screen-size multipliers. Weights are applied
/// through both `fontWeight` and the variable-font `wght` axis so they render
/// identically on every platform.
///
/// Hierarchy (Material slot → role):
/// * display*  – hero / splash / big numbers
/// * headline* – screen titles
/// * title*    – section titles, card titles, app-bar titles
/// * body*     – paragraph and supporting text
/// * label*    – buttons, chips, inputs, captions
class AppTypography {
  AppTypography._();

  static const String latinFamily = 'Inter';
  static const String arabicFamily = 'Cairo';

  static String familyFor(String languageCode) =>
      languageCode == 'ar' ? arabicFamily : latinFamily;

  static TextStyle _s(
    String family,
    double size,
    double weight, {
    required double height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: _weightFor(weight),
      fontVariations: [FontVariation.weight(weight)],
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static FontWeight _weightFor(double w) => switch (w) {
        >= 800 => FontWeight.w800,
        >= 700 => FontWeight.w700,
        >= 600 => FontWeight.w600,
        >= 500 => FontWeight.w500,
        _ => FontWeight.w400,
      };

  /// Builds a Material 3 [TextTheme] for [languageCode].
  ///
  /// [primary] colours headings/titles, [secondary] colours supporting text.
  static TextTheme textTheme({
    required String languageCode,
    required Color primary,
    required Color secondary,
  }) {
    final f = familyFor(languageCode);
    // Arabic glyphs sit lower and need a little more leading.
    final k = languageCode == 'ar' ? 1.1 : 1.0;
    // Latin display sizes track tightly; Arabic must not be letter-spaced.
    final ls = languageCode == 'ar' ? 0.0 : 1.0;

    return TextTheme(
      displayLarge:
          _s(f, 32, 800, height: 1.2 * k, letterSpacing: -0.6 * ls)
              .copyWith(color: primary),
      displayMedium:
          _s(f, 28, 800, height: 1.2 * k, letterSpacing: -0.5 * ls)
              .copyWith(color: primary),
      displaySmall:
          _s(f, 24, 700, height: 1.25 * k, letterSpacing: -0.3 * ls)
              .copyWith(color: primary),
      headlineLarge:
          _s(f, 24, 700, height: 1.25 * k, letterSpacing: -0.3 * ls)
              .copyWith(color: primary),
      headlineMedium:
          _s(f, 22, 700, height: 1.3 * k, letterSpacing: -0.2 * ls)
              .copyWith(color: primary),
      headlineSmall: _s(f, 20, 700, height: 1.3 * k).copyWith(color: primary),
      titleLarge: _s(f, 18, 700, height: 1.35 * k).copyWith(color: primary),
      titleMedium: _s(f, 16, 600, height: 1.4 * k).copyWith(color: primary),
      titleSmall: _s(f, 14, 600, height: 1.4 * k).copyWith(color: primary),
      bodyLarge: _s(f, 16, 400, height: 1.5 * k).copyWith(color: primary),
      bodyMedium: _s(f, 14, 400, height: 1.5 * k).copyWith(color: secondary),
      bodySmall: _s(f, 12.5, 400, height: 1.45 * k).copyWith(color: secondary),
      labelLarge: _s(f, 15, 600, height: 1.3 * k, letterSpacing: 0.1 * ls)
          .copyWith(color: primary),
      labelMedium: _s(f, 13, 600, height: 1.3 * k).copyWith(color: secondary),
      labelSmall: _s(f, 11.5, 500, height: 1.3 * k, letterSpacing: 0.1 * ls)
          .copyWith(color: secondary),
    );
  }
}
