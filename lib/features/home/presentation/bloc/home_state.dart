import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/home_data.dart';

/// States for the HomeBloc.
///
/// Sealed class hierarchy representing all possible states
/// of the home screen feature.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any home data action is taken.
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// State while home data is being fetched.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// State when home data has been successfully loaded.
///
/// Contains all aggregated data for the home screen sections.
class HomeLoaded extends HomeState {
  const HomeLoaded({required this.homeData});

  /// The aggregated home screen data.
  final HomeData homeData;

  /// Whether the user has an active order to display the banner.
  bool get hasActiveOrder => homeData.activeOrder != null;

  @override
  List<Object?> get props => [homeData];
}

/// State when fetching home data has failed.
class HomeError extends HomeState {
  const HomeError({required this.failure});

  /// The failure that occurred.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
