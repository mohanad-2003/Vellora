import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import 'app_bar_widget.dart';
import 'empty_state_widget.dart';

/// Rendered for reserved routes (wishlist/checkout/orders/…) that ship in a
/// later phase.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: title),
      body: EmptyStateWidget(
        title: context.l10n.comingSoon,
        message: context.l10n.comingSoonBody,
        icon: Icons.rocket_launch_outlined,
        illustration: EmptyArt.comingSoon,
        actionLabel: context.l10n.home,
        onAction: () => context.pop(),
      ),
    );
  }
}
