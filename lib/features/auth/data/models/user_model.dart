import '../../../../core/constants/enums.dart';
import '../../domain/entities/user.dart';

/// Data Transfer Object for User API responses.
///
/// Maps snake_case JSON fields from the API to the domain [User] entity.
/// Handles nullable fields and date parsing from ISO 8601 strings.
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

  /// Parses a [UserModel] from a JSON map (API response).
  ///
  /// Handles both full user responses (e.g., from /users/me) and partial
  /// responses (e.g., from /auth/login which may omit email/phone).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['id'];
    return UserModel(
      userId: rawUserId as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String),
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'avatar_url': avatarUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      if (emailVerifiedAt != null)
        'email_verified_at': emailVerifiedAt!.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts this data model to the domain [User] entity.
  User toEntity() {
    return User(
      id: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
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
