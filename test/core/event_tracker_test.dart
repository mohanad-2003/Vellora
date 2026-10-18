import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/analytics/event_tracker.dart';

void main() {
  tearDown(() {
    EventTracker.sender = null;
    EventTracker.resetBannersSeen();
  });

  test('a step is reported with the kind, the product and one launch id', () async {
    final sent = <Map<String, dynamic>>[];
    EventTracker.sender = (body) async => sent.add(body);

    EventTracker.track(ShopEvent.viewProduct, productId: 'p1');
    EventTracker.track(ShopEvent.beginCheckout);
    await Future<void>.delayed(Duration.zero);

    expect(sent, hasLength(2));
    expect(sent[0]['events'], [
      {'kind': 'view_product', 'productId': 'p1'},
    ]);
    expect(sent[1]['events'], [
      {'kind': 'begin_checkout'},
    ]);
    expect(sent[0]['sessionId'], EventTracker.sessionId);
    expect(sent[1]['sessionId'], EventTracker.sessionId);
    expect(EventTracker.sessionId.length, 32);
  });

  test('a failing report is swallowed', () async {
    EventTracker.sender = (_) async => throw Exception('offline');
    EventTracker.track(ShopEvent.purchase);
    await Future<void>.delayed(Duration.zero);
  });

  test('without a network client the call is silently dropped', () async {
    EventTracker.track(ShopEvent.addToCart, productId: 'p2');
    await Future<void>.delayed(Duration.zero);
  });

  test('a banner is reported as seen once, and its taps every time', () async {
    final sent = <Map<String, dynamic>>[];
    EventTracker.sender = (body) async => sent.add(body);

    EventTracker.trackBannerView('b1');
    EventTracker.trackBannerView('b1');
    EventTracker.trackBannerView('b2');
    EventTracker.track(ShopEvent.bannerClick, bannerId: 'b1');
    EventTracker.track(ShopEvent.bannerClick, bannerId: 'b1');
    await Future<void>.delayed(Duration.zero);

    expect(sent.map((b) => (b['events'] as List).single).toList(), [
      {'kind': 'banner_view', 'bannerId': 'b1'},
      {'kind': 'banner_view', 'bannerId': 'b2'},
      {'kind': 'banner_click', 'bannerId': 'b1'},
      {'kind': 'banner_click', 'bannerId': 'b1'},
    ]);
  });
}
