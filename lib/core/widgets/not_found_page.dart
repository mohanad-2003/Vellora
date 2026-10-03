import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../routing/route_names.dart';
import 'empty_state_widget.dart';

/// Shown for unknown routes (bad deep links, removed pages).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.explore_off_outlined,
          title: l10n.pageNotFoundTitle,
          message: l10n.pageNotFoundBody,
          actionLabel: l10n.goHome,
          onAction: () => context.goNamed(RouteNames.nHome),
        ),
      ),
    );
  }
}
