import '../../../../core/error/result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/worker_profile.dart';

abstract class WorkerProfileRepository {
  Future<Result<WorkerProfile>> getWorkerProfile();

  Future<Result<WorkerProfile>> updateWorkerProfile({
    String? name,
    String? bio,
  });

  Future<Result<WorkerProfile>> uploadCoverPhoto(String filePath);

  Future<Result<void>> submitVerification({
    required String ktpPath,
    required List<String> certificatePaths,
    String? selfiePath,
  });

  Future<Result<WorkerProfile>> addService({
    required String name,
    required int basePrice,
    required String priceUnit,
  });

  Future<Result<WorkerProfile>> removeService(String serviceId);
}
