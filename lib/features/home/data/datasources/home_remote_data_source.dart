import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/home_data_model.dart';

/// Abstract interface for the home remote data source.
///
/// Defines API calls to the home endpoint.
/// Throws [DioException] on network/server errors which are
/// caught and mapped to [Failure] types in the repository layer.
abstract class HomeRemoteDataSource {
  /// Fetches aggregated home screen data from the API.
  ///
  /// Calls `GET /home` with the user's current location.
  /// Returns a [HomeDataModel] containing all home screen sections.
  Future<HomeDataModel> getHomeData();
}

/// Implementation of [HomeRemoteDataSource] using [ApiClient].
@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<HomeDataModel> getHomeData() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.home,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return HomeDataModel.fromJson(data);
  }
}
