import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/product/domain/entities/review_entity.dart';
import 'package:vellora/features/product/presentation/widgets/rating_summary.dart';

Map<String, dynamic> _json({Object? reply}) => {
  'id': 1,
  'author': 'Sara',
  'rating': 4,
  'comment': 'Nice fit',
  'photos': <String>[],
  'createdAt': '2026-10-20T10:00:00.000Z',
  'reply': reply,
};

Widget _app(List<ReviewEntity> reviews, Locale locale, {bool dark = false}) =>
    MaterialApp(
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
        body: SingleChildScrollView(
          child: RatingSummary(rating: 4, reviewCount: 2, reviews: reviews),
        ),
      ),
    );

void main() {
  test(
    'the shop reply comes through the API mapper, and an empty one is none',
    () {
      expect(
        ApiMappers.review(_json(reply: ' Thank you! ')).reply,
        'Thank you!',
      );
      expect(ApiMappers.review(_json(reply: null)).reply, isNull);
      expect(ApiMappers.review(_json(reply: '   ')).reply, isNull);
      final noField = _json()..remove('reply');
      expect(ApiMappers.review(noField).reply, isNull);
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final dark in const [false, true]) {
      testWidgets(
        'a review shows the shop reply under it (${locale.languageCode}, ${dark ? 'dark' : 'light'})',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final reviews = [
            ApiMappers.review(_json(reply: 'Thank you for the feedback')),
            ApiMappers.review(_json()),
          ];
          await tester.pumpWidget(_app(reviews, locale, dark: dark));
          await tester.pump();

          expect(find.text('Thank you for the feedback'), findsOneWidget);
          // Only the answered review has the block.
          expect(
            find.text(
              locale.languageCode == 'en'
                  ? 'Reply from Vellora'
                  : 'ردّ Vellora',
            ),
            findsOneWidget,
          );
          expect(find.text('Nice fit'), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
