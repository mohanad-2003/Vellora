import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/features/home/domain/entities/banner_entity.dart';

/// A banner's tap target comes from the back office; the three built-in banners
/// keep their own lists, and a banner with neither opens nothing.
void main() {
  Map<String, dynamic> json({Object? link, String id = 'b1'}) => {
    'id': id,
    'title': 't',
    'subtitle': 's',
    'imageUrl': 'https://example.com/b.webp',
    'link': link,
  };

  test('a link is read from the feed', () {
    final b = ApiMappers.banner(
      json(link: {'type': 'product', 'value': 'dj12'}),
    );
    expect(b.link, const BannerLink(type: 'product', value: 'dj12'));
    expect(b.opensSomething, isTrue);
  });

  test('no link, and a malformed link, mean the banner opens nothing', () {
    expect(ApiMappers.banner(json()).opensSomething, isFalse);
    expect(ApiMappers.banner(json(link: 'x')).link, isNull);
    expect(ApiMappers.banner(json(link: {'type': 'product'})).link, isNull);
  });

  test('the built-in banners still open their lists', () {
    for (final id in ['summer', 'flash', 'new']) {
      expect(
        ApiMappers.banner(json(id: id)).opensSomething,
        isTrue,
        reason: id,
      );
    }
  });

  test('badge, button words and the end time are read from the feed', () {
    final b = ApiMappers.banner({
      ...json(),
      'badge': 'Hot',
      'cta': 'Grab it',
      'endsAt': '2030-01-02T03:04:05.000Z',
    });
    expect([b.badge, b.cta], ['Hot', 'Grab it']);
    expect(
      b.endsAt!.isAtSameMomentAs(DateTime.utc(2030, 1, 2, 3, 4, 5)),
      isTrue,
    );
  });

  test('without them the banner has none', () {
    final b = ApiMappers.banner(json());
    expect([b.badge, b.cta, b.endsAt], ['', '', null]);
  });
}
