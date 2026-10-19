import 'package:equatable/equatable.dart';

/// What a tap on a banner opens, as chosen in the back office.
class BannerLink extends Equatable {
  const BannerLink({required this.type, required this.value});

  /// `product`, `category` or `collection`.
  final String type;

  /// A product id, a category id, or a collection name (e.g. `flashSale`).
  final String value;

  @override
  List<Object?> get props => [type, value];
}

class BannerEntity extends Equatable {
  const BannerEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.color,
    this.link,
    this.badge = '',
    this.cta = '',
    this.endsAt,
    this.showWholePicture = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imagePath;

  /// Palette key chosen in the back office (e.g. `rose`), or null for the
  /// banner's built-in colour.
  final String? color;

  /// Where a tap goes; null for a banner that is only to look at.
  final BannerLink? link;

  /// The small pill above the title, empty for none.
  final String badge;

  /// The words on the button, empty for the app's own "Shop now".
  final String cta;

  /// When the banner stops showing, for a countdown; null when it has no end.
  final DateTime? endsAt;

  /// Whether the picture is shown whole rather than cropped to the panel.
  final bool showWholePicture;

  /// The three built-in banners predate links and open their own lists.
  static const _legacyIds = {'summer', 'flash', 'new'};

  /// Whether tapping this banner does anything.
  bool get opensSomething => link != null || _legacyIds.contains(id);

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    imagePath,
    color,
    link,
    badge,
    cta,
    endsAt,
    showWholePicture,
  ];
}
