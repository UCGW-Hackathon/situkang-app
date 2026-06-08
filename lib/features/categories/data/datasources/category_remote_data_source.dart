import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';

/// Abstract interface for the category remote data source.
///
/// Defines API calls to the categories endpoints.
/// Throws [DioException] on network/server errors which are
/// caught and mapped to [Failure] types in the repository layer.
abstract class CategoryRemoteDataSource {
  /// Fetches all categories from the API.
  ///
  /// Calls `GET /categories`.
  /// Returns a list of [CategoryModel] on success.
  Future<List<CategoryModel>> getCategories();

  /// Fetches services for a specific category.
  ///
  /// Calls `GET /categories/:categoryId/services`.
  /// Returns a list of [ServiceModel] on success.
  /// Throws [DioException] with 404 if category not found or inactive.
  Future<List<ServiceModel>> getCategoryServices(String categoryId);
}

/// Implementation of [CategoryRemoteDataSource] using [ApiClient].
@LazySingleton(as: CategoryRemoteDataSource)
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  /// Creates a [CategoryRemoteDataSourceImpl] with the given [apiClient].
  const CategoryRemoteDataSourceImpl({required this.apiClient});

  /// The API client used for HTTP requests.
  final ApiClient apiClient;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
    );

    final data = response.data!['data'];
    final List<dynamic> categoriesList;

    if (data is List) {
      categoriesList = data;
    } else if (data is Map<String, dynamic> && data.containsKey('categories')) {
      categoriesList = data['categories'] as List<dynamic>;
    } else {
      categoriesList = [];
    }

    return categoriesList
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ServiceModel>> getCategoryServices(String categoryId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categoryServices(categoryId),
    );

    final data = response.data!['data'];
    final List<dynamic> servicesList;

    if (data is List) {
      servicesList = data;
    } else if (data is Map<String, dynamic> && data.containsKey('services')) {
      servicesList = data['services'] as List<dynamic>;
    } else {
      servicesList = [];
    }

    return servicesList
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
