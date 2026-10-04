import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../localization/l10n_lookup.dart';
import '../routing/route_names.dart';
import 'empty_state_widget.dart';
import 'error_state_widget.dart';

/// Shows why a screen could not load, from the failure key the cubit kept.
///
/// * `pleaseLogin` (the server refused because nobody is signed in) becomes an
///   invitation to sign in, not an error.
/// * No connection and other failures say what happened, with a retry.
class FailureStateView extends StatelessWidget {
  const FailureStateView({super.key, this.failureKey, this.onRetry});

  final String? failureKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = failureKey ?? 'somethingWentWrong';

    if (key == 'pleaseLogin') {
      return EmptyStateWidget(
        icon: Icons.lock_outline_rounded,
        title: l10n.signInRequiredTitle,
        message: l10n.signInRequiredBody,
        actionLabel: l10n.login,
        onAction: () => context.goNamed(RouteNames.nLogin),
      );
    }
    return ErrorStateWidget(
      message: tr(context, key),
      icon: key == 'noConnection' ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      onRetry: onRetry,
    );
  }
}
