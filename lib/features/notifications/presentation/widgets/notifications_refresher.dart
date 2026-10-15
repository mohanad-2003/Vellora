import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/in_app_banner.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../../domain/notification_entity.dart';
import '../cubit/notifications_cubit.dart';

/// Keeps the bell's unread dot current without the user doing anything: it
/// asks the server again every [every] while the app is open and signed in, and
/// right away when the app comes back from the background. A notification that
/// arrives meanwhile is announced by a banner over the top of the screen that
/// opens what it is about when tapped.
class NotificationsRefresher extends StatefulWidget {
  const NotificationsRefresher({
    super.key,
    required this.child,
    this.every = const Duration(seconds: 20),
    this.overlay,
    this.open,
  });

  final Widget child;
  final Duration every;

  /// Where the banner is drawn; defaults to the app's own navigator.
  final OverlayState? Function()? overlay;

  /// Opens a route by name with an id; defaults to the app's router.
  final void Function(String route, String id)? open;

  @override
  State<NotificationsRefresher> createState() => _NotificationsRefresherState();
}

class _NotificationsRefresherState extends State<NotificationsRefresher>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<NotificationEntity>? _arrivals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arrivals = sl<UnreadNotificationsCubit>().arrivals.listen(_announce);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arrivals?.cancel();
    InAppBanner.hide();
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.every, (_) => _refresh());
  }

  /// A guest has no feed, and asking would only draw a 401.
  void _refresh() {
    if (sl<UserSessionCubit>().state == null) return;
    sl<UnreadNotificationsCubit>().refresh();
  }

  /// Says what arrived; a tap opens what it is about.
  void _announce(NotificationEntity n) {
    if (!mounted) return;
    final overlay =
        (widget.overlay ??
            () => AppRouter.router.routerDelegate.navigatorKey.currentState
                ?.overlay)();
    if (overlay == null) return;
    final orderId = n.orderId;
    final productId = n.productId;
    final target = orderId != null
        ? (RouteNames.nOrderDetails, orderId)
        : productId != null
        ? (RouteNames.nProduct, productId)
        : null;
    InAppBanner.show(
      overlay,
      title: n.title ?? '',
      body: n.body ?? '',
      icon: orderId != null
          ? Icons.local_shipping_outlined
          : Icons.local_offer_outlined,
      onTap: () {
        if (target == null) return;
        final open =
            widget.open ??
            (String route, String id) => AppRouter.router.pushNamed(
              route,
              pathParameters: {'id': id},
            );
        open(target.$1, target.$2);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _refresh();
        _start();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _timer?.cancel();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
