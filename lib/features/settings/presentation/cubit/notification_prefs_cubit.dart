import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs extends Equatable {
  const NotificationPrefs({this.orderUpdates = true, this.promotions = true});

  final bool orderUpdates;
  final bool promotions;

  @override
  List<Object?> get props => [orderUpdates, promotions];
}

/// The user's notification preferences, persisted locally. They record intent
/// now and will gate real pushes once a notification service exists.
@injectable
class NotificationPrefsCubit extends Cubit<NotificationPrefs> {
  NotificationPrefsCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _ordersKey = 'pref_notif_orders';
  static const _promosKey = 'pref_notif_promos';

  static NotificationPrefs _read(SharedPreferences p) => NotificationPrefs(
        orderUpdates: p.getBool(_ordersKey) ?? true,
        promotions: p.getBool(_promosKey) ?? true,
      );

  Future<void> setOrderUpdates(bool value) async {
    emit(NotificationPrefs(orderUpdates: value, promotions: state.promotions));
    await _prefs.setBool(_ordersKey, value);
  }

  Future<void> setPromotions(bool value) async {
    emit(NotificationPrefs(orderUpdates: state.orderUpdates, promotions: value));
    await _prefs.setBool(_promosKey, value);
  }
}
