import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/auth/google_id_token.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/profile/presentation/widgets/delete_account_sheet.dart';

Widget _app(Widget child, Locale locale) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  final realSource = googleIdTokenSource;
  tearDown(() => googleIdTokenSource = realSource);

  testWidgets('with a password the sheet asks for it and sends only it', (
    tester,
  ) async {
    String? sentPassword = 'unset';
    String? sentToken = 'unset';
    await tester.pumpWidget(
      _app(
        DeleteAccountSheet(
          onConfirm: (password, token) async {
            sentPassword = password;
            sentToken = token;
            return null;
          },
          onDeleted: () {},
        ),
        const Locale('en'),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Confirm with Google'), findsNothing);

    // An empty password is refused before anything is sent.
    await tester.tap(find.text('Delete Account'));
    await tester.pump();
    expect(sentPassword, 'unset');

    await tester.enterText(find.byType(TextField), 'my-secret-pass');
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(sentPassword, 'my-secret-pass');
    expect(sentToken, isNull);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'a Google-only account is confirmed with Google, no password field (${locale.languageCode})',
      (tester) async {
        String? sentPassword = 'unset';
        String? sentToken;
        var asked = 0;
        googleIdTokenSource = () async {
          asked++;
          return 'google-token';
        };
        var deleted = false;
        await tester.pumpWidget(
          _app(
            DeleteAccountSheet(
              googleOnly: true,
              onConfirm: (password, token) async {
                sentPassword = password;
                sentToken = token;
                return null;
              },
              onDeleted: () => deleted = true,
            ),
            locale,
          ),
        );
        expect(find.byType(TextField), findsNothing);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(DeleteAccountSheet)),
        );
        expect(find.text(l10n.deleteAccountGoogleHint), findsOneWidget);

        await tester.tap(find.text(l10n.deleteAccountWithGoogle));
        await tester.pumpAndSettle();
        expect(asked, 1);
        expect(sentPassword, isNull);
        expect(sentToken, 'google-token');
        expect(deleted, isTrue);
      },
    );
  }

  testWidgets(
    'closing the Google chooser deletes nothing, a Google failure says so',
    (tester) async {
      var sent = false;
      await tester.pumpWidget(
        _app(
          DeleteAccountSheet(
            googleOnly: true,
            onConfirm: (password, token) async {
              sent = true;
              return null;
            },
            onDeleted: () {},
          ),
          const Locale('en'),
        ),
      );

      googleIdTokenSource = () async => null;
      await tester.tap(find.text('Confirm with Google'));
      await tester.pumpAndSettle();
      expect(sent, isFalse);
      expect(
        find.textContaining('Could not sign in with Google'),
        findsNothing,
      );

      googleIdTokenSource = () async =>
          throw const GoogleSignInUnavailable('boom');
      await tester.tap(find.text('Confirm with Google'));
      await tester.pumpAndSettle();
      expect(sent, isFalse);
      expect(
        find.textContaining('Could not sign in with Google'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a refusal from the server is shown and the sheet stays open', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DeleteAccountSheet(
          googleOnly: true,
          onConfirm: (password, token) async => 'somethingWentWrong',
          onDeleted: () => fail('must not be deleted'),
        ),
        const Locale('en'),
      ),
    );
    googleIdTokenSource = () async => 'google-token';
    await tester.tap(find.text('Confirm with Google'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountSheet), findsOneWidget);
    expect(find.text('Confirm with Google'), findsOneWidget);
  });
}
