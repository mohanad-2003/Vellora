import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vellora/core/monitoring/crash_reporting.dart';

void main() {
  test('without a DSN reporting is off and the app simply runs', () async {
    expect(CrashReporting.enabled, isFalse);
    var ran = 0;
    await CrashReporting.run(() => ran++);
    expect(ran, 1);
  });

  test('email addresses are masked wherever an event carries text', () {
    final event = SentryEvent(
      message: SentryMessage('Could not load sara@example.com'),
      exceptions: [
        SentryException(type: 'StateError', value: 'no account for a.b+c@mail.co.uk'),
      ],
    );

    final clean = CrashReporting.scrub(event, Hint())!;

    expect(clean.message!.formatted, 'Could not load ***@***');
    expect(clean.exceptions!.single.value, 'no account for ***@***');
    expect(clean.exceptions!.single.type, 'StateError');
  });

  test('web request breadcrumbs are dropped, others kept', () {
    expect(CrashReporting.dropNetworkBreadcrumbs(Breadcrumb(category: 'http'), Hint()), isNull);
    expect(CrashReporting.dropNetworkBreadcrumbs(Breadcrumb(category: 'xhr'), Hint()), isNull);
    final nav = Breadcrumb(category: 'navigation');
    expect(CrashReporting.dropNetworkBreadcrumbs(nav, Hint()), same(nav));
  });
}
