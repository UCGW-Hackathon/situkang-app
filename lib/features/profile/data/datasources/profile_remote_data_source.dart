import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Remote data source for user profile operations.
///
/// Makes API calls to the profile endpoints for fetching and updating
/// user profile data, avatar, and location.
abstract class ProfileRemoteDataSource {
  /// Fetches the current user's profile from the API.
  ///
  /// Calls `GET /users/me`.
  /// Throws an exception if the request fails.
  Future<UserModel> getProfile();

  /// Updates the user's profile fields via the API.
  ///
  /// Calls `PUT /users/me` with the provided fields.
  /// Returns the updated user data.
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  });

  /// Uploads a new avatar image via the API.
  ///
  /// Calls `PUT /users/me/avatar` with multipart form data.
  /// Returns the new avatar URL.
  Future<String> updateAvatar(File imageFile);

  /// Updates the user's location via the API.
  ///
  /// Calls `PUT /users/me/location` with latitude, longitude, and address.
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  });
}

/// Implementation of [ProfileRemoteDataSource] using [ApiClient].
@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userProfile,
    );

    final data = response.data!;
    final userData = data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final response = await apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.userProfile,
      data: body,
    );

    final data = response.data!;
    final userData = data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  @override
  Future<String> updateAvatar(File imageFile) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final response = await apiClient.upload<Map<String, dynamic>>(
      ApiEndpoints.userAvatar,
      data: formData,
    );

    final data = response.data!;
    final responseData = data['data'] as Map<String, dynamic>;
    return responseData['avatar_url'] as String;
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.userLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }
}
