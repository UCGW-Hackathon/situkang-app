import 'package:equatable/equatable.dart';

/// Represents a service category item in the home screen grid.
///
/// Categories include: AC, Pipa, Atap, Listrik, Kunci, Kayu, Cat, Kebun.
/// Displayed in their configured display order.
class CategoryItem extends Equatable {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
    this.displayOrder = 0,
  });

  /// Unique category identifier.
  final String id;

  /// Category name (e.g., "AC", "Pipa").
  final String name;

  /// URL to the category icon.
  final String icon;

  /// Optional category description.
  final String? description;

  /// Display order for sorting in the grid.
  final int displayOrder;

  @override
  List<Object?> get props => [id, name, icon, description, displayOrder];
}
