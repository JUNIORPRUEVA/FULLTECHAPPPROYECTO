import 'package:freezed_annotation/freezed_annotation.dart';

part 'punch_record.freezed.dart';
part 'punch_record.g.dart';

enum PunchType {
  @JsonValue('IN')
  in_,
  @JsonValue('LUNCH_START')
  lunchStart,
  @JsonValue('LUNCH_END')
  lunchEnd,
  @JsonValue('OUT')
  out,
}

enum SyncStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('SYNCED')
  synced,
  @JsonValue('FAILED')
  failed,
}

@freezed
class PunchRecord with _$PunchRecord {
  const factory PunchRecord({
    required String id,
    required String empresaId,
    required String userId,
    required PunchType type,
    required DateTime datetimeUtc,
    required String datetimeLocal,
    required String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    @Default(false) bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    @Default(false) bool isManualEdit,
    @Default(SyncStatus.synced) SyncStatus syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    // Relations
    String? userName,
    String? userEmail,
  }) = _PunchRecord;

  factory PunchRecord.fromJson(Map<String, dynamic> json) =>
      _$PunchRecordFromJson(json);
}

@freezed
class CreatePunchDto with _$CreatePunchDto {
  const factory CreatePunchDto({
    required PunchType type,
    required DateTime datetimeUtc,
    required String datetimeLocal,
    required String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    @Default(false) bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _CreatePunchDto;

  factory CreatePunchDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePunchDtoFromJson(json);
}

@freezed
class PunchListResponse with _$PunchListResponse {
  const factory PunchListResponse({
    required List<PunchRecord> items,
    required int total,
    required int limit,
    required int offset,
  }) = _PunchListResponse;

  factory PunchListResponse.fromJson(Map<String, dynamic> json) =>
      _$PunchListResponseFromJson(json);
}

@freezed
class PunchSummary with _$PunchSummary {
  const factory PunchSummary({
    required int daysWorked,
    required int totalPunches,
    required double totalHours,
    required double totalLunchHours,
    required double effectiveHours,
    required Map<String, int> byType,
  }) = _PunchSummary;

  factory PunchSummary.fromJson(Map<String, dynamic> json) =>
      _$PunchSummaryFromJson(json);
}
