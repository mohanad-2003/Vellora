import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../../features/cart/presentation/bloc/cart_badge_cubit.dart';
import '../../features/orders/data/orders_remote_datasource.dart';
import '../../features/orders/domain/order_entity.dart';
import '../../features/orders/presentation/cubit/active_orders_cubit.dart';
import '../di/injection.dart';
import '../extensions/context_extensions.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../usecases/usecase.dart';
import '../widgets/cart_added_chip.dart';
import '../widgets/cart_flight.dart';
import '../widgets/vellora_nav_bar.dart';
import 'tab_reselect.dart';

/// Hosts the four top-level tabs (Home · Explore · Cart · Profile). The
/// wishlist is opened from the profile.
///
/// Built on [StatefulNavigationShell] (`indexedStack`), so each tab keeps its
/// own navigation stack, scroll position and loaded data while the user moves
/// between tabs. Phones get a floating bottom bar; wide windows (tablets,
/// landscape tablets) get a navigation rail.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int homeIndex = 0;
  static const int cartIndex = 2;
  static const int profileIndex = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final ActiveOrdersCubit _activeOrders = ActiveOrdersCubit(
    isSignedIn: () async {
      final user = await sl<GetCachedUserUseCase>()(const NoParams());
      return user.fold((_) => false, (u) => u != null);
    },
    countActive: () async {
      final orders = await sl<OrdersRemoteDataSource>().getOrders();
      return orders
          .where(
            (o) =>
                o.status == OrderStatus.processing ||
                o.status == OrderStatus.shipped,
          )
          .length;
    },
  );

  StatefulNavigationShell get _shell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    _activeOrders.refresh();
  }

  @override
  void dispose() {
    _activeOrders.close();
    super.dispose();
  }

  void _select(BuildContext context, int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final same = index == _shell.currentIndex;
    // Re-tapping the active tab pops it back to its root (and a tab that
    // scrolls goes back to the top).
    _shell.goBranch(index, initialLocation: same);
    if (same) TabReselect.notify(index);
    _activeOrders.refresh(force: index == MainShell.profileIndex);
  }

  List<NavDestinationItem> _items(
    BuildContext context,
    int cartCount,
    int activeOrders,
  ) {
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
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag_rounded,
        label: l10n.cart,
        badgeCount: cartCount,
        iconKey: CartFlight.navCartKey,
      ),
      NavDestinationItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.profile,
        showDot: activeOrders > 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final current = _shell.currentIndex;
    final wide = context.screenWidth >= Breakpoints.medium;

    return PopScope(
      // System back on any tab other than Home returns to Home first.
      canPop: current == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && current != 0) _shell.goBranch(0);
      },
      child: BlocBuilder<CartBadgeCubit, int>(
        builder: (context, cartCount) => BlocBuilder<ActiveOrdersCubit, int>(
          bloc: _activeOrders,
          builder: (context, activeOrders) {
            final items = _items(context, cartCount, activeOrders);
            if (wide) {
              return Scaffold(
                body: Row(
                  children: [
                    _Rail(
                      items: items,
                      current: current,
                      onSelected: (i) => _select(context, i),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: context.colors.outlineVariant,
                    ),
                    Expanded(child: _shell),
                  ],
                ),
              );
            }
            return Scaffold(
              // The pages scroll under the glass bar and leave their own room.
              extendBody: true,
              body: Stack(
                children: [
                  Positioned.fill(child: _shell),
                  // Over the bar: what was just added, with a way to the cart.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Builder(
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(bottom: context.navClearance),
                        child: CartAddedChip(
                          hidden: current == MainShell.cartIndex,
                          onViewCart: () =>
                              _select(context, MainShell.cartIndex),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: VelloraNavBar(
                items: items,
                currentIndex: current,
                onSelected: (i) => _select(context, i),
              ),
            );
          },
        ),
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
    final colors = context.colors;
    final dark = context.isDark;
    // The same capsule as the phone bar: emerald with a gold icon in light,
    // deep with a mint icon in dark.
    return NavigationRail(
      selectedIndex: current,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colors.surface,
      indicatorColor: dark ? colors.primaryContainer : colors.primary,
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(
        color: dark ? colors.primary : kBrandGold,
      ),
      unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
      selectedLabelTextStyle: context.textTheme.labelMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w700,
      ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: _railIcon(item, item.icon),
            selectedIcon: _railIcon(item, item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }

  Widget _railIcon(NavDestinationItem item, IconData icon) {
    if (item.badgeCount > 0) {
      return Badge.count(count: item.badgeCount, child: Icon(icon));
    }
    if (item.showDot) return Badge(child: Icon(icon));
    return Icon(icon);
  }
}
