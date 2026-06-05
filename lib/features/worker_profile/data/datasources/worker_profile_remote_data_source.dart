import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/worker_profile_model.dart';

abstract class WorkerProfileRemoteDataSource {
  Future<WorkerProfileModel> getWorkerProfile();
  Future<WorkerProfileModel> updateWorkerProfile(String? name, String? bio);
  Future<WorkerProfileModel> uploadCoverPhoto(String filePath);
  Future<void> submitVerification({
    required String ktpPath,
    required List<String> certificatePaths,
    String? selfiePath,
  });
  Future<WorkerProfileModel> addService(String name, int basePrice, String priceUnit);
  Future<WorkerProfileModel> removeService(String serviceId);
}

@LazySingleton(as: WorkerProfileRemoteDataSource)
class WorkerProfileRemoteDataSourceImpl implements WorkerProfileRemoteDataSource {
  const WorkerProfileRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<WorkerProfileModel> getWorkerProfile() async {
    final response = await apiClient.get<Map<String, dynamic>>(ApiEndpoints.workerProfile);
    final apiResponse = ApiResponse<WorkerProfileModel>.fromJson(
      response.data!,
      fromJsonT: (json) => WorkerProfileModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<WorkerProfileModel> updateWorkerProfile(String? name, String? bio) async {
    final response = await apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.workerProfile,
      data: {
        if (name != null) 'full_name': name,
        if (bio != null) 'bio': bio,
      },
    );
    final apiResponse = ApiResponse<WorkerProfileModel>.fromJson(
      response.data!,
      fromJsonT: (json) => WorkerProfileModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<WorkerProfileModel> uploadCoverPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'cover_photo': await MultipartFile.fromFile(filePath),
    });
    final response = await apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.workerCoverPhoto,
      data: formData,
    );
    final apiResponse = ApiResponse<WorkerProfileModel>.fromJson(
      response.data!,
      fromJsonT: (json) => WorkerProfileModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> submitVerification({
    required String ktpPath,
    required List<String> certificatePaths,
    String? selfiePath,
  }) async {
    final Map<String, dynamic> formMap = {
      'ktp': await MultipartFile.fromFile(ktpPath),
    };

    if (selfiePath != null) {
      formMap['selfie'] = await MultipartFile.fromFile(selfiePath);
    }

    final List<MultipartFile> certFiles = [];
    for (final path in certificatePaths) {
      certFiles.add(await MultipartFile.fromFile(path));
    }
    formMap['certificates[]'] = certFiles;

    await apiClient.upload<Map<String, dynamic>>(
      ApiEndpoints.workerVerification,
      data: FormData.fromMap(formMap),
    );
  }

  @override
  Future<WorkerProfileModel> addService(String name, int basePrice, String priceUnit) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/worker/profile/services',
      data: {
        'name': name,
        'base_price': basePrice,
        'price_unit': priceUnit,
      },
    );
    final apiResponse = ApiResponse<WorkerProfileModel>.fromJson(
      response.data!,
      fromJsonT: (json) => WorkerProfileModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<WorkerProfileModel> removeService(String serviceId) async {
    final response = await apiClient.delete<Map<String, dynamic>>(
      '/worker/profile/services/$serviceId',
    );
    final apiResponse = ApiResponse<WorkerProfileModel>.fromJson(
      response.data!,
      fromJsonT: (json) => WorkerProfileModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
