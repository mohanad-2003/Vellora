import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/profile/presentation/pages/security_page.dart';

void main() {
  Future<List<(String, String)>> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final submitted = <(String, String)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangePasswordForm(
              onSubmit: (current, next) async {
                submitted.add((current, next));
                return null;
              },
              onDone: () {},
            ),
          ),
        ),
      ),
    );
    return submitted;
  }

  Future<void> fill(
    WidgetTester tester, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), next);
    await tester.enterText(fields.at(2), confirm);
    await tester.tap(find.text('Update Password'));
    await tester.pump();
  }

  testWidgets(
    'N1: an old 6-character current password is accepted, the new one is 8+',
    (tester) async {
      final submitted = await pumpForm(tester);

      await fill(
        tester,
        current: 'abc123', // 6 characters: created before the 8-char rule
        next: 'brand-new-1',
        confirm: 'brand-new-1',
      );

      expect(submitted, [('abc123', 'brand-new-1')]);
      expect(find.text('Password must be at least 8 characters'), findsNothing);
    },
  );

  testWidgets('N1: a 7-character current password is accepted too',
      (tester) async {
    final submitted = await pumpForm(tester);

    await fill(tester, current: 'abc1234', next: 'brand-new-1', confirm: 'brand-new-1');

    expect(submitted, [('abc1234', 'brand-new-1')]);
  });

  testWidgets('N1: the current password is still required', (tester) async {
    final submitted = await pumpForm(tester);

    await fill(tester, current: '', next: 'brand-new-1', confirm: 'brand-new-1');

    expect(submitted, isEmpty);
  });

  testWidgets('N1: the new password must still be at least 8 characters',
      (tester) async {
    final submitted = await pumpForm(tester);

    await fill(tester, current: 'abc123', next: '1234567', confirm: '1234567');

    expect(submitted, isEmpty);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('N1: the confirmation must match the new password',
      (tester) async {
    final submitted = await pumpForm(tester);

    await fill(tester, current: 'abc123', next: 'brand-new-1', confirm: 'brand-new-2');

    expect(submitted, isEmpty);
  });
}
