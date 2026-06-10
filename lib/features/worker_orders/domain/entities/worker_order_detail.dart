import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';
import '../../../orders/domain/entities/order.dart';

class WorkerCustomerInfo extends Equatable {
  const WorkerCustomerInfo({
    required this.fullName,
    this.customerId,
    this.phone,
    this.avatarUrl,
  });

  final String? customerId;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  bool get hasName => fullName.trim().isNotEmpty;

  @override
  List<Object?> get props => [customerId, fullName, phone, avatarUrl];
}

class WorkerOrderDetail extends Equatable {
  const WorkerOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.urgency,
    required this.location,
    required this.createdAt,
    this.customer,
    this.serviceName,
    this.photos = const [],
    this.acceptedAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String title;
  final String description;
  final OrderStatus status;
  final OrderUrgency urgency;
  final OrderLocation location;
  final DateTime createdAt;
  final WorkerCustomerInfo? customer;
  final String? serviceName;
  final List<String> photos;
  final DateTime? acceptedAt;
  final DateTime? updatedAt;

  bool get hasUsableLocation =>
      location.latitude != 0 && location.longitude != 0;

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    title,
    description,
    status,
    urgency,
    location,
    createdAt,
    customer,
    serviceName,
    photos,
    acceptedAt,
    updatedAt,
  ];
}
