part of 'purchase_bloc.dart';

/// Sealed class representing all purchase management states.
///
/// The [PurchaseBloc] emits these states in response to [PurchaseEvent]s,
/// driving the UI to display the appropriate content or feedback.
sealed class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any purchase data has been loaded.
class PurchaseInitial extends PurchaseState {
  const PurchaseInitial();
}

/// State emitted while purchases are being fetched.
class PurchaseLoading extends PurchaseState {
  const PurchaseLoading();
}

/// State emitted when purchases have been successfully loaded.
///
/// Contains the purchase list, summary, and action-specific loading states.
class PurchaseLoaded extends PurchaseState {
  /// Creates a [PurchaseLoaded] state.
  const PurchaseLoaded({
    required this.purchases,
    required this.summary,
    this.actionLoadingIds = const {},
    this.actionError,
  });

  /// The list of purchases for the order.
  final List<Purchase> purchases;

  /// The aggregated purchase summary.
  final PurchaseSummary summary;

  /// Set of purchase IDs currently undergoing an action (approve/reject/clarify).
  /// Used to show per-item loading indicators.
  final Set<String> actionLoadingIds;

  /// Error from the last action attempt (approve/reject/clarify).
  /// Null if no error occurred.
  final Failure? actionError;

  /// Creates a copy of this state with optional overrides.
  PurchaseLoaded copyWith({
    List<Purchase>? purchases,
    PurchaseSummary? summary,
    Set<String>? actionLoadingIds,
    Failure? Function()? actionError,
  }) {
    return PurchaseLoaded(
      purchases: purchases ?? this.purchases,
      summary: summary ?? this.summary,
      actionLoadingIds: actionLoadingIds ?? this.actionLoadingIds,
      actionError: actionError != null ? actionError() : this.actionError,
    );
  }

  @override
  List<Object?> get props => [purchases, summary, actionLoadingIds, actionError];
}

/// State emitted when fetching purchases fails.
class PurchaseError extends PurchaseState {
  /// Creates a [PurchaseError] state with the given [failure].
  const PurchaseError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
