import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  const BannerEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imagePath;

  /// Palette key chosen in the back office (e.g. `rose`), or null for the
  /// banner's built-in colour.
  final String? color;

  @override
  List<Object?> get props => [id, title, subtitle, imagePath, color];
}
