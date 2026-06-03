import '../../domain/entities/worker_service.dart';

/// Data model for a worker's service, mapping API JSON to domain entity.
class WorkerServiceModel {
  const WorkerServiceModel({
    required this.serviceId,
    required this.name,
    this.iconUrl,
    this.basePrice,
    this.priceUnit,
  });

  /// Creates a [WorkerServiceModel] from a JSON map.
  factory WorkerServiceModel.fromJson(Map<String, dynamic> json) {
    return WorkerServiceModel(
      serviceId: json['service_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      basePrice: json['base_price'] as int?,
      priceUnit: json['price_unit'] as String?,
    );
  }

  final String serviceId;
  final String name;
  final String? iconUrl;
  final int? basePrice;
  final String? priceUnit;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'name': name,
        'icon_url': iconUrl,
        'base_price': basePrice,
        'price_unit': priceUnit,
      };

  /// Converts this model to a domain [WorkerService] entity.
  WorkerService toEntity() => WorkerService(
        id: serviceId,
        name: name,
        iconUrl: iconUrl,
        basePrice: basePrice,
        priceUnit: priceUnit,
      );
}
