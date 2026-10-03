import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Presents a themed modal bottom sheet with a drag handle.
///
/// The sheet never exceeds 90% of the screen height, scrolls when its content
/// is taller (large text, landscape, keyboard) and stays width-capped on
/// tablets.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    String? title,
    bool scrollable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) =>
          _SheetBody(title: title, scrollable: scrollable, child: child),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.child,
    required this.scrollable,
    this.title,
  });

  final Widget child;
  final String? title;

  /// When false the child manages its own scrolling (e.g. a sticky footer).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: AppRadius.rPill,
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.lg,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(title!, style: context.textTheme.titleLarge),
                  ),
                ),
              if (scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.lg,
                      AppSpacing.screenH,
                      AppSpacing.xl,
                    ),
                    child: child,
                  ),
                )
              else
                Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
