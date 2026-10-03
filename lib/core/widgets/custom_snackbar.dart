import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';

enum SnackType { success, error, info }

/// Themed floating snackbars. Content is announced to screen readers by the
/// framework's [SnackBar] semantics.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final vellora = context.vellora;
    final (color, icon) = switch (type) {
      SnackType.success => (vellora.success, Icons.check_circle_rounded),
      SnackType.error => (context.colors.error, Icons.error_rounded),
      SnackType.info => (context.colors.inverseSurface, Icons.info_rounded),
    };
    final onColor =
        type == SnackType.info ? context.colors.onInverseSurface : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: onColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: context.textTheme.bodyMedium?.copyWith(color: onColor),
                ),
              ),
            ],
          ),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: onColor,
                  onPressed: onAction ?? () {},
                )
              : null,
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.error);
}
