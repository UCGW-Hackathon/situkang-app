import '../../domain/entities/article_item.dart';

/// Data Transfer Object for article API responses.
///
/// Maps snake_case JSON fields from the `/home` endpoint to the
/// domain [ArticleItem] entity.
class ArticleItemModel {
  const ArticleItemModel({
    required this.articleId,
    required this.title,
    required this.thumbnailUrl,
  });

  /// Parses an [ArticleItemModel] from a JSON map.
  factory ArticleItemModel.fromJson(Map<String, dynamic> json) {
    return ArticleItemModel(
      articleId: json['article_id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    );
  }

  final String articleId;
  final String title;
  final String thumbnailUrl;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'article_id': articleId,
      'title': title,
      'thumbnail_url': thumbnailUrl,
    };
  }

  /// Converts this data model to the domain [ArticleItem] entity.
  ArticleItem toEntity() {
    return ArticleItem(
      id: articleId,
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
  }
}
