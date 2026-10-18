import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';

/// App-wide count of items in the cart (sum of quantities), for the navigation
/// badge. The Hive cart box is the single source of truth, so any screen that
/// changes the cart — Home quick-add, product details, the cart itself —
/// updates the badge without wiring anything extra.
@lazySingleton
class CartBadgeCubit extends Cubit<int> {
  CartBadgeCubit(@Named(AppConstants.cartBox) this._box)
    : super(_countOf(_box)) {
    _subscription = _box.watch().listen((_) => emit(_countOf(_box)));
  }

  final Box _box;
  late final StreamSubscription<BoxEvent> _subscription;

  static int _countOf(Box box) {
    var total = 0;
    for (final raw in box.values) {
      try {
        final json = jsonDecode(raw as String) as Map<String, dynamic>;
        total += (json['quantity'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // A corrupt entry must never break the badge.
      }
    }
    return total;
  }

  /// What the cart holds, at the prices it was added with (for the "added"
  /// chip; the cart page and checkout price from the server's summary).
  double get total {
    var sum = 0.0;
    for (final raw in _box.values) {
      try {
        final json = jsonDecode(raw as String) as Map<String, dynamic>;
        sum +=
            ((json['price'] as num?)?.toDouble() ?? 0) *
            ((json['quantity'] as num?)?.toInt() ?? 0);
      } catch (_) {
        // Skipped, like in the count.
      }
    }
    return sum;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
