import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../utils/haptics.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

/// The single button used across the app: theme-driven, with loading state,
/// optional leading/trailing icon and optional haptic confirmation.
///
/// The label wraps (up to two lines) instead of shrinking, so it stays legible
/// at large text scales and with longer Arabic copy.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.haptic = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;

  /// Fires a light haptic when pressed. Reserve for committing actions.
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    VoidCallback? handler;
    if (enabled) {
      handler = () {
        if (haptic) Haptics.light();
        onPressed!();
      };
    }

    final foreground = switch (variant) {
      AppButtonVariant.primary => colors.onPrimary,
      AppButtonVariant.secondary => colors.onPrimaryContainer,
      AppButtonVariant.outline => colors.onSurface,
      AppButtonVariant.text => colors.primary,
      AppButtonVariant.danger => colors.onError,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20),
        ],
      ],
    );

    // Keep the label in the tree (hidden) while loading so the button does not
    // change size.
    final child = isLoading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: content),
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(foreground),
                ),
              ),
            ],
          )
        : content;

    const shape = RoundedRectangleBorder(borderRadius: AppRadius.rMd);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: handler,
        style: isLoading
            ? ElevatedButton.styleFrom(
                disabledBackgroundColor: colors.primary,
                disabledForegroundColor: colors.onPrimary,
              )
            : null,
        child: child,
      ),
      AppButtonVariant.secondary => ElevatedButton(
        onPressed: handler,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          disabledBackgroundColor: colors.primaryContainer,
          disabledForegroundColor: colors.onPrimaryContainer,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: handler,
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: handler,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: colors.onError,
          disabledBackgroundColor: isLoading ? colors.error : null,
          disabledForegroundColor: isLoading ? colors.onError : null,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: handler, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Filled brand button — the main call to action on a screen.
class PrimaryButton extends AppButton {
  const PrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.trailingIcon,
    super.expand,
    super.haptic,
  }) : super(variant: AppButtonVariant.primary);
}

/// Soft / outlined secondary action.
class SecondaryButton extends AppButton {
  const SecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.trailingIcon,
    super.expand,
    super.haptic,
    bool outlined = true,
  }) : super(
         variant: outlined
             ? AppButtonVariant.outline
             : AppButtonVariant.secondary,
       );
}
