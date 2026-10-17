import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/localization/locale_cubit.dart';

/// First launch has no language screen: the app follows the device (English
/// for English, Arabic for everything else) until the user picks one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith([Map<String, Object> saved = const {}]) {
    SharedPreferences.setMockInitialValues(saved);
    return SharedPreferences.getInstance();
  }

  test('an English device starts in English', () async {
    final prefs = await prefsWith();
    expect(
      LocaleCubit.resolve(prefs, const Locale('en', 'US')).languageCode,
      'en',
    );
  });

  test('an Arabic device starts in Arabic', () async {
    final prefs = await prefsWith();
    expect(
      LocaleCubit.resolve(prefs, const Locale('ar', 'JO')).languageCode,
      'ar',
    );
  });

  test('any other device language falls back to Arabic', () async {
    final prefs = await prefsWith();
    expect(
      LocaleCubit.resolve(prefs, const Locale('fr', 'FR')).languageCode,
      'ar',
    );
  });

  test('a saved choice beats the device language', () async {
    final prefs = await prefsWith({AppConstants.prefLocale: 'ar'});
    expect(
      LocaleCubit.resolve(prefs, const Locale('en', 'US')).languageCode,
      'ar',
    );
    final english = await prefsWith({AppConstants.prefLocale: 'en'});
    expect(LocaleCubit.resolve(english, const Locale('ar')).languageCode, 'en');
  });

  test('nothing is saved until the user chooses', () async {
    final prefs = await prefsWith();
    LocaleCubit(prefs);
    expect(prefs.getString(AppConstants.prefLocale), isNull);
  });

  test('choosing a language saves it', () async {
    final prefs = await prefsWith();
    final cubit = LocaleCubit(prefs);
    await cubit.setLocale(
      cubit.state.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar'),
    );
    expect(prefs.getString(AppConstants.prefLocale), cubit.state.languageCode);
    await cubit.close();
  });
}
