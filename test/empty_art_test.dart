import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  test('every picture exists and is a small, text-free SVG', () {
    for (final path in _all) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final svg = file.readAsStringSync();
      expect(svg.length, lessThan(10 * 1024), reason: path);
      for (final bad in ['<text', '<image', '<script', '<filter']) {
        expect(svg.contains(bad), isFalse, reason: '$path has $bad');
      }
    }
  });

  for (final size in const [Size(320, 568), Size(412, 900)]) {
    for (final dark in const [false, true]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        testWidgets(
          'empty state with a picture ${size.width.toInt()}px x1.4 '
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
                  theme: dark ? AppTheme.dark : AppTheme.light,
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
            expect(find.byType(SvgPicture), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

void _noop() {}
