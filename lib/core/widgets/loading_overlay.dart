import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Dims the screen and shows a spinner while [isLoading] is true. Wrap a page
/// body to block interaction during a blocking action.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadius.rLg,
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
