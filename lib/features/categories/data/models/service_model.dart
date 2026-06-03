import '../../domain/entities/service.dart';

/// Data Transfer Object for [Service] entity.
///
/// Maps JSON responses from the category services API endpoint to the domain entity.
class ServiceModel {
  /// Creates a [ServiceModel] from its fields.
  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.priceUnit,
    required this.estimatedDuration,
    required this.isActive,
  });

  /// Creates a [ServiceModel] from a JSON map.
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? json['service_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      priceUnit: json['price_unit'] as String? ?? '',
      estimatedDuration: json['estimated_duration'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int basePrice;
  final String priceUnit;
  final String estimatedDuration;
  final bool isActive;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'base_price': basePrice,
        'price_unit': priceUnit,
        'estimated_duration': estimatedDuration,
        'is_active': isActive,
      };

  /// Converts this DTO to the domain [Service] entity.
  Service toEntity() => Service(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        basePrice: basePrice,
        priceUnit: priceUnit,
        estimatedDuration: estimatedDuration,
        isActive: isActive,
      );
}
