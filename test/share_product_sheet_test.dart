import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';
import 'package:vellora/features/product/presentation/widgets/share_product_sheet.dart';

/// The share sheet: what is shared, the quick apps, the link with Copy, and the
/// system sheet as the fallback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const product = ProductEntity(
    id: 'dj7',
    name: 'Coco Noir',
    brand: 'Chanel',
    imagePath: '',
    price: 108.53,
    originalPrice: 129.0,
  );

  final launched = <Uri>[];
  final systemShared = <String>[];
  var canLaunch = true;
  String? clipboard;

  setUp(() {
    launched.clear();
    systemShared.clear();
    canLaunch = true;
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });

  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
            child: ShareProductSheet(
              product: product,
              launch: (uri) async {
                launched.add(uri);
                return canLaunch;
              },
              systemShare: (_, text) async => systemShared.add(text),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the product and the link', (tester) async {
    await open(tester);
    expect(find.text('Coco Noir'), findsOneWidget);
    expect(find.text('Chanel'), findsOneWidget);
    expect(find.text(AppConstants.productUrl('dj7')), findsOneWidget);
    for (final label in ['WhatsApp', 'Telegram', 'Messages', 'More']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Copy puts the link on the clipboard and confirms', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(clipboard, AppConstants.productUrl('dj7'));
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('WhatsApp opens a wa.me link carrying the message', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('WhatsApp'));
    await tester.pump();
    expect(launched.single.host, 'wa.me');
    final text = launched.single.queryParameters['text']!;
    expect(text, contains('Coco Noir'));
    expect(text, contains(AppConstants.productUrl('dj7')));
    expect(systemShared, isEmpty);
  });

  testWidgets('Telegram opens its share link', (tester) async {
    await open(tester);
    await tester.tap(find.text('Telegram'));
    await tester.pump();
    expect(launched.single.host, 't.me');
    expect(
      launched.single.queryParameters['url'],
      AppConstants.productUrl('dj7'),
    );
  });

  testWidgets('when no app can open the link, the system sheet takes over', (
    tester,
  ) async {
    canLaunch = false;
    await open(tester);
    await tester.tap(find.text('WhatsApp'));
    await tester.pump();
    expect(systemShared.single, contains('Coco Noir'));
  });

  testWidgets('More opens the system sheet with the message', (tester) async {
    await open(tester);
    await tester.tap(find.text('More'));
    await tester.pump();
    expect(launched, isEmpty);
    expect(systemShared.single, contains(AppConstants.productUrl('dj7')));
  });

  testWidgets('reads in Arabic', (tester) async {
    await open(tester, locale: const Locale('ar'));
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('نسخ'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'fits a 360 wide phone (${locale.languageCode}, text x$scale)',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const Scaffold(
                  body: SingleChildScrollView(
                    child: ShareProductSheet(product: product),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
