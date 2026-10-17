import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Holds the active [Locale] and persists it. Flutter auto-applies RTL for
/// Arabic. Supported locales are English and Arabic.
@lazySingleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs)
    : super(resolve(_prefs, PlatformDispatcher.instance.locale));

  final SharedPreferences _prefs;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  /// The saved choice if there is one; otherwise the device language when it
  /// is English, and Arabic for everything else. Nothing is saved until the
  /// user picks a language, so the app keeps following the device until then.
  @visibleForTesting
  static Locale resolve(SharedPreferences prefs, Locale device) {
    final code = prefs.getString(AppConstants.prefLocale);
    if (code == 'en') return const Locale('en');
    if (code == 'ar') return const Locale('ar');
    return device.languageCode == 'en'
        ? const Locale('en')
        : const Locale('ar');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    emit(locale);
    await _prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  bool get isArabic => state.languageCode == 'ar';
}
