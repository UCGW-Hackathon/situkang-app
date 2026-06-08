import 'package:situkang_app/core/error/result.dart';

import '../entities/worker_location.dart';

abstract class LocationSharingRepository {
  Future<Result<void>> startSharing(String orderId);
  
  Future<Result<void>> stopSharing();
  
  Future<Result<void>> sendLocationUpdate(WorkerLocation location);
}
