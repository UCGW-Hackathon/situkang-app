import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Filter parameters for the order list.
///
/// Used to filter orders by status in the orders tab.
class OrderFilter extends Equatable {
  const OrderFilter({
    this.status,
  });

  /// Filter by order status. When null, all orders are shown.
  final OrderStatus? status;

  /// Whether any filter is actively applied.
  bool get hasActiveFilters => status != null;

  /// Creates a copy of this filter with the given fields replaced.
  OrderFilter copyWith({
    OrderStatus? status,
  }) {
    return OrderFilter(
      status: status ?? this.status,
    );
  }

  /// Creates a copy with the status cleared (set to null).
  OrderFilter clearStatus() {
    return const OrderFilter();
  }

  @override
  List<Object?> get props => [status];
}
