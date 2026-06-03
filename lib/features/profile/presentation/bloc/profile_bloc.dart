import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing user profile state.
///
/// Handles profile fetching, updating, avatar uploads, and location updates.
/// Retains previous user data on errors so the UI can preserve form state.
@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.profileRepository})
      : super(const ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateAvatar>(_onUpdateAvatar);
    on<UpdateLocation>(_onUpdateLocation);
  }

  /// The profile repository for data operations.
  final ProfileRepository profileRepository;

  /// Returns the current user from state, if available.
  User? get _currentUser {
    final currentState = state;
    if (currentState is ProfileLoaded) return currentState.user;
    if (currentState is ProfileUpdating) return currentState.user;
    if (currentState is ProfileError) return currentState.user;
    return null;
  }

  Future<void> _onFetchProfile(
    FetchProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await profileRepository.getProfile();

    result.fold(
      (failure) => emit(ProfileError(failure: failure, user: _currentUser)),
      (user) => emit(ProfileLoaded(user: user)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final previousUser = _currentUser;
    if (previousUser != null) {
      emit(ProfileUpdating(user: previousUser));
    } else {
      emit(const ProfileLoading());
    }

    final result = await profileRepository.updateProfile(
      fullName: event.fullName,
      phone: event.phone,
      address: event.address,
    );

    result.fold(
      (failure) => emit(ProfileError(failure: failure, user: previousUser)),
      (user) => emit(ProfileLoaded(user: user)),
    );
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final previousUser = _currentUser;
    if (previousUser != null) {
      emit(ProfileUpdating(user: previousUser));
    } else {
      emit(const ProfileLoading());
    }

    final result = await profileRepository.updateAvatar(event.imageFile);

    result.fold(
      (failure) => emit(ProfileError(failure: failure, user: previousUser)),
      (avatarUrl) {
        final updatedUser = previousUser?.copyWith(avatarUrl: avatarUrl);
        if (updatedUser != null) {
          emit(ProfileLoaded(user: updatedUser));
        } else {
          // If no previous user, re-fetch the profile
          add(const FetchProfile());
        }
      },
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<ProfileState> emit,
  ) async {
    final previousUser = _currentUser;
    if (previousUser != null) {
      emit(ProfileUpdating(user: previousUser));
    } else {
      emit(const ProfileLoading());
    }

    final result = await profileRepository.updateLocation(
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
    );

    result.fold(
      (failure) => emit(ProfileError(failure: failure, user: previousUser)),
      (_) {
        final updatedUser = previousUser?.copyWith(
          latitude: event.latitude,
          longitude: event.longitude,
          address: event.address,
        );
        if (updatedUser != null) {
          emit(ProfileLoaded(user: updatedUser));
        } else {
          add(const FetchProfile());
        }
      },
    );
  }
}
