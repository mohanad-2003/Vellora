import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Shows [child] as a centred dialog that fades and scales in over a dimmed
/// barrier. Used for short, decisive questions (log out, delete account).
class AppDialog {
  AppDialog._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Dialog(
              backgroundColor: ctx.colors.surface,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, page) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: page,
          ),
        );
      },
    );
  }
}

/// Body for [AppDialog]: a tinted icon badge, a title and message, optional
/// extra [content], and a cancel / confirm button pair.
class ConfirmDialogCard extends StatelessWidget {
  const ConfirmDialogCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.cancelLabel,
    this.confirmIcon,
    this.onCancel,
    this.content,
    this.danger = false,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String cancelLabel;
  final IconData? confirmIcon;

  /// Defaults to closing the dialog.
  final VoidCallback? onCancel;

  /// Extra widget between the message and the buttons (e.g. a password field).
  final Widget? content;

  /// Red tone for destructive actions; the brand colour otherwise.
  final bool danger;

  /// Shows a spinner on the confirm button and locks cancel.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = danger ? colors.error : colors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.12),
            ),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.withValues(alpha: 0.16),
              ),
              child: Icon(icon, size: 26, color: tone),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (content != null) ...[
          const SizedBox(height: AppSpacing.lg),
          content!,
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.outline,
                onPressed: busy
                    ? null
                    : (onCancel ?? () => Navigator.of(context).pop()),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                icon: confirmIcon,
                variant: danger
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                isLoading: busy,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
