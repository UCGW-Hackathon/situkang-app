import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';

class OrderProgressIcon extends StatelessWidget {
  const OrderProgressIcon({
    required this.status,
    required this.icon,
    super.key,
  });

  final OrderStatus status;
  final IconData icon;

  static const _trackColor = Color(0xFFE5E7EB);
  static const _pendingColor = Color(0xFF7B8490);
  static const _activeColor = Color(0xFF2563EB);
  static const _completedColor = Color(0xFF00AA13);
  static const _failedColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final progress = _progressForStatus(status);
    final color = _colorForStatus(status);

    return SizedBox(
      width: 52,
      height: 52,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: _trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }

  double _progressForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 0.3;
      case OrderStatus.onTheWay:
        return 0.5;
      case OrderStatus.arrived:
        return 0.65;
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
        return 0.75;
      case OrderStatus.waitingPayment:
        return 0.9;
      case OrderStatus.completed:
        return 1;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return 0;
    }
  }

  Color _colorForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _pendingColor;
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
      case OrderStatus.waitingPayment:
        return _activeColor;
      case OrderStatus.completed:
        return _completedColor;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return _failedColor;
    }
  }
}
