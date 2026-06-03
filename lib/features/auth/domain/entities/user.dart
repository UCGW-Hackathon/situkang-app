import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Represents an authenticated user in the SITUKANG platform.
///
/// This entity is shared across features (auth, profile, home) and contains
/// the core user data returned by the API.
class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.emailVerifiedAt,
    this.lastLoginAt,
  });

  /// Unique user identifier (UUID).
  final String id;

  /// User's full name (max 255 characters).
  final String fullName;

  /// User's email address.
  final String email;

  /// User's phone number with country code (max 20 characters).
  final String phone;

  /// User's role in the platform.
  final UserRole role;

  /// URL to the user's avatar image, or null if not set.
  final String? avatarUrl;

  /// User's address string, or null if not set.
  final String? address;

  /// User's latitude coordinate, or null if location not set.
  final double? latitude;

  /// User's longitude coordinate, or null if location not set.
  final double? longitude;

  /// Whether the user account is active.
  final bool isActive;

  /// When the user's email was verified, or null if not verified.
  final DateTime? emailVerifiedAt;

  /// When the user last logged in, or null if never.
  final DateTime? lastLoginAt;

  /// When the user account was created.
  final DateTime createdAt;

  /// Creates a copy of this user with the given fields replaced.
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? emailVerifiedAt,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        role,
        avatarUrl,
        address,
        latitude,
        longitude,
        isActive,
        emailVerifiedAt,
        lastLoginAt,
        createdAt,
      ];
}
