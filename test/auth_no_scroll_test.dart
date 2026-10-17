import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/core/di/environments.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/localization/locale_cubit.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/auth/presentation/pages/login_page.dart';
import 'package:vellora/features/auth/presentation/pages/register_page.dart';

/// Login and Register must fit a phone screen without scrolling (keyboard
/// closed, normal text size), in English and Arabic, on every common size.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStore = <String, String>{};
  late Directory hiveDir;

  setUpAll(() async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          final key = args['key'] as String?;
          switch (call.method) {
            case 'write':
              secureStore[key!] = args['value'] as String;
              return null;
            case 'read':
              return secureStore[key];
            case 'readAll':
              return Map<String, String>.from(secureStore);
            case 'delete':
              secureStore.remove(key);
              return null;
            case 'deleteAll':
              secureStore.clear();
              return null;
            default:
              return null;
          }
        });

    hiveDir = await Directory.systemTemp.createTemp('hive_no_scroll_test');
    Hive.init(hiveDir.path);
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(environment: mockEnv);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
    await sl.reset();
  });

  Widget harness(Widget page, Locale locale) {
    return Builder(
      builder: (context) => BlocProvider.value(
        value: sl<LocaleCubit>(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: locale,
          supportedLocales: LocaleCubit.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: page,
        ),
      ),
    );
  }

  final sizes = <(String, Size)>[
    ('small-320x568', const Size(320, 568)),
    ('older-360x640', const Size(360, 640)),
    ('iphone-se-375x667', const Size(375, 667)),
    ('android-360x740', const Size(360, 740)),
    ('iphone-14-390x844', const Size(390, 844)),
    ('pixel-393x851', const Size(393, 851)),
    ('large-412x915', const Size(412, 915)),
    ('max-430x932', const Size(430, 932)),
  ];

  // The status bar and gesture bar take some of the height on real devices.
  const bars = EdgeInsets.only(top: 28, bottom: 20);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final (sizeName, size) in sizes) {
      for (final (pageName, page) in <(String, Widget Function())>[
        ('Login', () => const LoginPage()),
        ('Register', () => const RegisterPage()),
      ]) {
        testWidgets(
          '$pageName does not scroll @ $sizeName ${locale.languageCode}',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            tester.view.padding = FakeViewPadding(
              top: bars.top,
              bottom: bars.bottom,
            );
            tester.view.viewPadding = tester.view.padding;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(harness(page(), locale));
            await tester.pump(const Duration(milliseconds: 400));

            expect(tester.takeException(), isNull);
            final scrollable = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            expect(
              scrollable.position.maxScrollExtent,
              0,
              reason: '$pageName needs scrolling at $sizeName',
            );
          },
        );
      }
    }
  }

  testWidgets(
    'with the keyboard open the form scrolls instead of overflowing',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);

      for (final page in const <Widget>[LoginPage(), RegisterPage()]) {
        await tester.pumpWidget(harness(page, const Locale('en')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
      }
    },
  );
}
