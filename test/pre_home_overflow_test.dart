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
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/pages/create_new_password_page.dart';
import 'package:vellora/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vellora/features/auth/presentation/pages/login_page.dart';
import 'package:vellora/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:vellora/features/auth/presentation/pages/password_reset_success_page.dart';
import 'package:vellora/features/auth/presentation/pages/register_page.dart';
import 'package:vellora/features/auth/presentation/pages/terms_privacy_page.dart';
import 'package:vellora/features/auth/presentation/pages/welcome_page.dart';
import 'package:vellora/features/language_select/presentation/pages/language_select_page.dart';
import 'package:vellora/features/onboarding/presentation/pages/onboarding_page.dart';

/// Renders every new / redesigned pre-Home screen at multiple viewport aspect
/// ratios (including a short-wide desktop-like one) and asserts none overflow.
/// This targets the RenderFlex-overflow bug class that broke Phase 1 (element
/// height tied to `.w` width / AspectRatio inside a bounded parent).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStore = <String, String>{};
  late Directory hiveDir;

  setUpAll(() async {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
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

    hiveDir = await Directory.systemTemp.createTemp('hive_overflow_test');
    Hive.init(hiveDir.path);
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(environment: mockEnv);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
    await sl.reset();
  });

  Widget harness(Widget page) {
    return Builder(
      builder: (context) => BlocProvider.value(
        value: sl<LocaleCubit>(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: const Locale('en'),
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

  Widget withAuthBloc(Widget page) =>
      BlocProvider(create: (_) => sl<AuthBloc>(), child: page);

  // Portrait phone, short-wide desktop, and a tall-narrow foldable.
  final sizes = <(String, Size)>[
    ('phone-portrait', const Size(375, 812)),
    ('desktop-short-wide', const Size(1280, 560)),
    ('landscape-phone', const Size(740, 360)),
  ];

  final pages = <(String, Widget Function())>[
    ('LanguageSelect', () => const LanguageSelectPage()),
    ('Onboarding', () => const OnboardingPage()),
    ('Welcome', () => const WelcomePage()),
    ('Login', () => const LoginPage()),
    ('Register', () => const RegisterPage()),
    ('TermsPrivacy', () => const TermsPrivacyPage()),
    ('ForgotPassword', () => const ForgotPasswordPage()),
    ('OtpVerification', () => const OtpVerificationPage()),
    ('CreateNewPassword', () => const CreateNewPasswordPage()),
    ('PasswordResetSuccess', () => const PasswordResetSuccessPage()),
  ];

  const needsAuthAncestor = {
    'ForgotPassword',
    'OtpVerification',
    'CreateNewPassword',
  };

  for (final (sizeName, size) in sizes) {
    for (final (pageName, builder) in pages) {
      testWidgets('$pageName renders without overflow @ $sizeName',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var page = builder();
        if (needsAuthAncestor.contains(pageName)) {
          page = withAuthBloc(page);
        }

        await tester.pumpWidget(harness(page));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull,
            reason: '$pageName overflowed at $sizeName');
      });
    }
  }
}
