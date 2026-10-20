import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';

enum SnackType { success, error, info }

final RegExp _rtlLetters = RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

/// The direction a piece of text reads in: right to left when it holds Arabic
/// or Hebrew letters, left to right otherwise. Server messages are English even
/// in the Arabic app, and a full stop or number would otherwise land on the
/// wrong side.

/// Themed floating snackbars. Content is announced to screen readers by the
/// framework's [SnackBar] semantics.
class AppSnackbar {
  AppSnackbar._();

  /// The direction [text] should be laid out in.
  static TextDirection directionOf(String text) =>
      _rtlLetters.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        build(
          context,
          message: message,
          title: title,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      );
  }

  /// Builds the themed snackbar without showing it. Use it to capture the
  /// styling while [context] is still alive when the snackbar has to appear
  /// after the page was replaced (e.g. after signing out).
  static SnackBar build(
    BuildContext context, {
    required String message,
    String? title,
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
    final onColor = type == SnackType.info
        ? context.colors.onInverseSurface
        : Colors.white;

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: onColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    textDirection: directionOf(title),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  message,
                  textDirection: directionOf(message),
                  style: context.textTheme.bodyMedium?.copyWith(color: onColor),
                ),
              ],
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
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.error);
}
