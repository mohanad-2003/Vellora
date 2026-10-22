import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.author,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    this.photos = const [],
    this.reply,
  });

  final String author;
  final double rating;
  final String comment;
  final String timeAgo;

  /// Addresses of the pictures the reviewer added.
  final List<String> photos;

  /// What the shop answered, when it did.
  final String? reply;

  @override
  List<Object?> get props => [author, rating, comment, timeAgo, photos, reply];
}
