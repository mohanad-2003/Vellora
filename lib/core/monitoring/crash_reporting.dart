import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash and error reporting (Sentry), switched on only when the app is built
/// with `--dart-define=SENTRY_DSN=...`. Without it nothing here does anything.
///
/// Nothing about the shopper is sent: the app never sets a user, personal data
/// such as the IP address is off, there are no screenshots, web requests are kept
/// out of the trail, and email addresses are masked in every message.
class CrashReporting {
  CrashReporting._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');

  static bool get enabled => _dsn.isNotEmpty;

  /// `--dart-define=SENTRY_TEST=true` sends one test error at start-up, to check that reporting reaches Sentry.
  static const bool _sendTest = bool.fromEnvironment('SENTRY_TEST');

  /// Runs [appRunner], with error reporting around it when it is on.
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!enabled) return appRunner();
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = _dsn
          ..environment = kReleaseMode ? 'production' : 'development'
          ..sendDefaultPii = false
          ..attachScreenshot = false
          // Errors only: performance traces are another thing to pay for.
          ..tracesSampleRate = 0
          ..beforeSend = scrub
          ..beforeBreadcrumb = dropNetworkBreadcrumbs;
      },
      appRunner: () async {
        if (_sendTest) {
          await Sentry.captureException(StateError('Sentry test error from the Vellora app'));
        }
        await appRunner();
      },
    );
  }

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');

  /// Replaces every email address in [text] with `***@***`.
  @visibleForTesting
  static String maskEmails(String text) => text.replaceAll(_email, '***@***');

  /// Masks email addresses in an event's texts before it leaves the phone.
  @visibleForTesting
  static SentryEvent? scrub(SentryEvent event, Hint hint) {
    final message = event.message;
    if (message != null) {
      event.message = SentryMessage(
        maskEmails(message.formatted),
        template: message.template == null ? null : maskEmails(message.template!),
        params: message.params,
      );
    }
    for (final e in event.exceptions ?? const <SentryException>[]) {
      final value = e.value;
      if (value != null) e.value = maskEmails(value);
    }
    return event;
  }

  /// Web requests carry addresses and ids; they stay out of the trail.
  @visibleForTesting
  static Breadcrumb? dropNetworkBreadcrumbs(Breadcrumb? crumb, Hint hint) {
    final category = crumb?.category;
    if (category == 'http' || category == 'xhr') return null;
    return crumb;
  }
}
