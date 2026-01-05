// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'punch_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PunchRecordImpl _$$PunchRecordImplFromJson(Map<String, dynamic> json) =>
    _$PunchRecordImpl(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$PunchTypeEnumMap, json['type']),
      datetimeUtc: DateTime.parse(json['datetimeUtc'] as String),
      datetimeLocal: json['datetimeLocal'] as String,
      timezone: json['timezone'] as String,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble(),
      locationProvider: json['locationProvider'] as String?,
      addressText: json['addressText'] as String?,
      locationMissing: json['locationMissing'] as bool? ?? false,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
      note: json['note'] as String?,
      isManualEdit: json['isManualEdit'] as bool? ?? false,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
          SyncStatus.synced,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
    );

Map<String, dynamic> _$$PunchRecordImplToJson(_$PunchRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'empresaId': instance.empresaId,
      'userId': instance.userId,
      'type': _$PunchTypeEnumMap[instance.type]!,
      'datetimeUtc': instance.datetimeUtc.toIso8601String(),
      'datetimeLocal': instance.datetimeLocal,
      'timezone': instance.timezone,
      'locationLat': instance.locationLat,
      'locationLng': instance.locationLng,
      'locationAccuracy': instance.locationAccuracy,
      'locationProvider': instance.locationProvider,
      'addressText': instance.addressText,
      'locationMissing': instance.locationMissing,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'platform': instance.platform,
      'note': instance.note,
      'isManualEdit': instance.isManualEdit,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'userName': instance.userName,
      'userEmail': instance.userEmail,
    };

const _$PunchTypeEnumMap = {
  PunchType.in_: 'IN',
  PunchType.lunchStart: 'LUNCH_START',
  PunchType.lunchEnd: 'LUNCH_END',
  PunchType.out: 'OUT',
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'PENDING',
  SyncStatus.synced: 'SYNCED',
  SyncStatus.failed: 'FAILED',
};

_$CreatePunchDtoImpl _$$CreatePunchDtoImplFromJson(Map<String, dynamic> json) =>
    _$CreatePunchDtoImpl(
      type: $enumDecode(_$PunchTypeEnumMap, json['type']),
      datetimeUtc: DateTime.parse(json['datetimeUtc'] as String),
      datetimeLocal: json['datetimeLocal'] as String,
      timezone: json['timezone'] as String,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble(),
      locationProvider: json['locationProvider'] as String?,
      addressText: json['addressText'] as String?,
      locationMissing: json['locationMissing'] as bool? ?? false,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
      note: json['note'] as String?,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
          SyncStatus.pending,
    );

Map<String, dynamic> _$$CreatePunchDtoImplToJson(
  _$CreatePunchDtoImpl instance,
) => <String, dynamic>{
  'type': _$PunchTypeEnumMap[instance.type]!,
  'datetimeUtc': instance.datetimeUtc.toIso8601String(),
  'datetimeLocal': instance.datetimeLocal,
  'timezone': instance.timezone,
  'locationLat': instance.locationLat,
  'locationLng': instance.locationLng,
  'locationAccuracy': instance.locationAccuracy,
  'locationProvider': instance.locationProvider,
  'addressText': instance.addressText,
  'locationMissing': instance.locationMissing,
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'platform': instance.platform,
  'note': instance.note,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

_$PunchListResponseImpl _$$PunchListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PunchListResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => PunchRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
);

Map<String, dynamic> _$$PunchListResponseImplToJson(
  _$PunchListResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'limit': instance.limit,
  'offset': instance.offset,
};

_$PunchSummaryImpl _$$PunchSummaryImplFromJson(Map<String, dynamic> json) =>
    _$PunchSummaryImpl(
      daysWorked: (json['daysWorked'] as num).toInt(),
      totalPunches: (json['totalPunches'] as num).toInt(),
      totalHours: (json['totalHours'] as num).toDouble(),
      totalLunchHours: (json['totalLunchHours'] as num).toDouble(),
      effectiveHours: (json['effectiveHours'] as num).toDouble(),
      byType: Map<String, int>.from(json['byType'] as Map),
    );

Map<String, dynamic> _$$PunchSummaryImplToJson(_$PunchSummaryImpl instance) =>
    <String, dynamic>{
      'daysWorked': instance.daysWorked,
      'totalPunches': instance.totalPunches,
      'totalHours': instance.totalHours,
      'totalLunchHours': instance.totalLunchHours,
      'effectiveHours': instance.effectiveHours,
      'byType': instance.byType,
    };
