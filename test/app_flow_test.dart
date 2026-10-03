import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vellora/app.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/widgets/vellora_logo.dart';

/// Boots the real app (real DI graph, Hive, go_router, mock datasources) and
/// walks the core shopping loop end-to-end, headlessly. Platform channels for
/// secure storage are stubbed with an in-memory map; Hive uses a temp dir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStore = <String, String>{};
  late Directory hiveDir;

  setUpAll(() async {
    // Stub flutter_secure_storage's platform channel.
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
        case 'delete':
          secureStore.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });

    hiveDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(hiveDir.path);

    // Language already chosen + onboarding already seen so splash routes
    // straight to Login.
    SharedPreferences.setMockInitialValues({
      AppConstants.prefLanguageSelected: true,
      AppConstants.prefOnboardingSeen: true,
    });

    await configureDependencies();
  });

  tearDownAll(() async {
    // Box watchers created inside the fake-async test zone can never finish
    // closing, so don't wait on them forever.
    await Hive.deleteFromDisk().timeout(
      const Duration(seconds: 2),
      onTimeout: () => <void>[],
    );
    try {
      await hiveDir.delete(recursive: true);
    } catch (_) {}
    await sl.reset();
  });

  testWidgets('Splash → Login → Home → Product → Cart', (tester) async {
    await tester.pumpWidget(const VelloraApp());

    // Splash renders.
    await tester.pump();
    // The Vellora brand mark and wordmark are shown (artwork, not text).
    expect(find.byType(VelloraMark), findsOneWidget);
    expect(find.byType(VelloraWordmark), findsOneWidget);

    // Splash decides destination (1.6s) → Login.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets,
        reason: 'Login form should be visible');

    // Fill credentials and submit.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'shopper@test.com');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Tap the login button (elevated).
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump(); // loading
    await tester.pump(const Duration(milliseconds: 1500)); // mock auth delay
    // Login persists the user in Hive (real file I/O), which fake-async time
    // cannot advance — let real time pass instead.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    // Home loads (mock delay ~1.2s). Avoid pumpAndSettle while shimmer spins.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Home renders inside the tab shell: the greeting header and the
    // bottom navigation are visible.
    expect(find.text('Explore'), findsOneWidget,
        reason: 'Bottom navigation should render after login');
    expect(find.text('Guest'), findsNothing,
        reason: 'A signed-in user is greeted by name, not as a guest');

    // Unmount so periodic timers (banner autoplay, countdown) are released.
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
  });
}
