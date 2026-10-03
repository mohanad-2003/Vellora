import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/bloc/cart_badge_cubit.dart';
import '../extensions/context_extensions.dart';
import '../responsive/responsive.dart';
import '../widgets/vellora_nav_bar.dart';

/// Hosts the five top-level tabs (Home · Explore · Wishlist · Cart · Profile).
///
/// Built on [StatefulNavigationShell] (`indexedStack`), so each tab keeps its
/// own navigation stack, scroll position and loaded data while the user moves
/// between tabs. Phones get a bottom bar; wide windows (tablets, landscape
/// tablets) get a navigation rail.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int cartIndex = 3;

  void _select(BuildContext context, int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // Re-tapping the active tab pops it back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<NavDestinationItem> _items(BuildContext context, int cartCount) {
    final l10n = context.l10n;
    return [
      NavDestinationItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      NavDestinationItem(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
        label: l10n.explore,
      ),
      NavDestinationItem(
        icon: Icons.favorite_border_rounded,
        selectedIcon: Icons.favorite_rounded,
        label: l10n.wishlist,
      ),
      NavDestinationItem(
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag_rounded,
        label: l10n.cart,
        badgeCount: cartCount,
      ),
      NavDestinationItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.profile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    final wide = context.screenWidth >= Breakpoints.medium;

    return PopScope(
      // System back on any tab other than Home returns to Home first.
      canPop: current == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && current != 0) navigationShell.goBranch(0);
      },
      child: BlocBuilder<CartBadgeCubit, int>(
        builder: (context, cartCount) {
          final items = _items(context, cartCount);
          if (wide) {
            return Scaffold(
              body: Row(
                children: [
                  _Rail(items: items, current: current, onSelected: (i) => _select(context, i)),
                  VerticalDivider(
                    width: 1,
                    color: context.colors.outlineVariant,
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
            );
          }
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: VelloraNavBar(
              items: items,
              currentIndex: current,
              onSelected: (i) => _select(context, i),
            ),
          );
        },
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.items,
    required this.current,
    required this.onSelected,
  });

  final List<NavDestinationItem> items;
  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: current,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: context.colors.surface,
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Badge.count(
              count: item.badgeCount,
              isLabelVisible: item.badgeCount > 0,
              child: Icon(item.icon),
            ),
            selectedIcon: Badge.count(
              count: item.badgeCount,
              isLabelVisible: item.badgeCount > 0,
              child: Icon(item.selectedIcon),
            ),
            label: Text(item.label),
          ),
      ],
    );
  }
}
