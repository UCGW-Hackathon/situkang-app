import 'package:equatable/equatable.dart';

/// Events for the HomeBloc.
///
/// Sealed class hierarchy representing all possible user actions
/// related to the home screen.
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch all home screen data.
///
/// Triggered when the home screen is first opened.
class FetchHomeData extends HomeEvent {
  const FetchHomeData();
}

/// Event to refresh home screen data.
///
/// Triggered by pull-to-refresh or manual refresh action.
class RefreshHomeData extends HomeEvent {
  const RefreshHomeData();
}
