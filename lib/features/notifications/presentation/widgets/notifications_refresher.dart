import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../../domain/notification_entity.dart';
import '../cubit/notifications_cubit.dart';

/// Keeps the bell's unread dot current without the user doing anything: it
/// asks the server again every [every] while the app is open and signed in, and
/// right away when the app comes back from the background. A notification that
/// arrives meanwhile is announced on screen, with a button that opens what it
/// is about.
class NotificationsRefresher extends StatefulWidget {
  const NotificationsRefresher({
    super.key,
    required this.child,
    this.every = const Duration(seconds: 20),
  });

  final Widget child;
  final Duration every;

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

  /// Says what arrived, and opens it from the button.
  void _announce(NotificationEntity n) {
    if (!mounted) return;
    final orderId = n.orderId;
    final productId = n.productId;
    final target = orderId != null
        ? (RouteNames.nOrderDetails, orderId)
        : productId != null
        ? (RouteNames.nProduct, productId)
        : null;
    AppSnackbar.show(
      context,
      message: [
        if (n.title != null) n.title!,
        if (n.body != null) n.body!,
      ].join('\n'),
      actionLabel: target == null ? null : context.l10n.viewDetails,
      onAction: target == null
          ? null
          : () => AppRouter.router.pushNamed(
              target.$1,
              pathParameters: {'id': target.$2},
            ),
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
