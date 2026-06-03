import 'package:equatable/equatable.dart';

/// Represents a worker's real-time location during order tracking.
///
/// Contains GPS coordinates, movement data, and estimated time of arrival.
/// Updated via WebSocket [LocationUpdateEvent] or REST polling fallback.
///
/// Requirements: 9.1, 9.2, 9.3
class WorkerLocation extends Equatable {
  const WorkerLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    this.eta,
  });

  /// Worker's current latitude coordinate.
  final double latitude;

  /// Worker's current longitude coordinate.
  final double longitude;

  /// Worker's heading/bearing in degrees (0-360), or null if unavailable.
  final double? heading;

  /// Worker's current speed in meters per second, or null if unavailable.
  final double? speed;

  /// GPS accuracy in meters, or null if unavailable.
  final double? accuracy;

  /// Estimated time of arrival in minutes, or null if not yet calculated.
  ///
  /// Displayed as a whole number (e.g., "8 min") or "Calculating" if null.
  final int? eta;

  /// Creates a copy of this location with the given fields replaced.
  WorkerLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? accuracy,
    int? eta,
  }) {
    return WorkerLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      eta: eta ?? this.eta,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, heading, speed, accuracy, eta];
}
