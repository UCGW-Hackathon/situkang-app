import 'dart:io';

import 'package:equatable/equatable.dart';

/// Events for the ProfileBloc.
///
/// Sealed class hierarchy representing all possible user actions
/// related to profile management.
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch the current user's profile.
class FetchProfile extends ProfileEvent {
  const FetchProfile();
}

/// Event to update the user's profile fields.
///
/// Only non-null fields will be sent to the API.
class UpdateProfile extends ProfileEvent {
  const UpdateProfile({
    this.fullName,
    this.phone,
    this.address,
  });

  /// Updated full name (max 255 characters).
  final String? fullName;

  /// Updated phone number (max 20 characters).
  final String? phone;

  /// Updated address.
  final String? address;

  @override
  List<Object?> get props => [fullName, phone, address];
}

/// Event to upload a new avatar image.
///
/// The image file must be JPG or PNG and not exceed 5MB.
class UpdateAvatar extends ProfileEvent {
  const UpdateAvatar({required this.imageFile});

  /// The image file to upload as the new avatar.
  final File imageFile;

  @override
  List<Object?> get props => [imageFile];
}

/// Event to update the user's current location.
class UpdateLocation extends ProfileEvent {
  const UpdateLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  /// Latitude coordinate.
  final double latitude;

  /// Longitude coordinate.
  final double longitude;

  /// Human-readable address string.
  final String address;

  @override
  List<Object?> get props => [latitude, longitude, address];
}
