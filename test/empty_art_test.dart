import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/empty_state_widget.dart';

const _all = [
  EmptyArt.cart,
  EmptyArt.wishlist,
  EmptyArt.orders,
  EmptyArt.notifications,
  EmptyArt.addresses,
  EmptyArt.payment,
  EmptyArt.search,
  EmptyArt.products,
  EmptyArt.filters,
  EmptyArt.signInRequired,
  EmptyArt.notFound,
  EmptyArt.comingSoon,
];

void main() {
  test('every empty-state picture exists as a compact transparent PNG', () {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    for (final path in _all) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final bytes = file.readAsBytesSync();
      expect(bytes.take(8).toList(), equals(signature), reason: path);
      expect(bytes.length, lessThan(3 * 1024 * 1024), reason: path);
    }
  });

  for (final path in _all) {
    testWidgets('$path decodes', (tester) async {
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          File(path).readAsBytesSync(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        final pixels = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(
          pixels!.getUint8(3),
          lessThanOrEqualTo(1),
          reason: '$path should have alpha',
        );
        frame.image.dispose();
        codec.dispose();
      });
    });
  }

  for (final size in const [Size(320, 568), Size(412, 900)]) {
    for (final dark in const [false, true]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          'empty state draws in ${size.width.toInt()}px '
          '${dark ? 'dark' : 'light'} ${locale.languageCode}',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.4),
                ),
                child: MaterialApp(
                  theme: dark
                      ? AppTheme.forLocale(Brightness.dark, locale)
                      : AppTheme.forLocale(Brightness.light, locale),
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const Scaffold(
                    body: EmptyStateWidget(
                      illustration: EmptyArt.cart,
                      title: 'Your bag is empty',
                      message: 'Looks like you have not added anything yet.',
                      actionLabel: 'Start shopping',
                      onAction: _noop,
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            expect(find.byType(Image), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

void _noop() {}
