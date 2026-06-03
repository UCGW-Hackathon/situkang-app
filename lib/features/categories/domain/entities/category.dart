import 'package:equatable/equatable.dart';

/// Represents a service category in the SITUKANG marketplace.
///
/// Categories are top-level classifications for services (e.g., AC, Pipa, Atap).
/// Each category contains multiple [Service] offerings.
class Category extends Equatable {
  /// Creates a [Category] entity.
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.displayOrder,
    required this.isActive,
  });

  /// Unique identifier for the category.
  final String id;

  /// Display name of the category (e.g., "AC", "Pipa", "Listrik").
  final String name;

  /// Icon identifier or URL for the category.
  final String icon;

  /// Description of the category.
  final String description;

  /// Sort order for display (ascending). Used per Requirement 4.2.
  final int displayOrder;

  /// Whether the category is currently active and available.
  final bool isActive;

  @override
  List<Object?> get props => [id, name, icon, description, displayOrder, isActive];
}
