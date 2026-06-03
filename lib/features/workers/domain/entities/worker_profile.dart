import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';
import 'worker_service.dart';

/// Represents a worker's full profile in the SITUKANG platform.
///
/// Used in both the nearby workers list (partial data) and the
/// worker detail screen (full data). Fields that are only available
/// on the detail screen are nullable.
class WorkerProfile extends Equatable {
  const WorkerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.ratingAvg,
    required this.totalReviews,
    required this.completedJobs,
    required this.isAvailable,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.specialization,
    this.bio,
    this.verificationStatus = VerificationStatus.unverified,
    this.basePrice,
    this.priceUnit,
    this.bookingFee = 2000,
    this.distance,
    this.verifiedAt,
    this.memberSince,
    this.services = const [],
    this.latitude,
    this.longitude,
  });

  /// Unique worker profile identifier.
  final String id;

  /// The user ID associated with this worker profile.
  final String userId;

  /// Worker's full name.
  final String fullName;

  /// URL to the worker's avatar image.
  final String? avatarUrl;

  /// URL to the worker's cover photo (detail screen only).
  final String? coverPhotoUrl;

  /// Worker's specialization description.
  final String? specialization;

  /// Worker's bio/description (detail screen only).
  final String? bio;

  /// Worker's identity verification status.
  final VerificationStatus verificationStatus;

  /// Worker's base price in Rupiah.
  final int? basePrice;

  /// Price unit description (e.g., "per kunjungan").
  final String? priceUnit;

  /// Fixed booking fee in Rupiah (default Rp2.000).
  final int bookingFee;

  /// Worker's average rating (0.0–5.0).
  final double ratingAvg;

  /// Total number of reviews received.
  final int totalReviews;

  /// Total number of completed jobs.
  final int completedJobs;

  /// Whether the worker is currently available for orders.
  final bool isAvailable;

  /// Distance from the user in kilometers.
  final double? distance;

  /// When the worker was verified.
  final DateTime? verifiedAt;

  /// When the worker joined the platform.
  final DateTime? memberSince;

  /// List of services offered by this worker.
  final List<WorkerService> services;

  /// Worker's latitude coordinate.
  final double? latitude;

  /// Worker's longitude coordinate.
  final double? longitude;

  /// Whether this worker is verified.
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Creates a copy of this profile with the given fields replaced.
  WorkerProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? specialization,
    String? bio,
    VerificationStatus? verificationStatus,
    int? basePrice,
    String? priceUnit,
    int? bookingFee,
    double? ratingAvg,
    int? totalReviews,
    int? completedJobs,
    bool? isAvailable,
    double? distance,
    DateTime? verifiedAt,
    DateTime? memberSince,
    List<WorkerService>? services,
    double? latitude,
    double? longitude,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      basePrice: basePrice ?? this.basePrice,
      priceUnit: priceUnit ?? this.priceUnit,
      bookingFee: bookingFee ?? this.bookingFee,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      isAvailable: isAvailable ?? this.isAvailable,
      distance: distance ?? this.distance,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      memberSince: memberSince ?? this.memberSince,
      services: services ?? this.services,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        avatarUrl,
        coverPhotoUrl,
        specialization,
        bio,
        verificationStatus,
        basePrice,
        priceUnit,
        bookingFee,
        ratingAvg,
        totalReviews,
        completedJobs,
        isAvailable,
        distance,
        verifiedAt,
        memberSince,
        services,
        latitude,
        longitude,
      ];
}
