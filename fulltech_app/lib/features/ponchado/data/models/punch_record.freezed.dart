// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'punch_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PunchRecord _$PunchRecordFromJson(Map<String, dynamic> json) {
  return _PunchRecord.fromJson(json);
}

/// @nodoc
mixin _$PunchRecord {
  String get id => throw _privateConstructorUsedError;
  String get empresaId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  PunchType get type => throw _privateConstructorUsedError;
  DateTime get datetimeUtc => throw _privateConstructorUsedError;
  String get datetimeLocal => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  double? get locationLat => throw _privateConstructorUsedError;
  double? get locationLng => throw _privateConstructorUsedError;
  double? get locationAccuracy => throw _privateConstructorUsedError;
  String? get locationProvider => throw _privateConstructorUsedError;
  String? get addressText => throw _privateConstructorUsedError;
  bool get locationMissing => throw _privateConstructorUsedError;
  String? get deviceId => throw _privateConstructorUsedError;
  String? get deviceName => throw _privateConstructorUsedError;
  String? get platform => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  bool get isManualEdit => throw _privateConstructorUsedError;
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError; // Relations
  String? get userName => throw _privateConstructorUsedError;
  String? get userEmail => throw _privateConstructorUsedError;

  /// Serializes this PunchRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PunchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PunchRecordCopyWith<PunchRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PunchRecordCopyWith<$Res> {
  factory $PunchRecordCopyWith(
    PunchRecord value,
    $Res Function(PunchRecord) then,
  ) = _$PunchRecordCopyWithImpl<$Res, PunchRecord>;
  @useResult
  $Res call({
    String id,
    String empresaId,
    String userId,
    PunchType type,
    DateTime datetimeUtc,
    String datetimeLocal,
    String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    bool isManualEdit,
    SyncStatus syncStatus,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    String? userName,
    String? userEmail,
  });
}

/// @nodoc
class _$PunchRecordCopyWithImpl<$Res, $Val extends PunchRecord>
    implements $PunchRecordCopyWith<$Res> {
  _$PunchRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PunchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? userId = null,
    Object? type = null,
    Object? datetimeUtc = null,
    Object? datetimeLocal = null,
    Object? timezone = null,
    Object? locationLat = freezed,
    Object? locationLng = freezed,
    Object? locationAccuracy = freezed,
    Object? locationProvider = freezed,
    Object? addressText = freezed,
    Object? locationMissing = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? platform = freezed,
    Object? note = freezed,
    Object? isManualEdit = null,
    Object? syncStatus = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? userName = freezed,
    Object? userEmail = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            empresaId: null == empresaId
                ? _value.empresaId
                : empresaId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PunchType,
            datetimeUtc: null == datetimeUtc
                ? _value.datetimeUtc
                : datetimeUtc // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            datetimeLocal: null == datetimeLocal
                ? _value.datetimeLocal
                : datetimeLocal // ignore: cast_nullable_to_non_nullable
                      as String,
            timezone: null == timezone
                ? _value.timezone
                : timezone // ignore: cast_nullable_to_non_nullable
                      as String,
            locationLat: freezed == locationLat
                ? _value.locationLat
                : locationLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationLng: freezed == locationLng
                ? _value.locationLng
                : locationLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationAccuracy: freezed == locationAccuracy
                ? _value.locationAccuracy
                : locationAccuracy // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationProvider: freezed == locationProvider
                ? _value.locationProvider
                : locationProvider // ignore: cast_nullable_to_non_nullable
                      as String?,
            addressText: freezed == addressText
                ? _value.addressText
                : addressText // ignore: cast_nullable_to_non_nullable
                      as String?,
            locationMissing: null == locationMissing
                ? _value.locationMissing
                : locationMissing // ignore: cast_nullable_to_non_nullable
                      as bool,
            deviceId: freezed == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            platform: freezed == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            isManualEdit: null == isManualEdit
                ? _value.isManualEdit
                : isManualEdit // ignore: cast_nullable_to_non_nullable
                      as bool,
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SyncStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            userEmail: freezed == userEmail
                ? _value.userEmail
                : userEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PunchRecordImplCopyWith<$Res>
    implements $PunchRecordCopyWith<$Res> {
  factory _$$PunchRecordImplCopyWith(
    _$PunchRecordImpl value,
    $Res Function(_$PunchRecordImpl) then,
  ) = __$$PunchRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String empresaId,
    String userId,
    PunchType type,
    DateTime datetimeUtc,
    String datetimeLocal,
    String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    bool isManualEdit,
    SyncStatus syncStatus,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    String? userName,
    String? userEmail,
  });
}

/// @nodoc
class __$$PunchRecordImplCopyWithImpl<$Res>
    extends _$PunchRecordCopyWithImpl<$Res, _$PunchRecordImpl>
    implements _$$PunchRecordImplCopyWith<$Res> {
  __$$PunchRecordImplCopyWithImpl(
    _$PunchRecordImpl _value,
    $Res Function(_$PunchRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PunchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? userId = null,
    Object? type = null,
    Object? datetimeUtc = null,
    Object? datetimeLocal = null,
    Object? timezone = null,
    Object? locationLat = freezed,
    Object? locationLng = freezed,
    Object? locationAccuracy = freezed,
    Object? locationProvider = freezed,
    Object? addressText = freezed,
    Object? locationMissing = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? platform = freezed,
    Object? note = freezed,
    Object? isManualEdit = null,
    Object? syncStatus = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? userName = freezed,
    Object? userEmail = freezed,
  }) {
    return _then(
      _$PunchRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        empresaId: null == empresaId
            ? _value.empresaId
            : empresaId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PunchType,
        datetimeUtc: null == datetimeUtc
            ? _value.datetimeUtc
            : datetimeUtc // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        datetimeLocal: null == datetimeLocal
            ? _value.datetimeLocal
            : datetimeLocal // ignore: cast_nullable_to_non_nullable
                  as String,
        timezone: null == timezone
            ? _value.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String,
        locationLat: freezed == locationLat
            ? _value.locationLat
            : locationLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationLng: freezed == locationLng
            ? _value.locationLng
            : locationLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationAccuracy: freezed == locationAccuracy
            ? _value.locationAccuracy
            : locationAccuracy // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationProvider: freezed == locationProvider
            ? _value.locationProvider
            : locationProvider // ignore: cast_nullable_to_non_nullable
                  as String?,
        addressText: freezed == addressText
            ? _value.addressText
            : addressText // ignore: cast_nullable_to_non_nullable
                  as String?,
        locationMissing: null == locationMissing
            ? _value.locationMissing
            : locationMissing // ignore: cast_nullable_to_non_nullable
                  as bool,
        deviceId: freezed == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        platform: freezed == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        isManualEdit: null == isManualEdit
            ? _value.isManualEdit
            : isManualEdit // ignore: cast_nullable_to_non_nullable
                  as bool,
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SyncStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        userEmail: freezed == userEmail
            ? _value.userEmail
            : userEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PunchRecordImpl implements _PunchRecord {
  const _$PunchRecordImpl({
    required this.id,
    required this.empresaId,
    required this.userId,
    required this.type,
    required this.datetimeUtc,
    required this.datetimeLocal,
    required this.timezone,
    this.locationLat,
    this.locationLng,
    this.locationAccuracy,
    this.locationProvider,
    this.addressText,
    this.locationMissing = false,
    this.deviceId,
    this.deviceName,
    this.platform,
    this.note,
    this.isManualEdit = false,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.userName,
    this.userEmail,
  });

  factory _$PunchRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PunchRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String empresaId;
  @override
  final String userId;
  @override
  final PunchType type;
  @override
  final DateTime datetimeUtc;
  @override
  final String datetimeLocal;
  @override
  final String timezone;
  @override
  final double? locationLat;
  @override
  final double? locationLng;
  @override
  final double? locationAccuracy;
  @override
  final String? locationProvider;
  @override
  final String? addressText;
  @override
  @JsonKey()
  final bool locationMissing;
  @override
  final String? deviceId;
  @override
  final String? deviceName;
  @override
  final String? platform;
  @override
  final String? note;
  @override
  @JsonKey()
  final bool isManualEdit;
  @override
  @JsonKey()
  final SyncStatus syncStatus;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  // Relations
  @override
  final String? userName;
  @override
  final String? userEmail;

  @override
  String toString() {
    return 'PunchRecord(id: $id, empresaId: $empresaId, userId: $userId, type: $type, datetimeUtc: $datetimeUtc, datetimeLocal: $datetimeLocal, timezone: $timezone, locationLat: $locationLat, locationLng: $locationLng, locationAccuracy: $locationAccuracy, locationProvider: $locationProvider, addressText: $addressText, locationMissing: $locationMissing, deviceId: $deviceId, deviceName: $deviceName, platform: $platform, note: $note, isManualEdit: $isManualEdit, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, userName: $userName, userEmail: $userEmail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PunchRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.empresaId, empresaId) ||
                other.empresaId == empresaId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.datetimeUtc, datetimeUtc) ||
                other.datetimeUtc == datetimeUtc) &&
            (identical(other.datetimeLocal, datetimeLocal) ||
                other.datetimeLocal == datetimeLocal) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.locationLat, locationLat) ||
                other.locationLat == locationLat) &&
            (identical(other.locationLng, locationLng) ||
                other.locationLng == locationLng) &&
            (identical(other.locationAccuracy, locationAccuracy) ||
                other.locationAccuracy == locationAccuracy) &&
            (identical(other.locationProvider, locationProvider) ||
                other.locationProvider == locationProvider) &&
            (identical(other.addressText, addressText) ||
                other.addressText == addressText) &&
            (identical(other.locationMissing, locationMissing) ||
                other.locationMissing == locationMissing) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.isManualEdit, isManualEdit) ||
                other.isManualEdit == isManualEdit) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    empresaId,
    userId,
    type,
    datetimeUtc,
    datetimeLocal,
    timezone,
    locationLat,
    locationLng,
    locationAccuracy,
    locationProvider,
    addressText,
    locationMissing,
    deviceId,
    deviceName,
    platform,
    note,
    isManualEdit,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    userName,
    userEmail,
  ]);

  /// Create a copy of PunchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PunchRecordImplCopyWith<_$PunchRecordImpl> get copyWith =>
      __$$PunchRecordImplCopyWithImpl<_$PunchRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PunchRecordImplToJson(this);
  }
}

abstract class _PunchRecord implements PunchRecord {
  const factory _PunchRecord({
    required final String id,
    required final String empresaId,
    required final String userId,
    required final PunchType type,
    required final DateTime datetimeUtc,
    required final String datetimeLocal,
    required final String timezone,
    final double? locationLat,
    final double? locationLng,
    final double? locationAccuracy,
    final String? locationProvider,
    final String? addressText,
    final bool locationMissing,
    final String? deviceId,
    final String? deviceName,
    final String? platform,
    final String? note,
    final bool isManualEdit,
    final SyncStatus syncStatus,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? deletedAt,
    final String? userName,
    final String? userEmail,
  }) = _$PunchRecordImpl;

  factory _PunchRecord.fromJson(Map<String, dynamic> json) =
      _$PunchRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get empresaId;
  @override
  String get userId;
  @override
  PunchType get type;
  @override
  DateTime get datetimeUtc;
  @override
  String get datetimeLocal;
  @override
  String get timezone;
  @override
  double? get locationLat;
  @override
  double? get locationLng;
  @override
  double? get locationAccuracy;
  @override
  String? get locationProvider;
  @override
  String? get addressText;
  @override
  bool get locationMissing;
  @override
  String? get deviceId;
  @override
  String? get deviceName;
  @override
  String? get platform;
  @override
  String? get note;
  @override
  bool get isManualEdit;
  @override
  SyncStatus get syncStatus;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get deletedAt; // Relations
  @override
  String? get userName;
  @override
  String? get userEmail;

  /// Create a copy of PunchRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PunchRecordImplCopyWith<_$PunchRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatePunchDto _$CreatePunchDtoFromJson(Map<String, dynamic> json) {
  return _CreatePunchDto.fromJson(json);
}

/// @nodoc
mixin _$CreatePunchDto {
  PunchType get type => throw _privateConstructorUsedError;
  DateTime get datetimeUtc => throw _privateConstructorUsedError;
  String get datetimeLocal => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  double? get locationLat => throw _privateConstructorUsedError;
  double? get locationLng => throw _privateConstructorUsedError;
  double? get locationAccuracy => throw _privateConstructorUsedError;
  String? get locationProvider => throw _privateConstructorUsedError;
  String? get addressText => throw _privateConstructorUsedError;
  bool get locationMissing => throw _privateConstructorUsedError;
  String? get deviceId => throw _privateConstructorUsedError;
  String? get deviceName => throw _privateConstructorUsedError;
  String? get platform => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  SyncStatus get syncStatus => throw _privateConstructorUsedError;

  /// Serializes this CreatePunchDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatePunchDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatePunchDtoCopyWith<CreatePunchDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatePunchDtoCopyWith<$Res> {
  factory $CreatePunchDtoCopyWith(
    CreatePunchDto value,
    $Res Function(CreatePunchDto) then,
  ) = _$CreatePunchDtoCopyWithImpl<$Res, CreatePunchDto>;
  @useResult
  $Res call({
    PunchType type,
    DateTime datetimeUtc,
    String datetimeLocal,
    String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    SyncStatus syncStatus,
  });
}

/// @nodoc
class _$CreatePunchDtoCopyWithImpl<$Res, $Val extends CreatePunchDto>
    implements $CreatePunchDtoCopyWith<$Res> {
  _$CreatePunchDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatePunchDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? datetimeUtc = null,
    Object? datetimeLocal = null,
    Object? timezone = null,
    Object? locationLat = freezed,
    Object? locationLng = freezed,
    Object? locationAccuracy = freezed,
    Object? locationProvider = freezed,
    Object? addressText = freezed,
    Object? locationMissing = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? platform = freezed,
    Object? note = freezed,
    Object? syncStatus = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PunchType,
            datetimeUtc: null == datetimeUtc
                ? _value.datetimeUtc
                : datetimeUtc // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            datetimeLocal: null == datetimeLocal
                ? _value.datetimeLocal
                : datetimeLocal // ignore: cast_nullable_to_non_nullable
                      as String,
            timezone: null == timezone
                ? _value.timezone
                : timezone // ignore: cast_nullable_to_non_nullable
                      as String,
            locationLat: freezed == locationLat
                ? _value.locationLat
                : locationLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationLng: freezed == locationLng
                ? _value.locationLng
                : locationLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationAccuracy: freezed == locationAccuracy
                ? _value.locationAccuracy
                : locationAccuracy // ignore: cast_nullable_to_non_nullable
                      as double?,
            locationProvider: freezed == locationProvider
                ? _value.locationProvider
                : locationProvider // ignore: cast_nullable_to_non_nullable
                      as String?,
            addressText: freezed == addressText
                ? _value.addressText
                : addressText // ignore: cast_nullable_to_non_nullable
                      as String?,
            locationMissing: null == locationMissing
                ? _value.locationMissing
                : locationMissing // ignore: cast_nullable_to_non_nullable
                      as bool,
            deviceId: freezed == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            platform: freezed == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SyncStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatePunchDtoImplCopyWith<$Res>
    implements $CreatePunchDtoCopyWith<$Res> {
  factory _$$CreatePunchDtoImplCopyWith(
    _$CreatePunchDtoImpl value,
    $Res Function(_$CreatePunchDtoImpl) then,
  ) = __$$CreatePunchDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PunchType type,
    DateTime datetimeUtc,
    String datetimeLocal,
    String timezone,
    double? locationLat,
    double? locationLng,
    double? locationAccuracy,
    String? locationProvider,
    String? addressText,
    bool locationMissing,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? note,
    SyncStatus syncStatus,
  });
}

/// @nodoc
class __$$CreatePunchDtoImplCopyWithImpl<$Res>
    extends _$CreatePunchDtoCopyWithImpl<$Res, _$CreatePunchDtoImpl>
    implements _$$CreatePunchDtoImplCopyWith<$Res> {
  __$$CreatePunchDtoImplCopyWithImpl(
    _$CreatePunchDtoImpl _value,
    $Res Function(_$CreatePunchDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatePunchDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? datetimeUtc = null,
    Object? datetimeLocal = null,
    Object? timezone = null,
    Object? locationLat = freezed,
    Object? locationLng = freezed,
    Object? locationAccuracy = freezed,
    Object? locationProvider = freezed,
    Object? addressText = freezed,
    Object? locationMissing = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? platform = freezed,
    Object? note = freezed,
    Object? syncStatus = null,
  }) {
    return _then(
      _$CreatePunchDtoImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PunchType,
        datetimeUtc: null == datetimeUtc
            ? _value.datetimeUtc
            : datetimeUtc // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        datetimeLocal: null == datetimeLocal
            ? _value.datetimeLocal
            : datetimeLocal // ignore: cast_nullable_to_non_nullable
                  as String,
        timezone: null == timezone
            ? _value.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String,
        locationLat: freezed == locationLat
            ? _value.locationLat
            : locationLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationLng: freezed == locationLng
            ? _value.locationLng
            : locationLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationAccuracy: freezed == locationAccuracy
            ? _value.locationAccuracy
            : locationAccuracy // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationProvider: freezed == locationProvider
            ? _value.locationProvider
            : locationProvider // ignore: cast_nullable_to_non_nullable
                  as String?,
        addressText: freezed == addressText
            ? _value.addressText
            : addressText // ignore: cast_nullable_to_non_nullable
                  as String?,
        locationMissing: null == locationMissing
            ? _value.locationMissing
            : locationMissing // ignore: cast_nullable_to_non_nullable
                  as bool,
        deviceId: freezed == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        platform: freezed == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SyncStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatePunchDtoImpl implements _CreatePunchDto {
  const _$CreatePunchDtoImpl({
    required this.type,
    required this.datetimeUtc,
    required this.datetimeLocal,
    required this.timezone,
    this.locationLat,
    this.locationLng,
    this.locationAccuracy,
    this.locationProvider,
    this.addressText,
    this.locationMissing = false,
    this.deviceId,
    this.deviceName,
    this.platform,
    this.note,
    this.syncStatus = SyncStatus.pending,
  });

  factory _$CreatePunchDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatePunchDtoImplFromJson(json);

  @override
  final PunchType type;
  @override
  final DateTime datetimeUtc;
  @override
  final String datetimeLocal;
  @override
  final String timezone;
  @override
  final double? locationLat;
  @override
  final double? locationLng;
  @override
  final double? locationAccuracy;
  @override
  final String? locationProvider;
  @override
  final String? addressText;
  @override
  @JsonKey()
  final bool locationMissing;
  @override
  final String? deviceId;
  @override
  final String? deviceName;
  @override
  final String? platform;
  @override
  final String? note;
  @override
  @JsonKey()
  final SyncStatus syncStatus;

  @override
  String toString() {
    return 'CreatePunchDto(type: $type, datetimeUtc: $datetimeUtc, datetimeLocal: $datetimeLocal, timezone: $timezone, locationLat: $locationLat, locationLng: $locationLng, locationAccuracy: $locationAccuracy, locationProvider: $locationProvider, addressText: $addressText, locationMissing: $locationMissing, deviceId: $deviceId, deviceName: $deviceName, platform: $platform, note: $note, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatePunchDtoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.datetimeUtc, datetimeUtc) ||
                other.datetimeUtc == datetimeUtc) &&
            (identical(other.datetimeLocal, datetimeLocal) ||
                other.datetimeLocal == datetimeLocal) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.locationLat, locationLat) ||
                other.locationLat == locationLat) &&
            (identical(other.locationLng, locationLng) ||
                other.locationLng == locationLng) &&
            (identical(other.locationAccuracy, locationAccuracy) ||
                other.locationAccuracy == locationAccuracy) &&
            (identical(other.locationProvider, locationProvider) ||
                other.locationProvider == locationProvider) &&
            (identical(other.addressText, addressText) ||
                other.addressText == addressText) &&
            (identical(other.locationMissing, locationMissing) ||
                other.locationMissing == locationMissing) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    datetimeUtc,
    datetimeLocal,
    timezone,
    locationLat,
    locationLng,
    locationAccuracy,
    locationProvider,
    addressText,
    locationMissing,
    deviceId,
    deviceName,
    platform,
    note,
    syncStatus,
  );

  /// Create a copy of CreatePunchDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatePunchDtoImplCopyWith<_$CreatePunchDtoImpl> get copyWith =>
      __$$CreatePunchDtoImplCopyWithImpl<_$CreatePunchDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatePunchDtoImplToJson(this);
  }
}

abstract class _CreatePunchDto implements CreatePunchDto {
  const factory _CreatePunchDto({
    required final PunchType type,
    required final DateTime datetimeUtc,
    required final String datetimeLocal,
    required final String timezone,
    final double? locationLat,
    final double? locationLng,
    final double? locationAccuracy,
    final String? locationProvider,
    final String? addressText,
    final bool locationMissing,
    final String? deviceId,
    final String? deviceName,
    final String? platform,
    final String? note,
    final SyncStatus syncStatus,
  }) = _$CreatePunchDtoImpl;

  factory _CreatePunchDto.fromJson(Map<String, dynamic> json) =
      _$CreatePunchDtoImpl.fromJson;

  @override
  PunchType get type;
  @override
  DateTime get datetimeUtc;
  @override
  String get datetimeLocal;
  @override
  String get timezone;
  @override
  double? get locationLat;
  @override
  double? get locationLng;
  @override
  double? get locationAccuracy;
  @override
  String? get locationProvider;
  @override
  String? get addressText;
  @override
  bool get locationMissing;
  @override
  String? get deviceId;
  @override
  String? get deviceName;
  @override
  String? get platform;
  @override
  String? get note;
  @override
  SyncStatus get syncStatus;

  /// Create a copy of CreatePunchDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatePunchDtoImplCopyWith<_$CreatePunchDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PunchListResponse _$PunchListResponseFromJson(Map<String, dynamic> json) {
  return _PunchListResponse.fromJson(json);
}

/// @nodoc
mixin _$PunchListResponse {
  List<PunchRecord> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this PunchListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PunchListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PunchListResponseCopyWith<PunchListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PunchListResponseCopyWith<$Res> {
  factory $PunchListResponseCopyWith(
    PunchListResponse value,
    $Res Function(PunchListResponse) then,
  ) = _$PunchListResponseCopyWithImpl<$Res, PunchListResponse>;
  @useResult
  $Res call({List<PunchRecord> items, int total, int limit, int offset});
}

/// @nodoc
class _$PunchListResponseCopyWithImpl<$Res, $Val extends PunchListResponse>
    implements $PunchListResponseCopyWith<$Res> {
  _$PunchListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PunchListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<PunchRecord>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            offset: null == offset
                ? _value.offset
                : offset // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PunchListResponseImplCopyWith<$Res>
    implements $PunchListResponseCopyWith<$Res> {
  factory _$$PunchListResponseImplCopyWith(
    _$PunchListResponseImpl value,
    $Res Function(_$PunchListResponseImpl) then,
  ) = __$$PunchListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PunchRecord> items, int total, int limit, int offset});
}

/// @nodoc
class __$$PunchListResponseImplCopyWithImpl<$Res>
    extends _$PunchListResponseCopyWithImpl<$Res, _$PunchListResponseImpl>
    implements _$$PunchListResponseImplCopyWith<$Res> {
  __$$PunchListResponseImplCopyWithImpl(
    _$PunchListResponseImpl _value,
    $Res Function(_$PunchListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PunchListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _$PunchListResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PunchRecord>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        offset: null == offset
            ? _value.offset
            : offset // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PunchListResponseImpl implements _PunchListResponse {
  const _$PunchListResponseImpl({
    required final List<PunchRecord> items,
    required this.total,
    required this.limit,
    required this.offset,
  }) : _items = items;

  factory _$PunchListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PunchListResponseImplFromJson(json);

  final List<PunchRecord> _items;
  @override
  List<PunchRecord> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int limit;
  @override
  final int offset;

  @override
  String toString() {
    return 'PunchListResponse(items: $items, total: $total, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PunchListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    limit,
    offset,
  );

  /// Create a copy of PunchListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PunchListResponseImplCopyWith<_$PunchListResponseImpl> get copyWith =>
      __$$PunchListResponseImplCopyWithImpl<_$PunchListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PunchListResponseImplToJson(this);
  }
}

abstract class _PunchListResponse implements PunchListResponse {
  const factory _PunchListResponse({
    required final List<PunchRecord> items,
    required final int total,
    required final int limit,
    required final int offset,
  }) = _$PunchListResponseImpl;

  factory _PunchListResponse.fromJson(Map<String, dynamic> json) =
      _$PunchListResponseImpl.fromJson;

  @override
  List<PunchRecord> get items;
  @override
  int get total;
  @override
  int get limit;
  @override
  int get offset;

  /// Create a copy of PunchListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PunchListResponseImplCopyWith<_$PunchListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PunchSummary _$PunchSummaryFromJson(Map<String, dynamic> json) {
  return _PunchSummary.fromJson(json);
}

/// @nodoc
mixin _$PunchSummary {
  int get daysWorked => throw _privateConstructorUsedError;
  int get totalPunches => throw _privateConstructorUsedError;
  double get totalHours => throw _privateConstructorUsedError;
  double get totalLunchHours => throw _privateConstructorUsedError;
  double get effectiveHours => throw _privateConstructorUsedError;
  Map<String, int> get byType => throw _privateConstructorUsedError;

  /// Serializes this PunchSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PunchSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PunchSummaryCopyWith<PunchSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PunchSummaryCopyWith<$Res> {
  factory $PunchSummaryCopyWith(
    PunchSummary value,
    $Res Function(PunchSummary) then,
  ) = _$PunchSummaryCopyWithImpl<$Res, PunchSummary>;
  @useResult
  $Res call({
    int daysWorked,
    int totalPunches,
    double totalHours,
    double totalLunchHours,
    double effectiveHours,
    Map<String, int> byType,
  });
}

/// @nodoc
class _$PunchSummaryCopyWithImpl<$Res, $Val extends PunchSummary>
    implements $PunchSummaryCopyWith<$Res> {
  _$PunchSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PunchSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? daysWorked = null,
    Object? totalPunches = null,
    Object? totalHours = null,
    Object? totalLunchHours = null,
    Object? effectiveHours = null,
    Object? byType = null,
  }) {
    return _then(
      _value.copyWith(
            daysWorked: null == daysWorked
                ? _value.daysWorked
                : daysWorked // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPunches: null == totalPunches
                ? _value.totalPunches
                : totalPunches // ignore: cast_nullable_to_non_nullable
                      as int,
            totalHours: null == totalHours
                ? _value.totalHours
                : totalHours // ignore: cast_nullable_to_non_nullable
                      as double,
            totalLunchHours: null == totalLunchHours
                ? _value.totalLunchHours
                : totalLunchHours // ignore: cast_nullable_to_non_nullable
                      as double,
            effectiveHours: null == effectiveHours
                ? _value.effectiveHours
                : effectiveHours // ignore: cast_nullable_to_non_nullable
                      as double,
            byType: null == byType
                ? _value.byType
                : byType // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PunchSummaryImplCopyWith<$Res>
    implements $PunchSummaryCopyWith<$Res> {
  factory _$$PunchSummaryImplCopyWith(
    _$PunchSummaryImpl value,
    $Res Function(_$PunchSummaryImpl) then,
  ) = __$$PunchSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int daysWorked,
    int totalPunches,
    double totalHours,
    double totalLunchHours,
    double effectiveHours,
    Map<String, int> byType,
  });
}

/// @nodoc
class __$$PunchSummaryImplCopyWithImpl<$Res>
    extends _$PunchSummaryCopyWithImpl<$Res, _$PunchSummaryImpl>
    implements _$$PunchSummaryImplCopyWith<$Res> {
  __$$PunchSummaryImplCopyWithImpl(
    _$PunchSummaryImpl _value,
    $Res Function(_$PunchSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PunchSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? daysWorked = null,
    Object? totalPunches = null,
    Object? totalHours = null,
    Object? totalLunchHours = null,
    Object? effectiveHours = null,
    Object? byType = null,
  }) {
    return _then(
      _$PunchSummaryImpl(
        daysWorked: null == daysWorked
            ? _value.daysWorked
            : daysWorked // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPunches: null == totalPunches
            ? _value.totalPunches
            : totalPunches // ignore: cast_nullable_to_non_nullable
                  as int,
        totalHours: null == totalHours
            ? _value.totalHours
            : totalHours // ignore: cast_nullable_to_non_nullable
                  as double,
        totalLunchHours: null == totalLunchHours
            ? _value.totalLunchHours
            : totalLunchHours // ignore: cast_nullable_to_non_nullable
                  as double,
        effectiveHours: null == effectiveHours
            ? _value.effectiveHours
            : effectiveHours // ignore: cast_nullable_to_non_nullable
                  as double,
        byType: null == byType
            ? _value._byType
            : byType // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PunchSummaryImpl implements _PunchSummary {
  const _$PunchSummaryImpl({
    required this.daysWorked,
    required this.totalPunches,
    required this.totalHours,
    required this.totalLunchHours,
    required this.effectiveHours,
    required final Map<String, int> byType,
  }) : _byType = byType;

  factory _$PunchSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PunchSummaryImplFromJson(json);

  @override
  final int daysWorked;
  @override
  final int totalPunches;
  @override
  final double totalHours;
  @override
  final double totalLunchHours;
  @override
  final double effectiveHours;
  final Map<String, int> _byType;
  @override
  Map<String, int> get byType {
    if (_byType is EqualUnmodifiableMapView) return _byType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byType);
  }

  @override
  String toString() {
    return 'PunchSummary(daysWorked: $daysWorked, totalPunches: $totalPunches, totalHours: $totalHours, totalLunchHours: $totalLunchHours, effectiveHours: $effectiveHours, byType: $byType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PunchSummaryImpl &&
            (identical(other.daysWorked, daysWorked) ||
                other.daysWorked == daysWorked) &&
            (identical(other.totalPunches, totalPunches) ||
                other.totalPunches == totalPunches) &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours) &&
            (identical(other.totalLunchHours, totalLunchHours) ||
                other.totalLunchHours == totalLunchHours) &&
            (identical(other.effectiveHours, effectiveHours) ||
                other.effectiveHours == effectiveHours) &&
            const DeepCollectionEquality().equals(other._byType, _byType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    daysWorked,
    totalPunches,
    totalHours,
    totalLunchHours,
    effectiveHours,
    const DeepCollectionEquality().hash(_byType),
  );

  /// Create a copy of PunchSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PunchSummaryImplCopyWith<_$PunchSummaryImpl> get copyWith =>
      __$$PunchSummaryImplCopyWithImpl<_$PunchSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PunchSummaryImplToJson(this);
  }
}

abstract class _PunchSummary implements PunchSummary {
  const factory _PunchSummary({
    required final int daysWorked,
    required final int totalPunches,
    required final double totalHours,
    required final double totalLunchHours,
    required final double effectiveHours,
    required final Map<String, int> byType,
  }) = _$PunchSummaryImpl;

  factory _PunchSummary.fromJson(Map<String, dynamic> json) =
      _$PunchSummaryImpl.fromJson;

  @override
  int get daysWorked;
  @override
  int get totalPunches;
  @override
  double get totalHours;
  @override
  double get totalLunchHours;
  @override
  double get effectiveHours;
  @override
  Map<String, int> get byType;

  /// Create a copy of PunchSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PunchSummaryImplCopyWith<_$PunchSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
