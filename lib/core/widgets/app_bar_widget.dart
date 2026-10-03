import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import 'app_icon_button.dart';

/// Consistent app bar: tonal circular back button, centred title, actions.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.centerTitle = true,
    this.leading,
    this.bottom,
  });

  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(60 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // go_router-aware: pages inside a ShellRoute have their own Navigator, so
    // Navigator.canPop alone misses the back stack.
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: 60,
      title: title != null
          ? Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading:
          leading ??
          (showBack && canPop
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: AppIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 18,
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed:
                        onBack ??
                        () => router != null
                            ? router.pop()
                            : Navigator.of(context).maybePop(),
                  ),
                )
              : null),
      actions: [...?actions, const SizedBox(width: 8)],
      bottom: bottom,
      backgroundColor: context.colors.surfaceContainerLow,
    );
  }
}
