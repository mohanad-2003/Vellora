import 'package:equatable/equatable.dart';

/// A shopping category. [name] is the fallback label; the UI localizes by [id]
/// (see `categoryLabel`), so a backend can later send its own names.
class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.imagePath,
    this.productCount = 0,
  });

  final String id;
  final String name;

  /// Representative photo shown on category cards.
  final String imagePath;
  final int productCount;

  @override
  List<Object?> get props => [id, name, imagePath, productCount];
}
