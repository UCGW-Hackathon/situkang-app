import '../../../../core/constants/enums.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/worker_order_detail.dart';

class WorkerOrderDetailModel {
  const WorkerOrderDetailModel({
    required this.orderId,
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

  factory WorkerOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final nestedOrder = _asMap(json['order']);
    final orderJson = <String, dynamic>{
      ...json,
      if (nestedOrder != null) ...nestedOrder,
    };

    final serviceJson = _asMap(orderJson['service']);
    final customerJson =
        _asMap(orderJson['customer']) ??
        _asMap(orderJson['user']) ??
        _asMap(json['customer']) ??
        _asMap(json['user']) ??
        orderJson;

    final customer = WorkerCustomerInfoModel.fromJson(customerJson);

    return WorkerOrderDetailModel(
      orderId: _string(orderJson, const ['order_id', 'id']) ?? '',
      orderNumber: _string(orderJson, const ['order_number']) ?? '',
      title: _string(orderJson, const ['title']) ?? '',
      description:
          _string(orderJson, const ['description', 'problem_description']) ??
          '',
      status: OrderStatus.fromString(
        _string(orderJson, const ['status']) ?? 'pending',
      ),
      urgency: OrderUrgency.fromString(
        _string(orderJson, const ['urgency']) ?? 'normal',
      ),
      location: _parseLocation(orderJson),
      createdAt: _dateTime(orderJson, const ['created_at']) ?? DateTime.now(),
      customer: customer.hasData ? customer : null,
      serviceName:
          _string(orderJson, const ['service_name']) ??
          _string(serviceJson, const ['name']),
      photos: _parsePhotos(orderJson),
      acceptedAt: _dateTime(orderJson, const ['accepted_at']),
      updatedAt: _dateTime(orderJson, const ['updated_at']),
    );
  }

  final String orderId;
  final String orderNumber;
  final String title;
  final String description;
  final OrderStatus status;
  final OrderUrgency urgency;
  final OrderLocation location;
  final DateTime createdAt;
  final WorkerCustomerInfoModel? customer;
  final String? serviceName;
  final List<String> photos;
  final DateTime? acceptedAt;
  final DateTime? updatedAt;

  WorkerOrderDetail toEntity() => WorkerOrderDetail(
    id: orderId,
    orderNumber: orderNumber,
    title: title,
    description: description,
    status: status,
    urgency: urgency,
    location: location,
    createdAt: createdAt,
    customer: customer?.toEntity(),
    serviceName: serviceName,
    photos: photos,
    acceptedAt: acceptedAt,
    updatedAt: updatedAt,
  );

  static OrderLocation _parseLocation(Map<String, dynamic> json) {
    final locationJson = _asMap(json['location']) ?? json;
    return OrderLocation(
      latitude:
          _double(locationJson, const ['latitude', 'lat', 'location_lat']) ??
          _double(json, const ['location_lat']) ??
          0,
      longitude:
          _double(locationJson, const ['longitude', 'lng', 'location_lng']) ??
          _double(json, const ['location_lng']) ??
          0,
      address:
          _string(locationJson, const ['address', 'location_address']) ??
          _string(json, const ['location_address']) ??
          '',
      addressDetail:
          _string(locationJson, const ['address_detail', 'location_detail']) ??
          _string(json, const ['location_detail']),
    );
  }

  static List<String> _parsePhotos(Map<String, dynamic> json) {
    final raw = json['photos'] ?? json['order_photos'] ?? json['photo_urls'];
    if (raw is! List) return const [];

    return raw
        .map((item) {
          if (item is String) return item;
          final map = _asMap(item);
          if (map == null) return null;
          return _string(map, const ['photo_url', 'url', 'image_url']);
        })
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class WorkerCustomerInfoModel {
  const WorkerCustomerInfoModel({
    required this.fullName,
    this.customerId,
    this.phone,
    this.avatarUrl,
  });

  factory WorkerCustomerInfoModel.fromJson(Map<String, dynamic> json) {
    return WorkerCustomerInfoModel(
      customerId: _string(json, const ['customer_id', 'user_id', 'id']),
      fullName:
          _string(json, const [
            'customer_name',
            'full_name',
            'name',
            'user_name',
          ]) ??
          '',
      phone: _string(json, const ['customer_phone', 'phone']),
      avatarUrl: _string(json, const [
        'customer_avatar',
        'customer_avatar_url',
        'avatar_url',
      ]),
    );
  }

  final String? customerId;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  bool get hasData =>
      fullName.trim().isNotEmpty ||
      (phone != null && phone!.trim().isNotEmpty) ||
      (avatarUrl != null && avatarUrl!.trim().isNotEmpty);

  WorkerCustomerInfo toEntity() => WorkerCustomerInfo(
    customerId: customerId,
    fullName: fullName,
    phone: phone,
    avatarUrl: avatarUrl,
  );
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _string(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

double? _double(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? _dateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _string(json, keys);
  if (value == null) return null;
  return DateTime.tryParse(value);
}
