import 'package:equatable/equatable.dart';

/// Represents an article card displayed on the home screen.
///
/// Each article shows a thumbnail, title, and read call-to-action label.
class ArticleItem extends Equatable {
  const ArticleItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  /// Unique article identifier.
  final String id;

  /// Article title.
  final String title;

  /// URL to the article thumbnail image.
  final String thumbnailUrl;

  @override
  List<Object?> get props => [id, title, thumbnailUrl];
}
