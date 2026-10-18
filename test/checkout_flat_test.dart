import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/checkout/presentation/widgets/selectable_tile.dart';

/// The checkout choices sit on the page: they stay tappable, show which one is
/// chosen, and do not overflow on narrow phones with large text.
void main() {
  var tapped = 0;
  setUp(() => tapped = 0);

  Future<void> show(
    WidgetTester tester, {
    Size size = const Size(390, 800),
    double textScale = 1,
    bool dark = false,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SelectableTile(
                  selected: true,
                  title: 'Standard delivery with a rather long title',
                  subtitle: '3-5 working days',
                  leading: const TileIcon(icon: Icons.local_shipping_outlined),
                  trailing: const Text('Free'),
                  onTap: () => tapped++,
                ),
                SelectableTile(
                  selected: false,
                  title: 'Express',
                  subtitle: '1-2 working days',
                  leading: const TileIcon(icon: Icons.bolt_rounded),
                  trailing: const Text('\$14.99'),
                  onTap: () => tapped++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('rows are tappable and show the radio state', (tester) async {
    await show(tester);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    await tester.tap(find.text('Express'));
    expect(tapped, 1);
  });

  for (final size in const [Size(320, 640), Size(360, 740)]) {
    for (final dark in const [false, true]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          'no overflow ${size.width.toInt()}px x1.4 '
          '${dark ? 'dark' : 'light'} ${locale.languageCode}',
          (tester) async {
            await show(
              tester,
              size: size,
              textScale: 1.4,
              dark: dark,
              locale: locale,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
