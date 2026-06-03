import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';

/// States for the ProfileBloc.
///
/// Sealed class hierarchy representing all possible states
/// of the profile management feature.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any profile action is taken.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// State while the profile is being fetched from the API/cache.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// State when the profile has been successfully loaded.
class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.user});

  /// The current user's profile data.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// State while a profile update operation is in progress.
///
/// Retains the current user data so the UI can still display it
/// while the update is being processed.
class ProfileUpdating extends ProfileState {
  const ProfileUpdating({required this.user});

  /// The current user data before the update completes.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// State when a profile operation has failed.
///
/// Retains the previous user data (if available) so the UI can
/// retain form data on failure as per requirements.
class ProfileError extends ProfileState {
  const ProfileError({
    required this.failure,
    this.user,
  });

  /// The failure that occurred.
  final Failure failure;

  /// The previous user data, retained for form recovery.
  final User? user;

  @override
  List<Object?> get props => [failure, user];
}
