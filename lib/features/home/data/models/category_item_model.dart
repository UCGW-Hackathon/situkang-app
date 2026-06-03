import '../../domain/entities/category_item.dart';

/// Data Transfer Object for service category API responses.
///
/// Maps snake_case JSON fields from the `/home` endpoint to the
/// domain [CategoryItem] entity.
class CategoryItemModel {
  const CategoryItemModel({
    required this.categoryId,
    required this.name,
    required this.iconUrl,
    this.slug,
    this.description,
    this.displayOrder = 0,
  });

  /// Parses a [CategoryItemModel] from a JSON map.
  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  final String categoryId;
  final String name;
  final String iconUrl;
  final String? slug;
  final String? description;
  final int displayOrder;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'icon_url': iconUrl,
      'slug': slug,
      'description': description,
      'display_order': displayOrder,
    };
  }

  /// Converts this data model to the domain [CategoryItem] entity.
  CategoryItem toEntity() {
    return CategoryItem(
      id: categoryId,
      name: name,
      icon: iconUrl,
      description: description,
      displayOrder: displayOrder,
    );
  }
}
