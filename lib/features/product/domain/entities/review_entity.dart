import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.author,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    this.photos = const [],
  });

  final String author;
  final double rating;
  final String comment;
  final String timeAgo;

  /// Addresses of the pictures the reviewer added.
  final List<String> photos;

  @override
  List<Object?> get props => [author, rating, comment, timeAgo, photos];
}
