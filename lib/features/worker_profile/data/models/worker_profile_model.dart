import 'package:json_annotation/json_annotation.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/worker_profile.dart';

part 'worker_profile_model.g.dart';

@JsonSerializable()
class WorkerServiceModel extends WorkerService {
  const WorkerServiceModel({
    required super.id,
    required super.name,
    @JsonKey(name: 'base_price') required super.basePrice,
    @JsonKey(name: 'price_unit') required super.priceUnit,
  });

  factory WorkerServiceModel.fromJson(Map<String, dynamic> json) {
    return WorkerServiceModel(
      id: json['id'] as String? ?? json['service_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      basePrice: (json['base_price'] as num?)?.toInt() ?? 0,
      priceUnit: json['price_unit'] as String? ?? 'per kunjungan',
    );
  }

  @override
  Map<String, dynamic> toJson() => _$WorkerServiceModelToJson(this);
}

@JsonSerializable()
class WorkerProfileModel extends WorkerProfile {
  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    if (json['joined_at'] == null) {
      json['joined_at'] = DateTime.now().toIso8601String();
    }
    return _$WorkerProfileModelFromJson(json);
  }

  const WorkerProfileModel({
    @JsonKey(name: 'worker_id') required super.id,
    @JsonKey(name: 'full_name') required super.name,
    @JsonKey(name: 'phone') required super.phoneNumber,
    @JsonKey(name: 'verification_status') required super.verificationStatus,
    @JsonKey(name: 'joined_at') required super.joinedAt,
    @JsonKey(name: 'avatar_url') super.avatarUrl,
    @JsonKey(name: 'cover_photo_url') super.coverUrl,
    super.bio,
    @JsonKey(name: 'verification_reason') super.verificationReason,
    this.servicesModel = const [],
  }) : super(services: servicesModel);

  @JsonKey(name: 'services')
  final List<WorkerServiceModel> servicesModel;

  Map<String, dynamic> toJson() => _$WorkerProfileModelToJson(this);
}
