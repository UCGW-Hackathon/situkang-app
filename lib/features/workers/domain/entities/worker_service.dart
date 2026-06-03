import 'package:equatable/equatable.dart';

/// Represents a service offered by a worker.
///
/// Each worker can offer multiple services, each with its own
/// pricing and icon.
class WorkerService extends Equatable {
  const WorkerService({
    required this.id,
    required this.name,
    this.iconUrl,
    this.basePrice,
    this.priceUnit,
  });

  /// Unique service identifier.
  final String id;

  /// Service name (e.g., "Instalasi Listrik").
  final String name;

  /// URL to the service icon image.
  final String? iconUrl;

  /// Base price for this service in Rupiah.
  final int? basePrice;

  /// Price unit description (e.g., "per kunjungan").
  final String? priceUnit;

  @override
  List<Object?> get props => [id, name, iconUrl, basePrice, priceUnit];
}
