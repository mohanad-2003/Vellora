import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/network/api_endpoints.dart';
import 'package:vellora/core/network/dio_client.dart';

import '../network/interceptors/auth_interceptor.dart';

/// The steps of a shopping visit the back office funnel counts.
enum ShopEvent {
  viewProduct('view_product'),
  addToCart('add_to_cart'),
  beginCheckout('begin_checkout'),
  purchase('purchase'),

  /// A promotional banner came up on Home / the shopper tapped it.
  bannerView('banner_view'),
  bannerClick('banner_click');

  const ShopEvent(this.wire);

  /// The name the API knows the step by.
  final String wire;
}

/// Reports shopping steps to the API, fire and forget: a slow or failed report
/// never reaches the shopper, and nothing is retried or queued.
class EventTracker {
  EventTracker._();

  /// One id per app launch, so visits from people who are not signed in can
  /// still be counted once each.
  static final String sessionId = _newSessionId();

  /// Replaces the network call in tests.
  static Future<void> Function(Map<String, dynamic> body)? sender;

  static String _newSessionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static void track(ShopEvent event, {String? productId, String? bannerId}) {
    unawaited(_send(event, productId, bannerId));
  }

  static final Set<String> _bannersSeen = {};

  /// A banner counts as seen once per launch, however often it comes round
  /// in the carousel or Home reloads.
  static void trackBannerView(String bannerId) {
    if (_bannersSeen.add(bannerId)) {
      track(ShopEvent.bannerView, bannerId: bannerId);
    }
  }

  /// Forgets which banners were seen (tests).
  static void resetBannersSeen() => _bannersSeen.clear();

  static Future<void> _send(
    ShopEvent event,
    String? productId,
    String? bannerId,
  ) async {
    try {
      final body = <String, dynamic>{
        'sessionId': sessionId,
        'events': [
          {'kind': event.wire, 'productId': ?productId, 'bannerId': ?bannerId},
        ],
      };
      final custom = sender;
      if (custom != null) return await custom(body);
      await sl<DioClient>().dio.post<void>(
        ApiEndpoints.events,
        data: body,
        options: Options(extra: {AuthInterceptor.skipAuthErrorKey: true}),
      );
    } catch (_) {
      // Best effort only.
    }
  }
}
