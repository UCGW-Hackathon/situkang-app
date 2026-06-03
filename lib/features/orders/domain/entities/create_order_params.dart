import 'dart:io';

import 'package:equatable/equatable.dart';

/// Parameters for creating a new order.
///
/// Contains all required and optional fields for the order creation API.
/// Used as input to the CreateOrder use case and repository method.
class CreateOrderParams extends Equatable {
  const CreateOrderParams({
    required this.workerId,
    required this.serviceId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressDetail,
    this.notes,
    this.urgency = 'normal',
    this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.photos = const [],
  });

  /// Selected worker's ID.
  final String workerId;

  /// Selected service ID.
  final String serviceId;

  /// Order title (max 255 characters).
  final String title;

  /// Problem description (max 2000 characters).
  final String description;

  /// Work location latitude.
  final double latitude;

  /// Work location longitude.
  final double longitude;

  /// Full address string.
  final String address;

  /// Additional address details (max 500 characters).
  final String? addressDetail;

  /// Additional notes for the worker (max 1000 characters).
  final String? notes;

  /// Urgency level: "normal" or "urgent".
  final String urgency;

  /// Preferred date for the service (YYYY-MM-DD format).
  final String? preferredDate;

  /// Preferred start time (HH:MM format).
  final String? preferredTimeStart;

  /// Preferred end time (HH:MM format).
  final String? preferredTimeEnd;

  /// Photos illustrating the problem (max 5, each max 5MB, JPG/PNG).
  final List<File> photos;

  @override
  List<Object?> get props => [
        workerId,
        serviceId,
        title,
        description,
        latitude,
        longitude,
        address,
        addressDetail,
        notes,
        urgency,
        preferredDate,
        preferredTimeStart,
        preferredTimeEnd,
        photos,
      ];
}
