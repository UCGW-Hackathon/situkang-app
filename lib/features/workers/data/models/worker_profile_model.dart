import '../../../../core/constants/enums.dart';
import '../../domain/entities/worker_profile.dart';
import 'worker_service_model.dart';

/// Data model for a worker profile, mapping API JSON to domain entity.
///
/// Handles both the nearby workers list response (partial data) and
/// the worker detail response (full data).
class WorkerProfileModel {
  const WorkerProfileModel({
    required this.workerId,
    required this.fullName,
    required this.ratingAvg,
    required this.totalReviews,
    required this.completedJobs,
    required this.isAvailable,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.specialization,
    this.bio,
    this.isVerified = false,
    this.verificationStatus,
    this.basePrice,
    this.priceUnit,
    this.bookingFee = 2000,
    this.distanceKm,
    this.memberSince,
    this.services = const [],
    this.serviceNames = const [],
    this.latitude,
    this.longitude,
  });

  /// Creates a [WorkerProfileModel] from a JSON map.
  ///
  /// Handles both list response format (services as string array)
  /// and detail response format (services as object array).
  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    // Parse services - can be either a list of objects or a list of strings
    final rawServices = json['services'] as List<dynamic>? ?? [];
    var serviceModels = <WorkerServiceModel>[];
    var serviceNames = <String>[];

    if (rawServices.isNotEmpty) {
      if (rawServices.first is Map<String, dynamic>) {
        serviceModels = rawServices
            .map((s) =>
                WorkerServiceModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        serviceNames = rawServices.map((s) => s.toString()).toList();
      }
    }

    return WorkerProfileModel(
      workerId: json['worker_id'] as String? ?? json['user_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      specialization: json['specialization'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String?,
      ratingAvg: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool? ?? false,
      basePrice: json['base_price'] as int?,
      priceUnit: json['price_unit'] as String?,
      bookingFee: json['booking_fee'] as int? ?? 2000,
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'] as String)
          : null,
      services: serviceModels,
      serviceNames: serviceNames,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  final String workerId;
  final String fullName;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? specialization;
  final String? bio;
  final bool isVerified;
  final String? verificationStatus;
  final double ratingAvg;
  final int totalReviews;
  final int completedJobs;
  final bool isAvailable;
  final int? basePrice;
  final String? priceUnit;
  final int bookingFee;
  final double? distanceKm;
  final DateTime? memberSince;
  final List<WorkerServiceModel> services;
  final List<String> serviceNames;
  final double? latitude;
  final double? longitude;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'worker_id': workerId,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'cover_photo_url': coverPhotoUrl,
        'specialization': specialization,
        'bio': bio,
        'is_verified': isVerified,
        'verification_status': verificationStatus,
        'rating': ratingAvg,
        'total_reviews': totalReviews,
        'completed_jobs': completedJobs,
        'is_available': isAvailable,
        'base_price': basePrice,
        'price_unit': priceUnit,
        'booking_fee': bookingFee,
        'distance_km': distanceKm,
        'member_since': memberSince?.toIso8601String(),
        'services': services.isNotEmpty
            ? services.map((s) => s.toJson()).toList()
            : serviceNames,
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Converts this model to a domain [WorkerProfile] entity.
  WorkerProfile toEntity() => WorkerProfile(
        id: workerId,
        userId: workerId,
        fullName: fullName,
        avatarUrl: avatarUrl,
        coverPhotoUrl: coverPhotoUrl,
        specialization: specialization,
        bio: bio,
        verificationStatus: _parseVerificationStatus(),
        basePrice: basePrice,
        priceUnit: priceUnit,
        bookingFee: bookingFee,
        ratingAvg: ratingAvg,
        totalReviews: totalReviews,
        completedJobs: completedJobs,
        isAvailable: isAvailable,
        distance: distanceKm,
        memberSince: memberSince,
        services: services.isNotEmpty
            ? services.map((s) => s.toEntity()).toList()
            : serviceNames
                .map((name) => WorkerServiceModel(
                      serviceId: '',
                      name: name,
                    ).toEntity())
                .toList(),
        latitude: latitude,
        longitude: longitude,
      );

  VerificationStatus _parseVerificationStatus() {
    if (verificationStatus != null) {
      return VerificationStatus.fromString(verificationStatus!);
    }
    return isVerified
        ? VerificationStatus.verified
        : VerificationStatus.unverified;
  }
}
