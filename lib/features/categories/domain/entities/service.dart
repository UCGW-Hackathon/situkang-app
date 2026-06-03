import 'package:equatable/equatable.dart';

/// Represents a specific service offering within a [Category].
///
/// Services are the individual tasks a Worker can perform
/// (e.g., "Pasang AC Baru", "Perbaikan Pipa Bocor").
class Service extends Equatable {
  /// Creates a [Service] entity.
  const Service({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.priceUnit,
    required this.estimatedDuration,
    required this.isActive,
  });

  /// Unique identifier for the service.
  final String id;

  /// The category this service belongs to.
  final String categoryId;

  /// Display name of the service.
  final String name;

  /// Description of what the service entails.
  final String description;

  /// Base price in Rupiah (integer).
  final int basePrice;

  /// Unit for the price (e.g., "per jam", "per titik", "per unit").
  final String priceUnit;

  /// Estimated duration for the service (e.g., "1-2 jam").
  final String estimatedDuration;

  /// Whether the service is currently active and available.
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        description,
        basePrice,
        priceUnit,
        estimatedDuration,
        isActive,
      ];
}
