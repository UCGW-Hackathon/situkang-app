import 'dart:io';

import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/user.dart';

/// Abstract repository interface for user profile management.
///
/// Defines the contract for fetching and updating user profile data,
/// avatar uploads, and location updates. Implementations should follow
/// a cache-first strategy for reads.
abstract class ProfileRepository {
  /// Fetches the current user's profile.
  ///
  /// Returns cached data immediately if available, then fetches fresh
  /// data from the API and updates the cache.
  Future<Result<User>> getProfile();

  /// Updates the user's profile fields.
  ///
  /// Only non-null parameters are sent to the API.
  /// Returns the updated [User] on success.
  Future<Result<User>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  });

  /// Uploads a new avatar image for the user.
  ///
  /// Accepts JPG or PNG files up to 5MB.
  /// Returns the new avatar URL on success.
  Future<Result<String>> updateAvatar(File imageFile);

  /// Updates the user's current location.
  ///
  /// All parameters are required for a location update.
  Future<Result<void>> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  });
}
