import '../../domain/entities/worker_location.dart';

/// Data transfer object for worker location from the API.
///
/// Maps the JSON response from the tracking location endpoint
/// to the domain [WorkerLocation] entity.
class WorkerLocationModel {
  const WorkerLocationModel({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    this.eta,
  });

  /// Creates a [WorkerLocationModel] from a JSON map.
  factory WorkerLocationModel.fromJson(Map<String, dynamic> json) {
    return WorkerLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      eta: json['eta'] as int?,
    );
  }

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final int? eta;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        if (eta != null) 'eta': eta,
      };

  /// Converts this DTO to the domain entity.
  WorkerLocation toEntity() => WorkerLocation(
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
        accuracy: accuracy,
        eta: eta,
      );
}
