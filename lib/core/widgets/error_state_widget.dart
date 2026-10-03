import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_button.dart';
import 'empty_state_widget.dart';

/// Error placeholder with a retry action. Shows a friendly [message] — never a
/// raw exception string.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon,
      title: context.l10n.somethingWentWrong,
      message: message,
      actionLabel: onRetry != null ? context.l10n.retry : null,
      onAction: onRetry,
    );
  }
}

/// Re-exported so call sites needing an inline retry button stay consistent.
typedef RetryButton = AppButton;
