import 'package:flutter_bloc/flutter_bloc.dart';

/// How many of the signed-in shopper's orders are still on their way, for the
/// dot on the Profile tab. Signed-out shoppers and failed reads give 0.
///
/// Reads are spaced out ([minGap]) because the tab bar asks every time a tab is
/// tapped; [refresh] with `force` skips the wait (for example on Profile).
class ActiveOrdersCubit extends Cubit<int> {
  ActiveOrdersCubit({
    required Future<bool> Function() isSignedIn,
    required Future<int> Function() countActive,
    this.minGap = const Duration(seconds: 90),
    DateTime Function()? now,
  }) : _isSignedIn = isSignedIn,
       _countActive = countActive,
       _now = now ?? DateTime.now,
       super(0);

  final Future<bool> Function() _isSignedIn;
  final Future<int> Function() _countActive;
  final DateTime Function() _now;
  final Duration minGap;

  DateTime? _last;
  bool _busy = false;

  Future<void> refresh({bool force = false}) async {
    if (_busy) return;
    final last = _last;
    if (!force && last != null && _now().difference(last) < minGap) return;
    _busy = true;
    try {
      if (!await _isSignedIn()) {
        if (!isClosed) emit(0);
        return;
      }
      final count = await _countActive();
      _last = _now();
      if (!isClosed) emit(count);
    } catch (_) {
      // The dot is a nicety: keep whatever is shown.
    } finally {
      _busy = false;
    }
  }
}
