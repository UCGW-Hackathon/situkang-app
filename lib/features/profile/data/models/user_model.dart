import '../../../../core/constants/enums.dart';
import '../../../auth/domain/entities/user.dart';

/// Data Transfer Object for user profile data.
///
/// Handles JSON serialization/deserialization and conversion to/from
/// the [User] domain entity. Maps API snake_case fields to Dart camelCase.
class UserModel {
  const UserModel({
    required this.userId,
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

  /// Creates a [UserModel] from a JSON map (API response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Creates a [UserModel] from a [User] domain entity.
  factory UserModel.fromEntity(User user) {
    return UserModel(
      userId: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role.value,
      avatarUrl: user.avatarUrl,
      address: user.address,
      latitude: user.latitude,
      longitude: user.longitude,
      isActive: user.isActive,
      emailVerifiedAt: user.emailVerifiedAt,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    );
  }

  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts this model to a [User] domain entity.
  User toEntity() {
    return User(
      id: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: UserRole.fromString(role),
      avatarUrl: avatarUrl,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      emailVerifiedAt: emailVerifiedAt,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
    );
  }
}
