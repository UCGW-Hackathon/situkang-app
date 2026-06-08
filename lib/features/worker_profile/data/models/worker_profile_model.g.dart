// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerServiceModel _$WorkerServiceModelFromJson(Map<String, dynamic> json) =>
    WorkerServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      basePrice: (json['base_price'] as num).toInt(),
      priceUnit: json['price_unit'] as String,
    );

Map<String, dynamic> _$WorkerServiceModelToJson(WorkerServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'base_price': instance.basePrice,
      'price_unit': instance.priceUnit,
    };

WorkerProfileModel _$WorkerProfileModelFromJson(Map<String, dynamic> json) =>
    WorkerProfileModel(
      id: json['worker_id'] as String,
      name: json['full_name'] as String,
      phoneNumber: json['phone'] as String,
      verificationStatus: $enumDecode(
        _$VerificationStatusEnumMap,
        json['verification_status'],
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_photo_url'] as String?,
      bio: json['bio'] as String?,
      verificationReason: json['verification_reason'] as String?,
      servicesModel:
          (json['services'] as List<dynamic>?)
              ?.map(
                (e) => WorkerServiceModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkerProfileModelToJson(WorkerProfileModel instance) =>
    <String, dynamic>{
      'worker_id': instance.id,
      'full_name': instance.name,
      'avatar_url': instance.avatarUrl,
      'cover_photo_url': instance.coverUrl,
      'phone': instance.phoneNumber,
      'bio': instance.bio,
      'verification_status':
          _$VerificationStatusEnumMap[instance.verificationStatus]!,
      'verification_reason': instance.verificationReason,
      'joined_at': instance.joinedAt.toIso8601String(),
      'services': instance.servicesModel,
    };

const _$VerificationStatusEnumMap = {
  VerificationStatus.unverified: 'unverified',
  VerificationStatus.pending: 'pending',
  VerificationStatus.verified: 'verified',
  VerificationStatus.rejected: 'rejected',
};
