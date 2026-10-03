import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/app.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/features/auth/presentation/pages/create_new_password_page.dart';
import 'package:vellora/features/auth/presentation/pages/login_page.dart';
import 'package:vellora/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:vellora/features/auth/presentation/pages/password_reset_success_page.dart';
import 'package:vellora/features/auth/presentation/pages/register_page.dart';
import 'package:vellora/features/auth/presentation/pages/welcome_page.dart';
import 'package:vellora/features/language_select/presentation/pages/language_select_page.dart';
import 'package:vellora/features/onboarding/presentation/pages/onboarding_page.dart';

/// Boots the real app (real DI, router, mock datasources) and drives the full
/// pre-Home chain headlessly, asserting each screen is reached and no exception
/// (incl. RenderFlex overflow) is thrown along the way. Mirrors the manual
/// walkthrough in the plan's step 10.
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

    hiveDir = await Directory.systemTemp.createTemp('hive_flow_test');
    Hive.init(hiveDir.path);
    // Fresh install: no language chosen → starts at Language Select.
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
    await sl.reset();
  });

  testWidgets('full pre-Home chain reaches every screen without exceptions',
      (tester) async {
    // Pin to the ScreenUtil design size (scale 1.0) so content fits and every
    // control is on-screen / hittable.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const VelloraApp());
    await tester.pump();

    // Splash decides (1.6s) → Language Select.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(LanguageSelectPage), findsOneWidget);

    // Continue → Onboarding.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    // Next, Next, Get Started → Welcome.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);

    // Create Account → Register.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);

    // Fill the register form and accept terms (gating check).
    final regFields = find.byType(TextFormField);
    await tester.enterText(regFields.at(0), 'Jane Doe');
    await tester.enterText(regFields.at(1), 'jane@vellora.com');
    await tester.enterText(regFields.at(2), 'secret123');
    await tester.enterText(regFields.at(3), 'secret123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // "Log In" swaps Register for Login (no stacking).
    // The link sits below the (now taller) form, so scroll it into view.
    final logInLink = find.widgetWithText(TextButton, 'Log In');
    await tester.ensureVisible(logInLink);
    await tester.pumpAndSettle();
    await tester.tap(logInLink);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Forgot Password → ForgotPassword.
    await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
    await tester.pumpAndSettle();
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'jane@vellora.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // mock delay
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OtpVerificationPage), findsOneWidget);

    // Enter the deterministic OTP 1234 → auto-verify → Create New Password.
    final otpBoxes = find.descendant(
      of: find.byType(OtpVerificationPage),
      matching: find.byType(TextField),
    );
    await tester.enterText(otpBoxes.at(0), '1');
    await tester.enterText(otpBoxes.at(1), '2');
    await tester.enterText(otpBoxes.at(2), '3');
    await tester.enterText(otpBoxes.at(3), '4');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // otp verify delay
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CreateNewPasswordPage), findsOneWidget);

    // Set a new password → Password Reset Success.
    final pwFields = find.descendant(
      of: find.byType(CreateNewPasswordPage),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(pwFields.at(0), 'NewPass123!');
    await tester.enterText(pwFields.at(1), 'NewPass123!');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // reset delay
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PasswordResetSuccessPage), findsOneWidget);

    // Back to Login → Login.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Back to Log In'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
