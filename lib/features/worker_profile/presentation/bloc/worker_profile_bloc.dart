import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/worker_profile_repository.dart';

part 'worker_profile_event.dart';
part 'worker_profile_state.dart';

@injectable
class WorkerProfileBloc extends Bloc<WorkerProfileEvent, WorkerProfileState> {
  WorkerProfileBloc(this.repository) : super(WorkerProfileInitial()) {
    on<FetchWorkerProfile>(_onFetchWorkerProfile);
    on<UpdateWorkerProfile>(_onUpdateWorkerProfile);
    on<UploadCoverPhoto>(_onUploadCoverPhoto);
    on<SubmitVerification>(_onSubmitVerification);
    on<AddWorkerService>(_onAddWorkerService);
    on<RemoveWorkerService>(_onRemoveWorkerService);
  }

  final WorkerProfileRepository repository;

  Future<void> _onFetchWorkerProfile(
    FetchWorkerProfile event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileLoading());

    final result = await repository.getWorkerProfile();

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (profile) => emit(WorkerProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdateWorkerProfile(
    UpdateWorkerProfile event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileActionLoading());

    final result = await repository.updateWorkerProfile(
      name: event.name,
      bio: event.bio,
    );

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (profile) => emit(WorkerProfileLoaded(profile)),
    );
  }

  Future<void> _onUploadCoverPhoto(
    UploadCoverPhoto event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileActionLoading());

    final result = await repository.uploadCoverPhoto(event.filePath);

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (profile) => emit(WorkerProfileLoaded(profile)),
    );
  }

  Future<void> _onSubmitVerification(
    SubmitVerification event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileActionLoading());

    final result = await repository.submitVerification(
      ktpPath: event.ktpPath,
      certificatePaths: event.certificatePaths,
      selfiePath: event.selfiePath,
    );

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (_) {
        emit(WorkerProfileVerificationSubmitted());
        add(FetchWorkerProfile()); // Refresh profile to get updated status
      },
    );
  }

  Future<void> _onAddWorkerService(
    AddWorkerService event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileActionLoading());

    final result = await repository.addService(
      name: event.name,
      basePrice: event.basePrice,
      priceUnit: event.priceUnit,
    );

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (profile) => emit(WorkerProfileLoaded(profile)),
    );
  }

  Future<void> _onRemoveWorkerService(
    RemoveWorkerService event,
    Emitter<WorkerProfileState> emit,
  ) async {
    emit(WorkerProfileActionLoading());

    final result = await repository.removeService(event.serviceId);

    result.fold(
      (failure) => emit(WorkerProfileError(failure)),
      (profile) => emit(WorkerProfileLoaded(profile)),
    );
  }
}
