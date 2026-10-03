import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../di/injection.dart';

/// Calls [onChanged] whenever the favourites change anywhere in the app, so
/// long-lived screens (tabs kept alive in the navigation shell, pages under a
/// pushed product page) can re-mark their hearts.
class FavoritesListener extends StatefulWidget {
  const FavoritesListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final VoidCallback onChanged;
  final Widget child;

  @override
  State<FavoritesListener> createState() => _FavoritesListenerState();
}

class _FavoritesListenerState extends State<FavoritesListener> {
  StreamSubscription<BoxEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    final box = sl<Box>(instanceName: AppConstants.favoritesBox);
    _subscription = box.watch().listen((_) {
      if (mounted) widget.onChanged();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
