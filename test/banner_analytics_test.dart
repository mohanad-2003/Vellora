import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/analytics/event_tracker.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/home/domain/entities/banner_entity.dart';
import 'package:vellora/features/home/presentation/widgets/promo_banner_carousel.dart';

/// The carousel reports which banner is up and which one was tapped.
void main() {
  final sent = <Map<String, dynamic>>[];
  final opened = <String>[];

  setUp(() {
    sent.clear();
    opened.clear();
    EventTracker.resetBannersSeen();
    EventTracker.sender = (body) async => sent.add(body);
  });

  tearDown(() {
    EventTracker.sender = null;
    EventTracker.resetBannersSeen();
  });

  List<Object?> events() => sent.expand((b) => b['events'] as List).toList();

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PromoBannerCarousel(
            banners: const [
              BannerEntity(
                id: 'b1',
                title: 'First',
                subtitle: '',
                imagePath: '',
                link: BannerLink(type: 'collection', value: 'flashSale'),
              ),
              BannerEntity(
                id: 'b2',
                title: 'Second',
                subtitle: '',
                imagePath: '',
              ),
            ],
            onBannerTap: (b) => opened.add(b.id),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the first banner counts as seen when the carousel shows', (
    tester,
  ) async {
    await show(tester);
    await tester.pump(Duration.zero);
    expect(events(), [
      {'kind': 'banner_view', 'bannerId': 'b1'},
    ]);
  });

  testWidgets('swiping to the next banner reports it, once', (tester) async {
    await show(tester);
    await tester.drag(find.text('First'), const Offset(-300, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(events(), [
      {'kind': 'banner_view', 'bannerId': 'b1'},
      {'kind': 'banner_view', 'bannerId': 'b2'},
    ]);
  });

  testWidgets('a tap is reported and still opens the banner', (tester) async {
    await show(tester);
    await tester.tap(find.text('First'));
    await tester.pump(Duration.zero);
    expect(opened, ['b1']);
    expect(events().last, {'kind': 'banner_click', 'bannerId': 'b1'});
  });
}
