part of 'worker_profile_bloc.dart';

sealed class WorkerProfileEvent extends Equatable {
  const WorkerProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkerProfile extends WorkerProfileEvent {}

class UpdateWorkerProfile extends WorkerProfileEvent {
  const UpdateWorkerProfile({
    this.name,
    this.bio,
  });

  final String? name;
  final String? bio;

  @override
  List<Object?> get props => [name, bio];
}

class UploadCoverPhoto extends WorkerProfileEvent {
  const UploadCoverPhoto(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class SubmitVerification extends WorkerProfileEvent {
  const SubmitVerification({
    required this.ktpPath,
    required this.certificatePaths,
    this.selfiePath,
  });

  final String ktpPath;
  final List<String> certificatePaths;
  final String? selfiePath;

  @override
  List<Object?> get props => [ktpPath, certificatePaths, selfiePath];
}

class AddWorkerService extends WorkerProfileEvent {
  const AddWorkerService({
    required this.name,
    required this.basePrice,
    required this.priceUnit,
  });

  final String name;
  final int basePrice;
  final String priceUnit;

  @override
  List<Object?> get props => [name, basePrice, priceUnit];
}

class RemoveWorkerService extends WorkerProfileEvent {
  const RemoveWorkerService(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}
