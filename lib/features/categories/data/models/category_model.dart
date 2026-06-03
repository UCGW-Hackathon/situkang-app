import '../../domain/entities/category.dart';

/// Data Transfer Object for [Category] entity.
///
/// Maps JSON responses from the categories API endpoint to the domain entity.
class CategoryModel {
  /// Creates a [CategoryModel] from its fields.
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.displayOrder,
    required this.isActive,
  });

  /// Creates a [CategoryModel] from a JSON map.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      description: json['description'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String icon;
  final String description;
  final int displayOrder;
  final bool isActive;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'display_order': displayOrder,
        'is_active': isActive,
      };

  /// Converts this DTO to the domain [Category] entity.
  Category toEntity() => Category(
        id: id,
        name: name,
        icon: icon,
        description: description,
        displayOrder: displayOrder,
        isActive: isActive,
      );
}
