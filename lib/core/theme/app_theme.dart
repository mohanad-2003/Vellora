import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData]. Colours come from [AppColors], type
/// from [AppTypography] (font switches with the active language).
class AppTheme {
  AppTheme._();

  static ThemeData get light => build(Brightness.light, 'en');
  static ThemeData get dark => build(Brightness.dark, 'en');

  static ThemeData forLocale(Brightness brightness, Locale locale) =>
      build(brightness, locale.languageCode);

  static ColorScheme _scheme(bool isDark) {
    if (isDark) {
      return const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: Color(0xFF0E1130),
        primaryContainer: AppColors.primarySoftDark,
        onPrimaryContainer: Color(0xFFD9DCFF),
        secondary: Color(0xFFE7E9F0),
        onSecondary: AppColors.secondary,
        secondaryContainer: AppColors.darkSurfaceVariant,
        onSecondaryContainer: AppColors.darkTextPrimary,
        tertiary: Color(0xFFFF7478),
        onTertiary: Colors.white,
        error: Color(0xFFF2766F),
        onError: Color(0xFF2A0907),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: Color(0xFF6B7280),
        outlineVariant: AppColors.darkDivider,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFFF1F2F6),
        onInverseSurface: AppColors.secondary,
        inversePrimary: AppColors.primary,
        surfaceContainerLowest: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkBackground,
        surfaceContainer: AppColors.darkSurface,
        surfaceContainerHigh: AppColors.darkSurfaceVariant,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
      );
    }
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: Color(0xFF1F2A8C),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightSurfaceVariant,
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: Color(0xFF8A91A0),
      outlineVariant: AppColors.lightDivider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.secondary,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryDark,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurfaceVariant,
      surfaceContainerHigh: AppColors.lightSurfaceVariant,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
    );
  }

  static ThemeData build(Brightness brightness, String languageCode) {
    final isDark = brightness == Brightness.dark;
    final scheme = _scheme(isDark);
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fill =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    final textTheme = AppTypography.textTheme(
      languageCode: languageCode,
      primary: textPrimary,
      secondary: textSecondary,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.rMd);
    const buttonMin = Size(64, 52);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.familyFor(languageCode),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [isDark ? VelloraColors.dark : VelloraColors.light],
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.outlineVariant,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          minimumSize: buttonMin,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMin,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: buttonMin,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 44),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary.withValues(alpha: 0.8),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        disabledBorder: border(Colors.transparent),
        focusedBorder: border(scheme.primary, 1.5),
        errorBorder: border(scheme.error, 1.2),
        focusedErrorBorder: border(scheme.error, 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outline, width: 1.4),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
      tooltipTheme: TooltipThemeData(
        textStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension VelloraThemeX on ThemeData {
  VelloraColors get vellora => extension<VelloraColors>() ?? VelloraColors.light;
}
