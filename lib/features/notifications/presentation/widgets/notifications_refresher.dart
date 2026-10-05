import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../cubit/notifications_cubit.dart';

/// Keeps the bell's unread dot current without the user doing anything: it
/// asks the server again every [every] while the app is open and signed in, and
/// right away when the app comes back from the background.
class NotificationsRefresher extends StatefulWidget {
  const NotificationsRefresher({
    super.key,
    required this.child,
    this.every = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration every;

  @override
  State<NotificationsRefresher> createState() => _NotificationsRefresherState();
}

class _NotificationsRefresherState extends State<NotificationsRefresher>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
