import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/core/widgets/promo_banner.dart';

/// The countdown on a banner: shown only while the end is near, and it ticks.
void main() {
  Future<void> show(WidgetTester tester, Duration left) async {
    final base = DateTime(2030, 1, 1, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: BannerCountdown(deadline: base.add(left), now: () => base),
          ),
        ),
      ),
    );
  }

  testWidgets('shows hours, minutes and seconds when the end is near', (
    tester,
  ) async {
    await show(tester, const Duration(hours: 2, minutes: 14, seconds: 33));
    expect(find.text('02:14:33'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the hours beyond a day', (tester) async {
    await show(tester, const Duration(hours: 50, minutes: 5, seconds: 9));
    expect(find.text('50:05:09'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows nothing when the end is far off or has passed', (
    tester,
  ) async {
    await show(tester, const Duration(days: 10));
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    await show(tester, const Duration(seconds: -5));
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
