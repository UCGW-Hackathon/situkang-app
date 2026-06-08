import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

class WorkerService extends Equatable {

  factory WorkerService.fromJson(Map<String, dynamic> json) {
    return WorkerService(
      id: json['id'] as String,
      name: json['name'] as String,
      basePrice: json['base_price'] as int,
      priceUnit: json['price_unit'] as String,
    );
  }
  const WorkerService({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.priceUnit,
  });

  final String id;
  final String name;
  final int basePrice;
  final String priceUnit;

  @override
  List<Object?> get props => [id, name, basePrice, priceUnit];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'base_price': basePrice,
      'price_unit': priceUnit,
    };
  }
}

class WorkerProfile extends Equatable {
  const WorkerProfile({
    required this.id,
    required this.name,
    required this.phoneNumber, required this.verificationStatus, required this.joinedAt, this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.verificationReason,
    this.services = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? coverUrl;
  final String phoneNumber;
  final String? bio;
  final VerificationStatus verificationStatus;
  final String? verificationReason;
  final List<WorkerService> services;
  final DateTime joinedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        coverUrl,
        phoneNumber,
        bio,
        verificationStatus,
        verificationReason,
        services,
        joinedAt,
      ];
}
