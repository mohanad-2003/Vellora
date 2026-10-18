import 'package:flutter/material.dart';

import '../localization/l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

extension ContextX on BuildContext {
  /// Localized strings: `context.l10n.login`.
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Extra brand colours (accent, success, skeleton).
  VelloraColors get vellora => Theme.of(this).vellora;

  /// Room to leave at the bottom of a tab's scrolling content so the floating
  /// bar does not cover its last item (the bar floats over the body).
  double get navClearance => MediaQuery.paddingOf(this).bottom;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
