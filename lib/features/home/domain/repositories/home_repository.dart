import '../../../../core/error/result.dart';
import '../entities/home_data.dart';

/// Abstract repository defining home screen data operations.
///
/// This interface is implemented in the data layer and consumed by
/// use cases in the domain layer. Returns [Result] for functional
/// error handling without exceptions.
abstract class HomeRepository {
  /// Fetches all aggregated data for the user home screen.
  ///
  /// Includes greeting (name, address), active order banner,
  /// promotional banners, service categories, featured workers,
  /// and articles.
  ///
  /// Returns [HomeData] on success.
  /// Returns [NetworkFailure] when offline with no cached data.
  /// Returns [ServerFailure] on API errors.
  Future<Result<HomeData>> getHomeData();
}
