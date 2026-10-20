import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/features/profile/presentation/widgets/profile_avatar.dart';

/// Controls that are only an icon must still be named for a screen reader.
Widget _app(Widget child, Locale locale) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    final l10n = lookupAppLocalizations(locale);

    testWidgets('password eye is named and follows its state '
        '(${locale.languageCode})', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const AppTextField(label: 'p', obscureText: true), locale),
      );
      expect(find.byTooltip(l10n.showPassword), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.showPassword));
      await tester.pump();
      expect(find.byTooltip(l10n.hidePassword), findsOneWidget);
      handle.dispose();
    });

    testWidgets('avatar camera badge is a named button '
        '(${locale.languageCode})', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ProfileAvatar(name: 'Mo Z', editable: true, onEdit: () => taps++),
          locale,
        ),
      );
      final badge = find.bySemanticsLabel(l10n.changePhoto);
      expect(badge, findsOneWidget);
      await tester.tap(badge);
      expect(taps, 1);
      handle.dispose();
    });
  }
}
