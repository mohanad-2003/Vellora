import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/empty_state_widget.dart';
import 'package:vellora/core/widgets/failure_state_view.dart';

Widget _scroll(Widget sliver) => MaterialApp(
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
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 148)),
            sliver,
          ],
        ),
      ),
    );

/// The Home, Explore and search screens show these placeholders in a sliver. The
/// screen used to go blank because the sliver tried to measure them first.
void main() {
  testWidgets('a failed load shows its message and retry inside a scroll view',
      (tester) async {
    var retried = 0;
    await tester.pumpWidget(_scroll(
      SliverFillRemaining(
        hasScrollBody: true,
        child: FailureStateView(failureKey: 'noConnection', onRetry: () => retried++),
      ),
    ));

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('an empty result fits too', (tester) async {
    await tester.pumpWidget(_scroll(
      const SliverFillRemaining(
        hasScrollBody: true,
        child: EmptyStateWidget(title: 'Nothing here'),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('Nothing here'), findsOneWidget);
  });
}
