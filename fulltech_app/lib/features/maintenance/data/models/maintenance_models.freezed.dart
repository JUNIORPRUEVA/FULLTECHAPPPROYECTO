// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProductBasicInfo _$ProductBasicInfoFromJson(Map<String, dynamic> json) {
  return _ProductBasicInfo.fromJson(json);
}

/// @nodoc
mixin _$ProductBasicInfo {
  String get id => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  String? get imagenUrl => throw _privateConstructorUsedError;
  double? get precioVenta => throw _privateConstructorUsedError;

  /// Serializes this ProductBasicInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductBasicInfoCopyWith<ProductBasicInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductBasicInfoCopyWith<$Res> {
  factory $ProductBasicInfoCopyWith(
    ProductBasicInfo value,
    $Res Function(ProductBasicInfo) then,
  ) = _$ProductBasicInfoCopyWithImpl<$Res, ProductBasicInfo>;
  @useResult
  $Res call({String id, String nombre, String? imagenUrl, double? precioVenta});
}

/// @nodoc
class _$ProductBasicInfoCopyWithImpl<$Res, $Val extends ProductBasicInfo>
    implements $ProductBasicInfoCopyWith<$Res> {
  _$ProductBasicInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? imagenUrl = freezed,
    Object? precioVenta = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nombre: null == nombre
                ? _value.nombre
                : nombre // ignore: cast_nullable_to_non_nullable
                      as String,
            imagenUrl: freezed == imagenUrl
                ? _value.imagenUrl
                : imagenUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            precioVenta: freezed == precioVenta
                ? _value.precioVenta
                : precioVenta // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductBasicInfoImplCopyWith<$Res>
    implements $ProductBasicInfoCopyWith<$Res> {
  factory _$$ProductBasicInfoImplCopyWith(
    _$ProductBasicInfoImpl value,
    $Res Function(_$ProductBasicInfoImpl) then,
  ) = __$$ProductBasicInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String nombre, String? imagenUrl, double? precioVenta});
}

/// @nodoc
class __$$ProductBasicInfoImplCopyWithImpl<$Res>
    extends _$ProductBasicInfoCopyWithImpl<$Res, _$ProductBasicInfoImpl>
    implements _$$ProductBasicInfoImplCopyWith<$Res> {
  __$$ProductBasicInfoImplCopyWithImpl(
    _$ProductBasicInfoImpl _value,
    $Res Function(_$ProductBasicInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? imagenUrl = freezed,
    Object? precioVenta = freezed,
  }) {
    return _then(
      _$ProductBasicInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nombre: null == nombre
            ? _value.nombre
            : nombre // ignore: cast_nullable_to_non_nullable
                  as String,
        imagenUrl: freezed == imagenUrl
            ? _value.imagenUrl
            : imagenUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        precioVenta: freezed == precioVenta
            ? _value.precioVenta
            : precioVenta // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductBasicInfoImpl implements _ProductBasicInfo {
  const _$ProductBasicInfoImpl({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    this.precioVenta,
  });

  factory _$ProductBasicInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductBasicInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String nombre;
  @override
  final String? imagenUrl;
  @override
  final double? precioVenta;

  @override
  String toString() {
    return 'ProductBasicInfo(id: $id, nombre: $nombre, imagenUrl: $imagenUrl, precioVenta: $precioVenta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductBasicInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
            (identical(other.imagenUrl, imagenUrl) ||
                other.imagenUrl == imagenUrl) &&
            (identical(other.precioVenta, precioVenta) ||
                other.precioVenta == precioVenta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, nombre, imagenUrl, precioVenta);

  /// Create a copy of ProductBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductBasicInfoImplCopyWith<_$ProductBasicInfoImpl> get copyWith =>
      __$$ProductBasicInfoImplCopyWithImpl<_$ProductBasicInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductBasicInfoImplToJson(this);
  }
}

abstract class _ProductBasicInfo implements ProductBasicInfo {
  const factory _ProductBasicInfo({
    required final String id,
    required final String nombre,
    final String? imagenUrl,
    final double? precioVenta,
  }) = _$ProductBasicInfoImpl;

  factory _ProductBasicInfo.fromJson(Map<String, dynamic> json) =
      _$ProductBasicInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get nombre;
  @override
  String? get imagenUrl;
  @override
  double? get precioVenta;

  /// Create a copy of ProductBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductBasicInfoImplCopyWith<_$ProductBasicInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserBasicInfo _$UserBasicInfoFromJson(Map<String, dynamic> json) {
  return _UserBasicInfo.fromJson(json);
}

/// @nodoc
mixin _$UserBasicInfo {
  String get id => throw _privateConstructorUsedError;
  String get nombreCompleto => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  /// Serializes this UserBasicInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserBasicInfoCopyWith<UserBasicInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserBasicInfoCopyWith<$Res> {
  factory $UserBasicInfoCopyWith(
    UserBasicInfo value,
    $Res Function(UserBasicInfo) then,
  ) = _$UserBasicInfoCopyWithImpl<$Res, UserBasicInfo>;
  @useResult
  $Res call({String id, String nombreCompleto, String? email});
}

/// @nodoc
class _$UserBasicInfoCopyWithImpl<$Res, $Val extends UserBasicInfo>
    implements $UserBasicInfoCopyWith<$Res> {
  _$UserBasicInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nombreCompleto: null == nombreCompleto
                ? _value.nombreCompleto
                : nombreCompleto // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserBasicInfoImplCopyWith<$Res>
    implements $UserBasicInfoCopyWith<$Res> {
  factory _$$UserBasicInfoImplCopyWith(
    _$UserBasicInfoImpl value,
    $Res Function(_$UserBasicInfoImpl) then,
  ) = __$$UserBasicInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String nombreCompleto, String? email});
}

/// @nodoc
class __$$UserBasicInfoImplCopyWithImpl<$Res>
    extends _$UserBasicInfoCopyWithImpl<$Res, _$UserBasicInfoImpl>
    implements _$$UserBasicInfoImplCopyWith<$Res> {
  __$$UserBasicInfoImplCopyWithImpl(
    _$UserBasicInfoImpl _value,
    $Res Function(_$UserBasicInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = freezed,
  }) {
    return _then(
      _$UserBasicInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nombreCompleto: null == nombreCompleto
            ? _value.nombreCompleto
            : nombreCompleto // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserBasicInfoImpl implements _UserBasicInfo {
  const _$UserBasicInfoImpl({
    required this.id,
    required this.nombreCompleto,
    this.email,
  });

  factory _$UserBasicInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserBasicInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String nombreCompleto;
  @override
  final String? email;

  @override
  String toString() {
    return 'UserBasicInfo(id: $id, nombreCompleto: $nombreCompleto, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserBasicInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombreCompleto, nombreCompleto) ||
                other.nombreCompleto == nombreCompleto) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nombreCompleto, email);

  /// Create a copy of UserBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserBasicInfoImplCopyWith<_$UserBasicInfoImpl> get copyWith =>
      __$$UserBasicInfoImplCopyWithImpl<_$UserBasicInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserBasicInfoImplToJson(this);
  }
}

abstract class _UserBasicInfo implements UserBasicInfo {
  const factory _UserBasicInfo({
    required final String id,
    required final String nombreCompleto,
    final String? email,
  }) = _$UserBasicInfoImpl;

  factory _UserBasicInfo.fromJson(Map<String, dynamic> json) =
      _$UserBasicInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get nombreCompleto;
  @override
  String? get email;

  /// Create a copy of UserBasicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserBasicInfoImplCopyWith<_$UserBasicInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaintenanceRecord _$MaintenanceRecordFromJson(Map<String, dynamic> json) {
  return _MaintenanceRecord.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceRecord {
  String get id => throw _privateConstructorUsedError;
  String get empresaId => throw _privateConstructorUsedError;
  String get productoId => throw _privateConstructorUsedError;
  String get createdByUserId => throw _privateConstructorUsedError;
  MaintenanceType get maintenanceType => throw _privateConstructorUsedError;
  ProductHealthStatus? get statusBefore => throw _privateConstructorUsedError;
  ProductHealthStatus get statusAfter => throw _privateConstructorUsedError;
  IssueCategory? get issueCategory => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get internalNotes => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  String? get warrantyCaseId => throw _privateConstructorUsedError;
  List<String> get attachmentUrls => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  ProductBasicInfo? get producto => throw _privateConstructorUsedError;
  UserBasicInfo? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this MaintenanceRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaintenanceRecordCopyWith<MaintenanceRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceRecordCopyWith<$Res> {
  factory $MaintenanceRecordCopyWith(
    MaintenanceRecord value,
    $Res Function(MaintenanceRecord) then,
  ) = _$MaintenanceRecordCopyWithImpl<$Res, MaintenanceRecord>;
  @useResult
  $Res call({
    String id,
    String empresaId,
    String productoId,
    String createdByUserId,
    MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    List<String> attachmentUrls,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  });

  $ProductBasicInfoCopyWith<$Res>? get producto;
  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class _$MaintenanceRecordCopyWithImpl<$Res, $Val extends MaintenanceRecord>
    implements $MaintenanceRecordCopyWith<$Res> {
  _$MaintenanceRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? productoId = null,
    Object? createdByUserId = null,
    Object? maintenanceType = null,
    Object? statusBefore = freezed,
    Object? statusAfter = null,
    Object? issueCategory = freezed,
    Object? description = null,
    Object? internalNotes = freezed,
    Object? cost = freezed,
    Object? warrantyCaseId = freezed,
    Object? attachmentUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? producto = freezed,
    Object? createdBy = freezed,
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
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdByUserId: null == createdByUserId
                ? _value.createdByUserId
                : createdByUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            maintenanceType: null == maintenanceType
                ? _value.maintenanceType
                : maintenanceType // ignore: cast_nullable_to_non_nullable
                      as MaintenanceType,
            statusBefore: freezed == statusBefore
                ? _value.statusBefore
                : statusBefore // ignore: cast_nullable_to_non_nullable
                      as ProductHealthStatus?,
            statusAfter: null == statusAfter
                ? _value.statusAfter
                : statusAfter // ignore: cast_nullable_to_non_nullable
                      as ProductHealthStatus,
            issueCategory: freezed == issueCategory
                ? _value.issueCategory
                : issueCategory // ignore: cast_nullable_to_non_nullable
                      as IssueCategory?,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            internalNotes: freezed == internalNotes
                ? _value.internalNotes
                : internalNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            warrantyCaseId: freezed == warrantyCaseId
                ? _value.warrantyCaseId
                : warrantyCaseId // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentUrls: null == attachmentUrls
                ? _value.attachmentUrls
                : attachmentUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
            producto: freezed == producto
                ? _value.producto
                : producto // ignore: cast_nullable_to_non_nullable
                      as ProductBasicInfo?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as UserBasicInfo?,
          )
          as $Val,
    );
  }

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductBasicInfoCopyWith<$Res>? get producto {
    if (_value.producto == null) {
      return null;
    }

    return $ProductBasicInfoCopyWith<$Res>(_value.producto!, (value) {
      return _then(_value.copyWith(producto: value) as $Val);
    });
  }

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserBasicInfoCopyWith<$Res>? get createdBy {
    if (_value.createdBy == null) {
      return null;
    }

    return $UserBasicInfoCopyWith<$Res>(_value.createdBy!, (value) {
      return _then(_value.copyWith(createdBy: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MaintenanceRecordImplCopyWith<$Res>
    implements $MaintenanceRecordCopyWith<$Res> {
  factory _$$MaintenanceRecordImplCopyWith(
    _$MaintenanceRecordImpl value,
    $Res Function(_$MaintenanceRecordImpl) then,
  ) = __$$MaintenanceRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String empresaId,
    String productoId,
    String createdByUserId,
    MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    List<String> attachmentUrls,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  });

  @override
  $ProductBasicInfoCopyWith<$Res>? get producto;
  @override
  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class __$$MaintenanceRecordImplCopyWithImpl<$Res>
    extends _$MaintenanceRecordCopyWithImpl<$Res, _$MaintenanceRecordImpl>
    implements _$$MaintenanceRecordImplCopyWith<$Res> {
  __$$MaintenanceRecordImplCopyWithImpl(
    _$MaintenanceRecordImpl _value,
    $Res Function(_$MaintenanceRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? productoId = null,
    Object? createdByUserId = null,
    Object? maintenanceType = null,
    Object? statusBefore = freezed,
    Object? statusAfter = null,
    Object? issueCategory = freezed,
    Object? description = null,
    Object? internalNotes = freezed,
    Object? cost = freezed,
    Object? warrantyCaseId = freezed,
    Object? attachmentUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? producto = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(
      _$MaintenanceRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        empresaId: null == empresaId
            ? _value.empresaId
            : empresaId // ignore: cast_nullable_to_non_nullable
                  as String,
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByUserId: null == createdByUserId
            ? _value.createdByUserId
            : createdByUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        maintenanceType: null == maintenanceType
            ? _value.maintenanceType
            : maintenanceType // ignore: cast_nullable_to_non_nullable
                  as MaintenanceType,
        statusBefore: freezed == statusBefore
            ? _value.statusBefore
            : statusBefore // ignore: cast_nullable_to_non_nullable
                  as ProductHealthStatus?,
        statusAfter: null == statusAfter
            ? _value.statusAfter
            : statusAfter // ignore: cast_nullable_to_non_nullable
                  as ProductHealthStatus,
        issueCategory: freezed == issueCategory
            ? _value.issueCategory
            : issueCategory // ignore: cast_nullable_to_non_nullable
                  as IssueCategory?,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        internalNotes: freezed == internalNotes
            ? _value.internalNotes
            : internalNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        warrantyCaseId: freezed == warrantyCaseId
            ? _value.warrantyCaseId
            : warrantyCaseId // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentUrls: null == attachmentUrls
            ? _value._attachmentUrls
            : attachmentUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
        producto: freezed == producto
            ? _value.producto
            : producto // ignore: cast_nullable_to_non_nullable
                  as ProductBasicInfo?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as UserBasicInfo?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceRecordImpl implements _MaintenanceRecord {
  const _$MaintenanceRecordImpl({
    required this.id,
    required this.empresaId,
    required this.productoId,
    required this.createdByUserId,
    required this.maintenanceType,
    this.statusBefore,
    required this.statusAfter,
    this.issueCategory,
    required this.description,
    this.internalNotes,
    this.cost,
    this.warrantyCaseId,
    final List<String> attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.producto,
    this.createdBy,
  }) : _attachmentUrls = attachmentUrls;

  factory _$MaintenanceRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String empresaId;
  @override
  final String productoId;
  @override
  final String createdByUserId;
  @override
  final MaintenanceType maintenanceType;
  @override
  final ProductHealthStatus? statusBefore;
  @override
  final ProductHealthStatus statusAfter;
  @override
  final IssueCategory? issueCategory;
  @override
  final String description;
  @override
  final String? internalNotes;
  @override
  final double? cost;
  @override
  final String? warrantyCaseId;
  final List<String> _attachmentUrls;
  @override
  @JsonKey()
  List<String> get attachmentUrls {
    if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentUrls);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  final ProductBasicInfo? producto;
  @override
  final UserBasicInfo? createdBy;

  @override
  String toString() {
    return 'MaintenanceRecord(id: $id, empresaId: $empresaId, productoId: $productoId, createdByUserId: $createdByUserId, maintenanceType: $maintenanceType, statusBefore: $statusBefore, statusAfter: $statusAfter, issueCategory: $issueCategory, description: $description, internalNotes: $internalNotes, cost: $cost, warrantyCaseId: $warrantyCaseId, attachmentUrls: $attachmentUrls, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, producto: $producto, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.empresaId, empresaId) ||
                other.empresaId == empresaId) &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.maintenanceType, maintenanceType) ||
                other.maintenanceType == maintenanceType) &&
            (identical(other.statusBefore, statusBefore) ||
                other.statusBefore == statusBefore) &&
            (identical(other.statusAfter, statusAfter) ||
                other.statusAfter == statusAfter) &&
            (identical(other.issueCategory, issueCategory) ||
                other.issueCategory == issueCategory) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.internalNotes, internalNotes) ||
                other.internalNotes == internalNotes) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.warrantyCaseId, warrantyCaseId) ||
                other.warrantyCaseId == warrantyCaseId) &&
            const DeepCollectionEquality().equals(
              other._attachmentUrls,
              _attachmentUrls,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.producto, producto) ||
                other.producto == producto) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    empresaId,
    productoId,
    createdByUserId,
    maintenanceType,
    statusBefore,
    statusAfter,
    issueCategory,
    description,
    internalNotes,
    cost,
    warrantyCaseId,
    const DeepCollectionEquality().hash(_attachmentUrls),
    createdAt,
    updatedAt,
    deletedAt,
    producto,
    createdBy,
  );

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceRecordImplCopyWith<_$MaintenanceRecordImpl> get copyWith =>
      __$$MaintenanceRecordImplCopyWithImpl<_$MaintenanceRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceRecordImplToJson(this);
  }
}

abstract class _MaintenanceRecord implements MaintenanceRecord {
  const factory _MaintenanceRecord({
    required final String id,
    required final String empresaId,
    required final String productoId,
    required final String createdByUserId,
    required final MaintenanceType maintenanceType,
    final ProductHealthStatus? statusBefore,
    required final ProductHealthStatus statusAfter,
    final IssueCategory? issueCategory,
    required final String description,
    final String? internalNotes,
    final double? cost,
    final String? warrantyCaseId,
    final List<String> attachmentUrls,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? deletedAt,
    final ProductBasicInfo? producto,
    final UserBasicInfo? createdBy,
  }) = _$MaintenanceRecordImpl;

  factory _MaintenanceRecord.fromJson(Map<String, dynamic> json) =
      _$MaintenanceRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get empresaId;
  @override
  String get productoId;
  @override
  String get createdByUserId;
  @override
  MaintenanceType get maintenanceType;
  @override
  ProductHealthStatus? get statusBefore;
  @override
  ProductHealthStatus get statusAfter;
  @override
  IssueCategory? get issueCategory;
  @override
  String get description;
  @override
  String? get internalNotes;
  @override
  double? get cost;
  @override
  String? get warrantyCaseId;
  @override
  List<String> get attachmentUrls;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get deletedAt;
  @override
  ProductBasicInfo? get producto;
  @override
  UserBasicInfo? get createdBy;

  /// Create a copy of MaintenanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaintenanceRecordImplCopyWith<_$MaintenanceRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WarrantyCase _$WarrantyCaseFromJson(Map<String, dynamic> json) {
  return _WarrantyCase.fromJson(json);
}

/// @nodoc
mixin _$WarrantyCase {
  String get id => throw _privateConstructorUsedError;
  String get empresaId => throw _privateConstructorUsedError;
  String get productoId => throw _privateConstructorUsedError;
  String get createdByUserId => throw _privateConstructorUsedError;
  WarrantyStatus get warrantyStatus => throw _privateConstructorUsedError;
  String? get supplierName => throw _privateConstructorUsedError;
  String? get supplierTicket => throw _privateConstructorUsedError;
  DateTime? get sentDate => throw _privateConstructorUsedError;
  DateTime? get receivedDate => throw _privateConstructorUsedError;
  DateTime? get closedAt => throw _privateConstructorUsedError;
  String get problemDescription => throw _privateConstructorUsedError;
  String? get resolutionNotes => throw _privateConstructorUsedError;
  List<String> get attachmentUrls => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  ProductBasicInfo? get producto => throw _privateConstructorUsedError;
  UserBasicInfo? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this WarrantyCase to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WarrantyCaseCopyWith<WarrantyCase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WarrantyCaseCopyWith<$Res> {
  factory $WarrantyCaseCopyWith(
    WarrantyCase value,
    $Res Function(WarrantyCase) then,
  ) = _$WarrantyCaseCopyWithImpl<$Res, WarrantyCase>;
  @useResult
  $Res call({
    String id,
    String empresaId,
    String productoId,
    String createdByUserId,
    WarrantyStatus warrantyStatus,
    String? supplierName,
    String? supplierTicket,
    DateTime? sentDate,
    DateTime? receivedDate,
    DateTime? closedAt,
    String problemDescription,
    String? resolutionNotes,
    List<String> attachmentUrls,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  });

  $ProductBasicInfoCopyWith<$Res>? get producto;
  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class _$WarrantyCaseCopyWithImpl<$Res, $Val extends WarrantyCase>
    implements $WarrantyCaseCopyWith<$Res> {
  _$WarrantyCaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? productoId = null,
    Object? createdByUserId = null,
    Object? warrantyStatus = null,
    Object? supplierName = freezed,
    Object? supplierTicket = freezed,
    Object? sentDate = freezed,
    Object? receivedDate = freezed,
    Object? closedAt = freezed,
    Object? problemDescription = null,
    Object? resolutionNotes = freezed,
    Object? attachmentUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? producto = freezed,
    Object? createdBy = freezed,
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
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdByUserId: null == createdByUserId
                ? _value.createdByUserId
                : createdByUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            warrantyStatus: null == warrantyStatus
                ? _value.warrantyStatus
                : warrantyStatus // ignore: cast_nullable_to_non_nullable
                      as WarrantyStatus,
            supplierName: freezed == supplierName
                ? _value.supplierName
                : supplierName // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplierTicket: freezed == supplierTicket
                ? _value.supplierTicket
                : supplierTicket // ignore: cast_nullable_to_non_nullable
                      as String?,
            sentDate: freezed == sentDate
                ? _value.sentDate
                : sentDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            receivedDate: freezed == receivedDate
                ? _value.receivedDate
                : receivedDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            closedAt: freezed == closedAt
                ? _value.closedAt
                : closedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            problemDescription: null == problemDescription
                ? _value.problemDescription
                : problemDescription // ignore: cast_nullable_to_non_nullable
                      as String,
            resolutionNotes: freezed == resolutionNotes
                ? _value.resolutionNotes
                : resolutionNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentUrls: null == attachmentUrls
                ? _value.attachmentUrls
                : attachmentUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
            producto: freezed == producto
                ? _value.producto
                : producto // ignore: cast_nullable_to_non_nullable
                      as ProductBasicInfo?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as UserBasicInfo?,
          )
          as $Val,
    );
  }

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductBasicInfoCopyWith<$Res>? get producto {
    if (_value.producto == null) {
      return null;
    }

    return $ProductBasicInfoCopyWith<$Res>(_value.producto!, (value) {
      return _then(_value.copyWith(producto: value) as $Val);
    });
  }

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserBasicInfoCopyWith<$Res>? get createdBy {
    if (_value.createdBy == null) {
      return null;
    }

    return $UserBasicInfoCopyWith<$Res>(_value.createdBy!, (value) {
      return _then(_value.copyWith(createdBy: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WarrantyCaseImplCopyWith<$Res>
    implements $WarrantyCaseCopyWith<$Res> {
  factory _$$WarrantyCaseImplCopyWith(
    _$WarrantyCaseImpl value,
    $Res Function(_$WarrantyCaseImpl) then,
  ) = __$$WarrantyCaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String empresaId,
    String productoId,
    String createdByUserId,
    WarrantyStatus warrantyStatus,
    String? supplierName,
    String? supplierTicket,
    DateTime? sentDate,
    DateTime? receivedDate,
    DateTime? closedAt,
    String problemDescription,
    String? resolutionNotes,
    List<String> attachmentUrls,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  });

  @override
  $ProductBasicInfoCopyWith<$Res>? get producto;
  @override
  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class __$$WarrantyCaseImplCopyWithImpl<$Res>
    extends _$WarrantyCaseCopyWithImpl<$Res, _$WarrantyCaseImpl>
    implements _$$WarrantyCaseImplCopyWith<$Res> {
  __$$WarrantyCaseImplCopyWithImpl(
    _$WarrantyCaseImpl _value,
    $Res Function(_$WarrantyCaseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? productoId = null,
    Object? createdByUserId = null,
    Object? warrantyStatus = null,
    Object? supplierName = freezed,
    Object? supplierTicket = freezed,
    Object? sentDate = freezed,
    Object? receivedDate = freezed,
    Object? closedAt = freezed,
    Object? problemDescription = null,
    Object? resolutionNotes = freezed,
    Object? attachmentUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? producto = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(
      _$WarrantyCaseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        empresaId: null == empresaId
            ? _value.empresaId
            : empresaId // ignore: cast_nullable_to_non_nullable
                  as String,
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByUserId: null == createdByUserId
            ? _value.createdByUserId
            : createdByUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        warrantyStatus: null == warrantyStatus
            ? _value.warrantyStatus
            : warrantyStatus // ignore: cast_nullable_to_non_nullable
                  as WarrantyStatus,
        supplierName: freezed == supplierName
            ? _value.supplierName
            : supplierName // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplierTicket: freezed == supplierTicket
            ? _value.supplierTicket
            : supplierTicket // ignore: cast_nullable_to_non_nullable
                  as String?,
        sentDate: freezed == sentDate
            ? _value.sentDate
            : sentDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        receivedDate: freezed == receivedDate
            ? _value.receivedDate
            : receivedDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        closedAt: freezed == closedAt
            ? _value.closedAt
            : closedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        problemDescription: null == problemDescription
            ? _value.problemDescription
            : problemDescription // ignore: cast_nullable_to_non_nullable
                  as String,
        resolutionNotes: freezed == resolutionNotes
            ? _value.resolutionNotes
            : resolutionNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentUrls: null == attachmentUrls
            ? _value._attachmentUrls
            : attachmentUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
        producto: freezed == producto
            ? _value.producto
            : producto // ignore: cast_nullable_to_non_nullable
                  as ProductBasicInfo?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as UserBasicInfo?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WarrantyCaseImpl implements _WarrantyCase {
  const _$WarrantyCaseImpl({
    required this.id,
    required this.empresaId,
    required this.productoId,
    required this.createdByUserId,
    required this.warrantyStatus,
    this.supplierName,
    this.supplierTicket,
    this.sentDate,
    this.receivedDate,
    this.closedAt,
    required this.problemDescription,
    this.resolutionNotes,
    final List<String> attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.producto,
    this.createdBy,
  }) : _attachmentUrls = attachmentUrls;

  factory _$WarrantyCaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarrantyCaseImplFromJson(json);

  @override
  final String id;
  @override
  final String empresaId;
  @override
  final String productoId;
  @override
  final String createdByUserId;
  @override
  final WarrantyStatus warrantyStatus;
  @override
  final String? supplierName;
  @override
  final String? supplierTicket;
  @override
  final DateTime? sentDate;
  @override
  final DateTime? receivedDate;
  @override
  final DateTime? closedAt;
  @override
  final String problemDescription;
  @override
  final String? resolutionNotes;
  final List<String> _attachmentUrls;
  @override
  @JsonKey()
  List<String> get attachmentUrls {
    if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentUrls);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  final ProductBasicInfo? producto;
  @override
  final UserBasicInfo? createdBy;

  @override
  String toString() {
    return 'WarrantyCase(id: $id, empresaId: $empresaId, productoId: $productoId, createdByUserId: $createdByUserId, warrantyStatus: $warrantyStatus, supplierName: $supplierName, supplierTicket: $supplierTicket, sentDate: $sentDate, receivedDate: $receivedDate, closedAt: $closedAt, problemDescription: $problemDescription, resolutionNotes: $resolutionNotes, attachmentUrls: $attachmentUrls, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, producto: $producto, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarrantyCaseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.empresaId, empresaId) ||
                other.empresaId == empresaId) &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.warrantyStatus, warrantyStatus) ||
                other.warrantyStatus == warrantyStatus) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.supplierTicket, supplierTicket) ||
                other.supplierTicket == supplierTicket) &&
            (identical(other.sentDate, sentDate) ||
                other.sentDate == sentDate) &&
            (identical(other.receivedDate, receivedDate) ||
                other.receivedDate == receivedDate) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            (identical(other.problemDescription, problemDescription) ||
                other.problemDescription == problemDescription) &&
            (identical(other.resolutionNotes, resolutionNotes) ||
                other.resolutionNotes == resolutionNotes) &&
            const DeepCollectionEquality().equals(
              other._attachmentUrls,
              _attachmentUrls,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.producto, producto) ||
                other.producto == producto) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    empresaId,
    productoId,
    createdByUserId,
    warrantyStatus,
    supplierName,
    supplierTicket,
    sentDate,
    receivedDate,
    closedAt,
    problemDescription,
    resolutionNotes,
    const DeepCollectionEquality().hash(_attachmentUrls),
    createdAt,
    updatedAt,
    deletedAt,
    producto,
    createdBy,
  );

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WarrantyCaseImplCopyWith<_$WarrantyCaseImpl> get copyWith =>
      __$$WarrantyCaseImplCopyWithImpl<_$WarrantyCaseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WarrantyCaseImplToJson(this);
  }
}

abstract class _WarrantyCase implements WarrantyCase {
  const factory _WarrantyCase({
    required final String id,
    required final String empresaId,
    required final String productoId,
    required final String createdByUserId,
    required final WarrantyStatus warrantyStatus,
    final String? supplierName,
    final String? supplierTicket,
    final DateTime? sentDate,
    final DateTime? receivedDate,
    final DateTime? closedAt,
    required final String problemDescription,
    final String? resolutionNotes,
    final List<String> attachmentUrls,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? deletedAt,
    final ProductBasicInfo? producto,
    final UserBasicInfo? createdBy,
  }) = _$WarrantyCaseImpl;

  factory _WarrantyCase.fromJson(Map<String, dynamic> json) =
      _$WarrantyCaseImpl.fromJson;

  @override
  String get id;
  @override
  String get empresaId;
  @override
  String get productoId;
  @override
  String get createdByUserId;
  @override
  WarrantyStatus get warrantyStatus;
  @override
  String? get supplierName;
  @override
  String? get supplierTicket;
  @override
  DateTime? get sentDate;
  @override
  DateTime? get receivedDate;
  @override
  DateTime? get closedAt;
  @override
  String get problemDescription;
  @override
  String? get resolutionNotes;
  @override
  List<String> get attachmentUrls;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get deletedAt;
  @override
  ProductBasicInfo? get producto;
  @override
  UserBasicInfo? get createdBy;

  /// Create a copy of WarrantyCase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WarrantyCaseImplCopyWith<_$WarrantyCaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InventoryAudit _$InventoryAuditFromJson(Map<String, dynamic> json) {
  return _InventoryAudit.fromJson(json);
}

/// @nodoc
mixin _$InventoryAudit {
  String get id => throw _privateConstructorUsedError;
  String get empresaId => throw _privateConstructorUsedError;
  String get createdByUserId => throw _privateConstructorUsedError;
  DateTime get auditFromDate => throw _privateConstructorUsedError;
  DateTime get auditToDate => throw _privateConstructorUsedError;
  String get weekLabel => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  AuditStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  UserBasicInfo? get createdBy => throw _privateConstructorUsedError;
  int? get totalItems => throw _privateConstructorUsedError;
  int? get totalDiferencias => throw _privateConstructorUsedError;

  /// Serializes this InventoryAudit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryAuditCopyWith<InventoryAudit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryAuditCopyWith<$Res> {
  factory $InventoryAuditCopyWith(
    InventoryAudit value,
    $Res Function(InventoryAudit) then,
  ) = _$InventoryAuditCopyWithImpl<$Res, InventoryAudit>;
  @useResult
  $Res call({
    String id,
    String empresaId,
    String createdByUserId,
    DateTime auditFromDate,
    DateTime auditToDate,
    String weekLabel,
    String? notes,
    AuditStatus status,
    DateTime createdAt,
    DateTime updatedAt,
    UserBasicInfo? createdBy,
    int? totalItems,
    int? totalDiferencias,
  });

  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class _$InventoryAuditCopyWithImpl<$Res, $Val extends InventoryAudit>
    implements $InventoryAuditCopyWith<$Res> {
  _$InventoryAuditCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? createdByUserId = null,
    Object? auditFromDate = null,
    Object? auditToDate = null,
    Object? weekLabel = null,
    Object? notes = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? totalItems = freezed,
    Object? totalDiferencias = freezed,
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
            createdByUserId: null == createdByUserId
                ? _value.createdByUserId
                : createdByUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            auditFromDate: null == auditFromDate
                ? _value.auditFromDate
                : auditFromDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            auditToDate: null == auditToDate
                ? _value.auditToDate
                : auditToDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            weekLabel: null == weekLabel
                ? _value.weekLabel
                : weekLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as AuditStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as UserBasicInfo?,
            totalItems: freezed == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalDiferencias: freezed == totalDiferencias
                ? _value.totalDiferencias
                : totalDiferencias // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserBasicInfoCopyWith<$Res>? get createdBy {
    if (_value.createdBy == null) {
      return null;
    }

    return $UserBasicInfoCopyWith<$Res>(_value.createdBy!, (value) {
      return _then(_value.copyWith(createdBy: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InventoryAuditImplCopyWith<$Res>
    implements $InventoryAuditCopyWith<$Res> {
  factory _$$InventoryAuditImplCopyWith(
    _$InventoryAuditImpl value,
    $Res Function(_$InventoryAuditImpl) then,
  ) = __$$InventoryAuditImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String empresaId,
    String createdByUserId,
    DateTime auditFromDate,
    DateTime auditToDate,
    String weekLabel,
    String? notes,
    AuditStatus status,
    DateTime createdAt,
    DateTime updatedAt,
    UserBasicInfo? createdBy,
    int? totalItems,
    int? totalDiferencias,
  });

  @override
  $UserBasicInfoCopyWith<$Res>? get createdBy;
}

/// @nodoc
class __$$InventoryAuditImplCopyWithImpl<$Res>
    extends _$InventoryAuditCopyWithImpl<$Res, _$InventoryAuditImpl>
    implements _$$InventoryAuditImplCopyWith<$Res> {
  __$$InventoryAuditImplCopyWithImpl(
    _$InventoryAuditImpl _value,
    $Res Function(_$InventoryAuditImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? empresaId = null,
    Object? createdByUserId = null,
    Object? auditFromDate = null,
    Object? auditToDate = null,
    Object? weekLabel = null,
    Object? notes = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? totalItems = freezed,
    Object? totalDiferencias = freezed,
  }) {
    return _then(
      _$InventoryAuditImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        empresaId: null == empresaId
            ? _value.empresaId
            : empresaId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByUserId: null == createdByUserId
            ? _value.createdByUserId
            : createdByUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        auditFromDate: null == auditFromDate
            ? _value.auditFromDate
            : auditFromDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        auditToDate: null == auditToDate
            ? _value.auditToDate
            : auditToDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        weekLabel: null == weekLabel
            ? _value.weekLabel
            : weekLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AuditStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as UserBasicInfo?,
        totalItems: freezed == totalItems
            ? _value.totalItems
            : totalItems // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalDiferencias: freezed == totalDiferencias
            ? _value.totalDiferencias
            : totalDiferencias // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryAuditImpl implements _InventoryAudit {
  const _$InventoryAuditImpl({
    required this.id,
    required this.empresaId,
    required this.createdByUserId,
    required this.auditFromDate,
    required this.auditToDate,
    required this.weekLabel,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.totalItems,
    this.totalDiferencias,
  });

  factory _$InventoryAuditImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryAuditImplFromJson(json);

  @override
  final String id;
  @override
  final String empresaId;
  @override
  final String createdByUserId;
  @override
  final DateTime auditFromDate;
  @override
  final DateTime auditToDate;
  @override
  final String weekLabel;
  @override
  final String? notes;
  @override
  final AuditStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final UserBasicInfo? createdBy;
  @override
  final int? totalItems;
  @override
  final int? totalDiferencias;

  @override
  String toString() {
    return 'InventoryAudit(id: $id, empresaId: $empresaId, createdByUserId: $createdByUserId, auditFromDate: $auditFromDate, auditToDate: $auditToDate, weekLabel: $weekLabel, notes: $notes, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, totalItems: $totalItems, totalDiferencias: $totalDiferencias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryAuditImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.empresaId, empresaId) ||
                other.empresaId == empresaId) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.auditFromDate, auditFromDate) ||
                other.auditFromDate == auditFromDate) &&
            (identical(other.auditToDate, auditToDate) ||
                other.auditToDate == auditToDate) &&
            (identical(other.weekLabel, weekLabel) ||
                other.weekLabel == weekLabel) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.totalDiferencias, totalDiferencias) ||
                other.totalDiferencias == totalDiferencias));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    empresaId,
    createdByUserId,
    auditFromDate,
    auditToDate,
    weekLabel,
    notes,
    status,
    createdAt,
    updatedAt,
    createdBy,
    totalItems,
    totalDiferencias,
  );

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryAuditImplCopyWith<_$InventoryAuditImpl> get copyWith =>
      __$$InventoryAuditImplCopyWithImpl<_$InventoryAuditImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryAuditImplToJson(this);
  }
}

abstract class _InventoryAudit implements InventoryAudit {
  const factory _InventoryAudit({
    required final String id,
    required final String empresaId,
    required final String createdByUserId,
    required final DateTime auditFromDate,
    required final DateTime auditToDate,
    required final String weekLabel,
    final String? notes,
    required final AuditStatus status,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final UserBasicInfo? createdBy,
    final int? totalItems,
    final int? totalDiferencias,
  }) = _$InventoryAuditImpl;

  factory _InventoryAudit.fromJson(Map<String, dynamic> json) =
      _$InventoryAuditImpl.fromJson;

  @override
  String get id;
  @override
  String get empresaId;
  @override
  String get createdByUserId;
  @override
  DateTime get auditFromDate;
  @override
  DateTime get auditToDate;
  @override
  String get weekLabel;
  @override
  String? get notes;
  @override
  AuditStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  UserBasicInfo? get createdBy;
  @override
  int? get totalItems;
  @override
  int? get totalDiferencias;

  /// Create a copy of InventoryAudit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryAuditImplCopyWith<_$InventoryAuditImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InventoryAuditItem _$InventoryAuditItemFromJson(Map<String, dynamic> json) {
  return _InventoryAuditItem.fromJson(json);
}

/// @nodoc
mixin _$InventoryAuditItem {
  String get id => throw _privateConstructorUsedError;
  String get auditId => throw _privateConstructorUsedError;
  String get productoId => throw _privateConstructorUsedError;
  int get expectedQty => throw _privateConstructorUsedError;
  int get countedQty => throw _privateConstructorUsedError;
  int get diffQty => throw _privateConstructorUsedError;
  AuditReason? get reason => throw _privateConstructorUsedError;
  String? get explanation => throw _privateConstructorUsedError;
  AuditAction get actionTaken => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  ProductBasicInfo? get producto => throw _privateConstructorUsedError;

  /// Serializes this InventoryAuditItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryAuditItemCopyWith<InventoryAuditItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryAuditItemCopyWith<$Res> {
  factory $InventoryAuditItemCopyWith(
    InventoryAuditItem value,
    $Res Function(InventoryAuditItem) then,
  ) = _$InventoryAuditItemCopyWithImpl<$Res, InventoryAuditItem>;
  @useResult
  $Res call({
    String id,
    String auditId,
    String productoId,
    int expectedQty,
    int countedQty,
    int diffQty,
    AuditReason? reason,
    String? explanation,
    AuditAction actionTaken,
    DateTime createdAt,
    ProductBasicInfo? producto,
  });

  $ProductBasicInfoCopyWith<$Res>? get producto;
}

/// @nodoc
class _$InventoryAuditItemCopyWithImpl<$Res, $Val extends InventoryAuditItem>
    implements $InventoryAuditItemCopyWith<$Res> {
  _$InventoryAuditItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? auditId = null,
    Object? productoId = null,
    Object? expectedQty = null,
    Object? countedQty = null,
    Object? diffQty = null,
    Object? reason = freezed,
    Object? explanation = freezed,
    Object? actionTaken = null,
    Object? createdAt = null,
    Object? producto = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            auditId: null == auditId
                ? _value.auditId
                : auditId // ignore: cast_nullable_to_non_nullable
                      as String,
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            expectedQty: null == expectedQty
                ? _value.expectedQty
                : expectedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            countedQty: null == countedQty
                ? _value.countedQty
                : countedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            diffQty: null == diffQty
                ? _value.diffQty
                : diffQty // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as AuditReason?,
            explanation: freezed == explanation
                ? _value.explanation
                : explanation // ignore: cast_nullable_to_non_nullable
                      as String?,
            actionTaken: null == actionTaken
                ? _value.actionTaken
                : actionTaken // ignore: cast_nullable_to_non_nullable
                      as AuditAction,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            producto: freezed == producto
                ? _value.producto
                : producto // ignore: cast_nullable_to_non_nullable
                      as ProductBasicInfo?,
          )
          as $Val,
    );
  }

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductBasicInfoCopyWith<$Res>? get producto {
    if (_value.producto == null) {
      return null;
    }

    return $ProductBasicInfoCopyWith<$Res>(_value.producto!, (value) {
      return _then(_value.copyWith(producto: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InventoryAuditItemImplCopyWith<$Res>
    implements $InventoryAuditItemCopyWith<$Res> {
  factory _$$InventoryAuditItemImplCopyWith(
    _$InventoryAuditItemImpl value,
    $Res Function(_$InventoryAuditItemImpl) then,
  ) = __$$InventoryAuditItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String auditId,
    String productoId,
    int expectedQty,
    int countedQty,
    int diffQty,
    AuditReason? reason,
    String? explanation,
    AuditAction actionTaken,
    DateTime createdAt,
    ProductBasicInfo? producto,
  });

  @override
  $ProductBasicInfoCopyWith<$Res>? get producto;
}

/// @nodoc
class __$$InventoryAuditItemImplCopyWithImpl<$Res>
    extends _$InventoryAuditItemCopyWithImpl<$Res, _$InventoryAuditItemImpl>
    implements _$$InventoryAuditItemImplCopyWith<$Res> {
  __$$InventoryAuditItemImplCopyWithImpl(
    _$InventoryAuditItemImpl _value,
    $Res Function(_$InventoryAuditItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? auditId = null,
    Object? productoId = null,
    Object? expectedQty = null,
    Object? countedQty = null,
    Object? diffQty = null,
    Object? reason = freezed,
    Object? explanation = freezed,
    Object? actionTaken = null,
    Object? createdAt = null,
    Object? producto = freezed,
  }) {
    return _then(
      _$InventoryAuditItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        auditId: null == auditId
            ? _value.auditId
            : auditId // ignore: cast_nullable_to_non_nullable
                  as String,
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        expectedQty: null == expectedQty
            ? _value.expectedQty
            : expectedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        countedQty: null == countedQty
            ? _value.countedQty
            : countedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        diffQty: null == diffQty
            ? _value.diffQty
            : diffQty // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as AuditReason?,
        explanation: freezed == explanation
            ? _value.explanation
            : explanation // ignore: cast_nullable_to_non_nullable
                  as String?,
        actionTaken: null == actionTaken
            ? _value.actionTaken
            : actionTaken // ignore: cast_nullable_to_non_nullable
                  as AuditAction,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        producto: freezed == producto
            ? _value.producto
            : producto // ignore: cast_nullable_to_non_nullable
                  as ProductBasicInfo?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryAuditItemImpl implements _InventoryAuditItem {
  const _$InventoryAuditItemImpl({
    required this.id,
    required this.auditId,
    required this.productoId,
    required this.expectedQty,
    required this.countedQty,
    required this.diffQty,
    this.reason,
    this.explanation,
    required this.actionTaken,
    required this.createdAt,
    this.producto,
  });

  factory _$InventoryAuditItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryAuditItemImplFromJson(json);

  @override
  final String id;
  @override
  final String auditId;
  @override
  final String productoId;
  @override
  final int expectedQty;
  @override
  final int countedQty;
  @override
  final int diffQty;
  @override
  final AuditReason? reason;
  @override
  final String? explanation;
  @override
  final AuditAction actionTaken;
  @override
  final DateTime createdAt;
  @override
  final ProductBasicInfo? producto;

  @override
  String toString() {
    return 'InventoryAuditItem(id: $id, auditId: $auditId, productoId: $productoId, expectedQty: $expectedQty, countedQty: $countedQty, diffQty: $diffQty, reason: $reason, explanation: $explanation, actionTaken: $actionTaken, createdAt: $createdAt, producto: $producto)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryAuditItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.auditId, auditId) || other.auditId == auditId) &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.expectedQty, expectedQty) ||
                other.expectedQty == expectedQty) &&
            (identical(other.countedQty, countedQty) ||
                other.countedQty == countedQty) &&
            (identical(other.diffQty, diffQty) || other.diffQty == diffQty) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            (identical(other.actionTaken, actionTaken) ||
                other.actionTaken == actionTaken) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.producto, producto) ||
                other.producto == producto));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    auditId,
    productoId,
    expectedQty,
    countedQty,
    diffQty,
    reason,
    explanation,
    actionTaken,
    createdAt,
    producto,
  );

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryAuditItemImplCopyWith<_$InventoryAuditItemImpl> get copyWith =>
      __$$InventoryAuditItemImplCopyWithImpl<_$InventoryAuditItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryAuditItemImplToJson(this);
  }
}

abstract class _InventoryAuditItem implements InventoryAuditItem {
  const factory _InventoryAuditItem({
    required final String id,
    required final String auditId,
    required final String productoId,
    required final int expectedQty,
    required final int countedQty,
    required final int diffQty,
    final AuditReason? reason,
    final String? explanation,
    required final AuditAction actionTaken,
    required final DateTime createdAt,
    final ProductBasicInfo? producto,
  }) = _$InventoryAuditItemImpl;

  factory _InventoryAuditItem.fromJson(Map<String, dynamic> json) =
      _$InventoryAuditItemImpl.fromJson;

  @override
  String get id;
  @override
  String get auditId;
  @override
  String get productoId;
  @override
  int get expectedQty;
  @override
  int get countedQty;
  @override
  int get diffQty;
  @override
  AuditReason? get reason;
  @override
  String? get explanation;
  @override
  AuditAction get actionTaken;
  @override
  DateTime get createdAt;
  @override
  ProductBasicInfo? get producto;

  /// Create a copy of InventoryAuditItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryAuditItemImplCopyWith<_$InventoryAuditItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaintenanceSummary _$MaintenanceSummaryFromJson(Map<String, dynamic> json) {
  return _MaintenanceSummary.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceSummary {
  int get totalProductosConProblema => throw _privateConstructorUsedError;
  int get totalEnGarantia => throw _privateConstructorUsedError;
  int get totalPerdidos => throw _privateConstructorUsedError;
  int get totalDanadoSinGarantia => throw _privateConstructorUsedError;
  int get totalVerificados => throw _privateConstructorUsedError;
  int get totalReparados => throw _privateConstructorUsedError;
  int get totalEnRevision => throw _privateConstructorUsedError;
  int get garantiasAbiertas => throw _privateConstructorUsedError;
  InventoryAudit? get ultimoAudit => throw _privateConstructorUsedError;
  List<ProductWithIncidents> get topProductosConIncidencias =>
      throw _privateConstructorUsedError;

  /// Serializes this MaintenanceSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaintenanceSummaryCopyWith<MaintenanceSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceSummaryCopyWith<$Res> {
  factory $MaintenanceSummaryCopyWith(
    MaintenanceSummary value,
    $Res Function(MaintenanceSummary) then,
  ) = _$MaintenanceSummaryCopyWithImpl<$Res, MaintenanceSummary>;
  @useResult
  $Res call({
    int totalProductosConProblema,
    int totalEnGarantia,
    int totalPerdidos,
    int totalDanadoSinGarantia,
    int totalVerificados,
    int totalReparados,
    int totalEnRevision,
    int garantiasAbiertas,
    InventoryAudit? ultimoAudit,
    List<ProductWithIncidents> topProductosConIncidencias,
  });

  $InventoryAuditCopyWith<$Res>? get ultimoAudit;
}

/// @nodoc
class _$MaintenanceSummaryCopyWithImpl<$Res, $Val extends MaintenanceSummary>
    implements $MaintenanceSummaryCopyWith<$Res> {
  _$MaintenanceSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalProductosConProblema = null,
    Object? totalEnGarantia = null,
    Object? totalPerdidos = null,
    Object? totalDanadoSinGarantia = null,
    Object? totalVerificados = null,
    Object? totalReparados = null,
    Object? totalEnRevision = null,
    Object? garantiasAbiertas = null,
    Object? ultimoAudit = freezed,
    Object? topProductosConIncidencias = null,
  }) {
    return _then(
      _value.copyWith(
            totalProductosConProblema: null == totalProductosConProblema
                ? _value.totalProductosConProblema
                : totalProductosConProblema // ignore: cast_nullable_to_non_nullable
                      as int,
            totalEnGarantia: null == totalEnGarantia
                ? _value.totalEnGarantia
                : totalEnGarantia // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPerdidos: null == totalPerdidos
                ? _value.totalPerdidos
                : totalPerdidos // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDanadoSinGarantia: null == totalDanadoSinGarantia
                ? _value.totalDanadoSinGarantia
                : totalDanadoSinGarantia // ignore: cast_nullable_to_non_nullable
                      as int,
            totalVerificados: null == totalVerificados
                ? _value.totalVerificados
                : totalVerificados // ignore: cast_nullable_to_non_nullable
                      as int,
            totalReparados: null == totalReparados
                ? _value.totalReparados
                : totalReparados // ignore: cast_nullable_to_non_nullable
                      as int,
            totalEnRevision: null == totalEnRevision
                ? _value.totalEnRevision
                : totalEnRevision // ignore: cast_nullable_to_non_nullable
                      as int,
            garantiasAbiertas: null == garantiasAbiertas
                ? _value.garantiasAbiertas
                : garantiasAbiertas // ignore: cast_nullable_to_non_nullable
                      as int,
            ultimoAudit: freezed == ultimoAudit
                ? _value.ultimoAudit
                : ultimoAudit // ignore: cast_nullable_to_non_nullable
                      as InventoryAudit?,
            topProductosConIncidencias: null == topProductosConIncidencias
                ? _value.topProductosConIncidencias
                : topProductosConIncidencias // ignore: cast_nullable_to_non_nullable
                      as List<ProductWithIncidents>,
          )
          as $Val,
    );
  }

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InventoryAuditCopyWith<$Res>? get ultimoAudit {
    if (_value.ultimoAudit == null) {
      return null;
    }

    return $InventoryAuditCopyWith<$Res>(_value.ultimoAudit!, (value) {
      return _then(_value.copyWith(ultimoAudit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MaintenanceSummaryImplCopyWith<$Res>
    implements $MaintenanceSummaryCopyWith<$Res> {
  factory _$$MaintenanceSummaryImplCopyWith(
    _$MaintenanceSummaryImpl value,
    $Res Function(_$MaintenanceSummaryImpl) then,
  ) = __$$MaintenanceSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalProductosConProblema,
    int totalEnGarantia,
    int totalPerdidos,
    int totalDanadoSinGarantia,
    int totalVerificados,
    int totalReparados,
    int totalEnRevision,
    int garantiasAbiertas,
    InventoryAudit? ultimoAudit,
    List<ProductWithIncidents> topProductosConIncidencias,
  });

  @override
  $InventoryAuditCopyWith<$Res>? get ultimoAudit;
}

/// @nodoc
class __$$MaintenanceSummaryImplCopyWithImpl<$Res>
    extends _$MaintenanceSummaryCopyWithImpl<$Res, _$MaintenanceSummaryImpl>
    implements _$$MaintenanceSummaryImplCopyWith<$Res> {
  __$$MaintenanceSummaryImplCopyWithImpl(
    _$MaintenanceSummaryImpl _value,
    $Res Function(_$MaintenanceSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalProductosConProblema = null,
    Object? totalEnGarantia = null,
    Object? totalPerdidos = null,
    Object? totalDanadoSinGarantia = null,
    Object? totalVerificados = null,
    Object? totalReparados = null,
    Object? totalEnRevision = null,
    Object? garantiasAbiertas = null,
    Object? ultimoAudit = freezed,
    Object? topProductosConIncidencias = null,
  }) {
    return _then(
      _$MaintenanceSummaryImpl(
        totalProductosConProblema: null == totalProductosConProblema
            ? _value.totalProductosConProblema
            : totalProductosConProblema // ignore: cast_nullable_to_non_nullable
                  as int,
        totalEnGarantia: null == totalEnGarantia
            ? _value.totalEnGarantia
            : totalEnGarantia // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPerdidos: null == totalPerdidos
            ? _value.totalPerdidos
            : totalPerdidos // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDanadoSinGarantia: null == totalDanadoSinGarantia
            ? _value.totalDanadoSinGarantia
            : totalDanadoSinGarantia // ignore: cast_nullable_to_non_nullable
                  as int,
        totalVerificados: null == totalVerificados
            ? _value.totalVerificados
            : totalVerificados // ignore: cast_nullable_to_non_nullable
                  as int,
        totalReparados: null == totalReparados
            ? _value.totalReparados
            : totalReparados // ignore: cast_nullable_to_non_nullable
                  as int,
        totalEnRevision: null == totalEnRevision
            ? _value.totalEnRevision
            : totalEnRevision // ignore: cast_nullable_to_non_nullable
                  as int,
        garantiasAbiertas: null == garantiasAbiertas
            ? _value.garantiasAbiertas
            : garantiasAbiertas // ignore: cast_nullable_to_non_nullable
                  as int,
        ultimoAudit: freezed == ultimoAudit
            ? _value.ultimoAudit
            : ultimoAudit // ignore: cast_nullable_to_non_nullable
                  as InventoryAudit?,
        topProductosConIncidencias: null == topProductosConIncidencias
            ? _value._topProductosConIncidencias
            : topProductosConIncidencias // ignore: cast_nullable_to_non_nullable
                  as List<ProductWithIncidents>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceSummaryImpl implements _MaintenanceSummary {
  const _$MaintenanceSummaryImpl({
    required this.totalProductosConProblema,
    required this.totalEnGarantia,
    required this.totalPerdidos,
    required this.totalDanadoSinGarantia,
    required this.totalVerificados,
    required this.totalReparados,
    required this.totalEnRevision,
    required this.garantiasAbiertas,
    this.ultimoAudit,
    final List<ProductWithIncidents> topProductosConIncidencias = const [],
  }) : _topProductosConIncidencias = topProductosConIncidencias;

  factory _$MaintenanceSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceSummaryImplFromJson(json);

  @override
  final int totalProductosConProblema;
  @override
  final int totalEnGarantia;
  @override
  final int totalPerdidos;
  @override
  final int totalDanadoSinGarantia;
  @override
  final int totalVerificados;
  @override
  final int totalReparados;
  @override
  final int totalEnRevision;
  @override
  final int garantiasAbiertas;
  @override
  final InventoryAudit? ultimoAudit;
  final List<ProductWithIncidents> _topProductosConIncidencias;
  @override
  @JsonKey()
  List<ProductWithIncidents> get topProductosConIncidencias {
    if (_topProductosConIncidencias is EqualUnmodifiableListView)
      return _topProductosConIncidencias;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topProductosConIncidencias);
  }

  @override
  String toString() {
    return 'MaintenanceSummary(totalProductosConProblema: $totalProductosConProblema, totalEnGarantia: $totalEnGarantia, totalPerdidos: $totalPerdidos, totalDanadoSinGarantia: $totalDanadoSinGarantia, totalVerificados: $totalVerificados, totalReparados: $totalReparados, totalEnRevision: $totalEnRevision, garantiasAbiertas: $garantiasAbiertas, ultimoAudit: $ultimoAudit, topProductosConIncidencias: $topProductosConIncidencias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceSummaryImpl &&
            (identical(
                  other.totalProductosConProblema,
                  totalProductosConProblema,
                ) ||
                other.totalProductosConProblema == totalProductosConProblema) &&
            (identical(other.totalEnGarantia, totalEnGarantia) ||
                other.totalEnGarantia == totalEnGarantia) &&
            (identical(other.totalPerdidos, totalPerdidos) ||
                other.totalPerdidos == totalPerdidos) &&
            (identical(other.totalDanadoSinGarantia, totalDanadoSinGarantia) ||
                other.totalDanadoSinGarantia == totalDanadoSinGarantia) &&
            (identical(other.totalVerificados, totalVerificados) ||
                other.totalVerificados == totalVerificados) &&
            (identical(other.totalReparados, totalReparados) ||
                other.totalReparados == totalReparados) &&
            (identical(other.totalEnRevision, totalEnRevision) ||
                other.totalEnRevision == totalEnRevision) &&
            (identical(other.garantiasAbiertas, garantiasAbiertas) ||
                other.garantiasAbiertas == garantiasAbiertas) &&
            (identical(other.ultimoAudit, ultimoAudit) ||
                other.ultimoAudit == ultimoAudit) &&
            const DeepCollectionEquality().equals(
              other._topProductosConIncidencias,
              _topProductosConIncidencias,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalProductosConProblema,
    totalEnGarantia,
    totalPerdidos,
    totalDanadoSinGarantia,
    totalVerificados,
    totalReparados,
    totalEnRevision,
    garantiasAbiertas,
    ultimoAudit,
    const DeepCollectionEquality().hash(_topProductosConIncidencias),
  );

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceSummaryImplCopyWith<_$MaintenanceSummaryImpl> get copyWith =>
      __$$MaintenanceSummaryImplCopyWithImpl<_$MaintenanceSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceSummaryImplToJson(this);
  }
}

abstract class _MaintenanceSummary implements MaintenanceSummary {
  const factory _MaintenanceSummary({
    required final int totalProductosConProblema,
    required final int totalEnGarantia,
    required final int totalPerdidos,
    required final int totalDanadoSinGarantia,
    required final int totalVerificados,
    required final int totalReparados,
    required final int totalEnRevision,
    required final int garantiasAbiertas,
    final InventoryAudit? ultimoAudit,
    final List<ProductWithIncidents> topProductosConIncidencias,
  }) = _$MaintenanceSummaryImpl;

  factory _MaintenanceSummary.fromJson(Map<String, dynamic> json) =
      _$MaintenanceSummaryImpl.fromJson;

  @override
  int get totalProductosConProblema;
  @override
  int get totalEnGarantia;
  @override
  int get totalPerdidos;
  @override
  int get totalDanadoSinGarantia;
  @override
  int get totalVerificados;
  @override
  int get totalReparados;
  @override
  int get totalEnRevision;
  @override
  int get garantiasAbiertas;
  @override
  InventoryAudit? get ultimoAudit;
  @override
  List<ProductWithIncidents> get topProductosConIncidencias;

  /// Create a copy of MaintenanceSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaintenanceSummaryImplCopyWith<_$MaintenanceSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductWithIncidents _$ProductWithIncidentsFromJson(Map<String, dynamic> json) {
  return _ProductWithIncidents.fromJson(json);
}

/// @nodoc
mixin _$ProductWithIncidents {
  String get id => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  String? get imagenUrl => throw _privateConstructorUsedError;
  int get incidencias => throw _privateConstructorUsedError;

  /// Serializes this ProductWithIncidents to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductWithIncidents
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductWithIncidentsCopyWith<ProductWithIncidents> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductWithIncidentsCopyWith<$Res> {
  factory $ProductWithIncidentsCopyWith(
    ProductWithIncidents value,
    $Res Function(ProductWithIncidents) then,
  ) = _$ProductWithIncidentsCopyWithImpl<$Res, ProductWithIncidents>;
  @useResult
  $Res call({String id, String nombre, String? imagenUrl, int incidencias});
}

/// @nodoc
class _$ProductWithIncidentsCopyWithImpl<
  $Res,
  $Val extends ProductWithIncidents
>
    implements $ProductWithIncidentsCopyWith<$Res> {
  _$ProductWithIncidentsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductWithIncidents
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? imagenUrl = freezed,
    Object? incidencias = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nombre: null == nombre
                ? _value.nombre
                : nombre // ignore: cast_nullable_to_non_nullable
                      as String,
            imagenUrl: freezed == imagenUrl
                ? _value.imagenUrl
                : imagenUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            incidencias: null == incidencias
                ? _value.incidencias
                : incidencias // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductWithIncidentsImplCopyWith<$Res>
    implements $ProductWithIncidentsCopyWith<$Res> {
  factory _$$ProductWithIncidentsImplCopyWith(
    _$ProductWithIncidentsImpl value,
    $Res Function(_$ProductWithIncidentsImpl) then,
  ) = __$$ProductWithIncidentsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String nombre, String? imagenUrl, int incidencias});
}

/// @nodoc
class __$$ProductWithIncidentsImplCopyWithImpl<$Res>
    extends _$ProductWithIncidentsCopyWithImpl<$Res, _$ProductWithIncidentsImpl>
    implements _$$ProductWithIncidentsImplCopyWith<$Res> {
  __$$ProductWithIncidentsImplCopyWithImpl(
    _$ProductWithIncidentsImpl _value,
    $Res Function(_$ProductWithIncidentsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductWithIncidents
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? imagenUrl = freezed,
    Object? incidencias = null,
  }) {
    return _then(
      _$ProductWithIncidentsImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nombre: null == nombre
            ? _value.nombre
            : nombre // ignore: cast_nullable_to_non_nullable
                  as String,
        imagenUrl: freezed == imagenUrl
            ? _value.imagenUrl
            : imagenUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        incidencias: null == incidencias
            ? _value.incidencias
            : incidencias // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductWithIncidentsImpl implements _ProductWithIncidents {
  const _$ProductWithIncidentsImpl({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    required this.incidencias,
  });

  factory _$ProductWithIncidentsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductWithIncidentsImplFromJson(json);

  @override
  final String id;
  @override
  final String nombre;
  @override
  final String? imagenUrl;
  @override
  final int incidencias;

  @override
  String toString() {
    return 'ProductWithIncidents(id: $id, nombre: $nombre, imagenUrl: $imagenUrl, incidencias: $incidencias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductWithIncidentsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
            (identical(other.imagenUrl, imagenUrl) ||
                other.imagenUrl == imagenUrl) &&
            (identical(other.incidencias, incidencias) ||
                other.incidencias == incidencias));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, nombre, imagenUrl, incidencias);

  /// Create a copy of ProductWithIncidents
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductWithIncidentsImplCopyWith<_$ProductWithIncidentsImpl>
  get copyWith =>
      __$$ProductWithIncidentsImplCopyWithImpl<_$ProductWithIncidentsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductWithIncidentsImplToJson(this);
  }
}

abstract class _ProductWithIncidents implements ProductWithIncidents {
  const factory _ProductWithIncidents({
    required final String id,
    required final String nombre,
    final String? imagenUrl,
    required final int incidencias,
  }) = _$ProductWithIncidentsImpl;

  factory _ProductWithIncidents.fromJson(Map<String, dynamic> json) =
      _$ProductWithIncidentsImpl.fromJson;

  @override
  String get id;
  @override
  String get nombre;
  @override
  String? get imagenUrl;
  @override
  int get incidencias;

  /// Create a copy of ProductWithIncidents
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductWithIncidentsImplCopyWith<_$ProductWithIncidentsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MaintenanceListResponse _$MaintenanceListResponseFromJson(
  Map<String, dynamic> json,
) {
  return _MaintenanceListResponse.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceListResponse {
  List<MaintenanceRecord> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;

  /// Serializes this MaintenanceListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaintenanceListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaintenanceListResponseCopyWith<MaintenanceListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceListResponseCopyWith<$Res> {
  factory $MaintenanceListResponseCopyWith(
    MaintenanceListResponse value,
    $Res Function(MaintenanceListResponse) then,
  ) = _$MaintenanceListResponseCopyWithImpl<$Res, MaintenanceListResponse>;
  @useResult
  $Res call({
    List<MaintenanceRecord> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class _$MaintenanceListResponseCopyWithImpl<
  $Res,
  $Val extends MaintenanceListResponse
>
    implements $MaintenanceListResponseCopyWith<$Res> {
  _$MaintenanceListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaintenanceListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MaintenanceRecord>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaintenanceListResponseImplCopyWith<$Res>
    implements $MaintenanceListResponseCopyWith<$Res> {
  factory _$$MaintenanceListResponseImplCopyWith(
    _$MaintenanceListResponseImpl value,
    $Res Function(_$MaintenanceListResponseImpl) then,
  ) = __$$MaintenanceListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<MaintenanceRecord> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class __$$MaintenanceListResponseImplCopyWithImpl<$Res>
    extends
        _$MaintenanceListResponseCopyWithImpl<
          $Res,
          _$MaintenanceListResponseImpl
        >
    implements _$$MaintenanceListResponseImplCopyWith<$Res> {
  __$$MaintenanceListResponseImplCopyWithImpl(
    _$MaintenanceListResponseImpl _value,
    $Res Function(_$MaintenanceListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaintenanceListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _$MaintenanceListResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MaintenanceRecord>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceListResponseImpl implements _MaintenanceListResponse {
  const _$MaintenanceListResponseImpl({
    required final List<MaintenanceRecord> items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : _items = items;

  factory _$MaintenanceListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceListResponseImplFromJson(json);

  final List<MaintenanceRecord> _items;
  @override
  List<MaintenanceRecord> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;
  @override
  final int totalPages;

  @override
  String toString() {
    return 'MaintenanceListResponse(items: $items, total: $total, page: $page, limit: $limit, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    page,
    limit,
    totalPages,
  );

  /// Create a copy of MaintenanceListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceListResponseImplCopyWith<_$MaintenanceListResponseImpl>
  get copyWith =>
      __$$MaintenanceListResponseImplCopyWithImpl<
        _$MaintenanceListResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceListResponseImplToJson(this);
  }
}

abstract class _MaintenanceListResponse implements MaintenanceListResponse {
  const factory _MaintenanceListResponse({
    required final List<MaintenanceRecord> items,
    required final int total,
    required final int page,
    required final int limit,
    required final int totalPages,
  }) = _$MaintenanceListResponseImpl;

  factory _MaintenanceListResponse.fromJson(Map<String, dynamic> json) =
      _$MaintenanceListResponseImpl.fromJson;

  @override
  List<MaintenanceRecord> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  int get totalPages;

  /// Create a copy of MaintenanceListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaintenanceListResponseImplCopyWith<_$MaintenanceListResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

WarrantyListResponse _$WarrantyListResponseFromJson(Map<String, dynamic> json) {
  return _WarrantyListResponse.fromJson(json);
}

/// @nodoc
mixin _$WarrantyListResponse {
  List<WarrantyCase> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;

  /// Serializes this WarrantyListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WarrantyListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WarrantyListResponseCopyWith<WarrantyListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WarrantyListResponseCopyWith<$Res> {
  factory $WarrantyListResponseCopyWith(
    WarrantyListResponse value,
    $Res Function(WarrantyListResponse) then,
  ) = _$WarrantyListResponseCopyWithImpl<$Res, WarrantyListResponse>;
  @useResult
  $Res call({
    List<WarrantyCase> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class _$WarrantyListResponseCopyWithImpl<
  $Res,
  $Val extends WarrantyListResponse
>
    implements $WarrantyListResponseCopyWith<$Res> {
  _$WarrantyListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WarrantyListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<WarrantyCase>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WarrantyListResponseImplCopyWith<$Res>
    implements $WarrantyListResponseCopyWith<$Res> {
  factory _$$WarrantyListResponseImplCopyWith(
    _$WarrantyListResponseImpl value,
    $Res Function(_$WarrantyListResponseImpl) then,
  ) = __$$WarrantyListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<WarrantyCase> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class __$$WarrantyListResponseImplCopyWithImpl<$Res>
    extends _$WarrantyListResponseCopyWithImpl<$Res, _$WarrantyListResponseImpl>
    implements _$$WarrantyListResponseImplCopyWith<$Res> {
  __$$WarrantyListResponseImplCopyWithImpl(
    _$WarrantyListResponseImpl _value,
    $Res Function(_$WarrantyListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WarrantyListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _$WarrantyListResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<WarrantyCase>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WarrantyListResponseImpl implements _WarrantyListResponse {
  const _$WarrantyListResponseImpl({
    required final List<WarrantyCase> items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : _items = items;

  factory _$WarrantyListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarrantyListResponseImplFromJson(json);

  final List<WarrantyCase> _items;
  @override
  List<WarrantyCase> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;
  @override
  final int totalPages;

  @override
  String toString() {
    return 'WarrantyListResponse(items: $items, total: $total, page: $page, limit: $limit, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarrantyListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    page,
    limit,
    totalPages,
  );

  /// Create a copy of WarrantyListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WarrantyListResponseImplCopyWith<_$WarrantyListResponseImpl>
  get copyWith =>
      __$$WarrantyListResponseImplCopyWithImpl<_$WarrantyListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WarrantyListResponseImplToJson(this);
  }
}

abstract class _WarrantyListResponse implements WarrantyListResponse {
  const factory _WarrantyListResponse({
    required final List<WarrantyCase> items,
    required final int total,
    required final int page,
    required final int limit,
    required final int totalPages,
  }) = _$WarrantyListResponseImpl;

  factory _WarrantyListResponse.fromJson(Map<String, dynamic> json) =
      _$WarrantyListResponseImpl.fromJson;

  @override
  List<WarrantyCase> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  int get totalPages;

  /// Create a copy of WarrantyListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WarrantyListResponseImplCopyWith<_$WarrantyListResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

AuditListResponse _$AuditListResponseFromJson(Map<String, dynamic> json) {
  return _AuditListResponse.fromJson(json);
}

/// @nodoc
mixin _$AuditListResponse {
  List<InventoryAudit> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;

  /// Serializes this AuditListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuditListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditListResponseCopyWith<AuditListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditListResponseCopyWith<$Res> {
  factory $AuditListResponseCopyWith(
    AuditListResponse value,
    $Res Function(AuditListResponse) then,
  ) = _$AuditListResponseCopyWithImpl<$Res, AuditListResponse>;
  @useResult
  $Res call({
    List<InventoryAudit> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class _$AuditListResponseCopyWithImpl<$Res, $Val extends AuditListResponse>
    implements $AuditListResponseCopyWith<$Res> {
  _$AuditListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<InventoryAudit>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuditListResponseImplCopyWith<$Res>
    implements $AuditListResponseCopyWith<$Res> {
  factory _$$AuditListResponseImplCopyWith(
    _$AuditListResponseImpl value,
    $Res Function(_$AuditListResponseImpl) then,
  ) = __$$AuditListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<InventoryAudit> items,
    int total,
    int page,
    int limit,
    int totalPages,
  });
}

/// @nodoc
class __$$AuditListResponseImplCopyWithImpl<$Res>
    extends _$AuditListResponseCopyWithImpl<$Res, _$AuditListResponseImpl>
    implements _$$AuditListResponseImplCopyWith<$Res> {
  __$$AuditListResponseImplCopyWithImpl(
    _$AuditListResponseImpl _value,
    $Res Function(_$AuditListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuditListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _$AuditListResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<InventoryAudit>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuditListResponseImpl implements _AuditListResponse {
  const _$AuditListResponseImpl({
    required final List<InventoryAudit> items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : _items = items;

  factory _$AuditListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditListResponseImplFromJson(json);

  final List<InventoryAudit> _items;
  @override
  List<InventoryAudit> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;
  @override
  final int totalPages;

  @override
  String toString() {
    return 'AuditListResponse(items: $items, total: $total, page: $page, limit: $limit, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    page,
    limit,
    totalPages,
  );

  /// Create a copy of AuditListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditListResponseImplCopyWith<_$AuditListResponseImpl> get copyWith =>
      __$$AuditListResponseImplCopyWithImpl<_$AuditListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditListResponseImplToJson(this);
  }
}

abstract class _AuditListResponse implements AuditListResponse {
  const factory _AuditListResponse({
    required final List<InventoryAudit> items,
    required final int total,
    required final int page,
    required final int limit,
    required final int totalPages,
  }) = _$AuditListResponseImpl;

  factory _AuditListResponse.fromJson(Map<String, dynamic> json) =
      _$AuditListResponseImpl.fromJson;

  @override
  List<InventoryAudit> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  int get totalPages;

  /// Create a copy of AuditListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditListResponseImplCopyWith<_$AuditListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuditItemsResponse _$AuditItemsResponseFromJson(Map<String, dynamic> json) {
  return _AuditItemsResponse.fromJson(json);
}

/// @nodoc
mixin _$AuditItemsResponse {
  List<InventoryAuditItem> get items => throw _privateConstructorUsedError;

  /// Serializes this AuditItemsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuditItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditItemsResponseCopyWith<AuditItemsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditItemsResponseCopyWith<$Res> {
  factory $AuditItemsResponseCopyWith(
    AuditItemsResponse value,
    $Res Function(AuditItemsResponse) then,
  ) = _$AuditItemsResponseCopyWithImpl<$Res, AuditItemsResponse>;
  @useResult
  $Res call({List<InventoryAuditItem> items});
}

/// @nodoc
class _$AuditItemsResponseCopyWithImpl<$Res, $Val extends AuditItemsResponse>
    implements $AuditItemsResponseCopyWith<$Res> {
  _$AuditItemsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<InventoryAuditItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuditItemsResponseImplCopyWith<$Res>
    implements $AuditItemsResponseCopyWith<$Res> {
  factory _$$AuditItemsResponseImplCopyWith(
    _$AuditItemsResponseImpl value,
    $Res Function(_$AuditItemsResponseImpl) then,
  ) = __$$AuditItemsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<InventoryAuditItem> items});
}

/// @nodoc
class __$$AuditItemsResponseImplCopyWithImpl<$Res>
    extends _$AuditItemsResponseCopyWithImpl<$Res, _$AuditItemsResponseImpl>
    implements _$$AuditItemsResponseImplCopyWith<$Res> {
  __$$AuditItemsResponseImplCopyWithImpl(
    _$AuditItemsResponseImpl _value,
    $Res Function(_$AuditItemsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuditItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$AuditItemsResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<InventoryAuditItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuditItemsResponseImpl implements _AuditItemsResponse {
  const _$AuditItemsResponseImpl({
    required final List<InventoryAuditItem> items,
  }) : _items = items;

  factory _$AuditItemsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditItemsResponseImplFromJson(json);

  final List<InventoryAuditItem> _items;
  @override
  List<InventoryAuditItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'AuditItemsResponse(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditItemsResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of AuditItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditItemsResponseImplCopyWith<_$AuditItemsResponseImpl> get copyWith =>
      __$$AuditItemsResponseImplCopyWithImpl<_$AuditItemsResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditItemsResponseImplToJson(this);
  }
}

abstract class _AuditItemsResponse implements AuditItemsResponse {
  const factory _AuditItemsResponse({
    required final List<InventoryAuditItem> items,
  }) = _$AuditItemsResponseImpl;

  factory _AuditItemsResponse.fromJson(Map<String, dynamic> json) =
      _$AuditItemsResponseImpl.fromJson;

  @override
  List<InventoryAuditItem> get items;

  /// Create a copy of AuditItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditItemsResponseImplCopyWith<_$AuditItemsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateMaintenanceDto _$CreateMaintenanceDtoFromJson(Map<String, dynamic> json) {
  return _CreateMaintenanceDto.fromJson(json);
}

/// @nodoc
mixin _$CreateMaintenanceDto {
  String get productoId => throw _privateConstructorUsedError;
  MaintenanceType get maintenanceType => throw _privateConstructorUsedError;
  ProductHealthStatus? get statusBefore => throw _privateConstructorUsedError;
  ProductHealthStatus get statusAfter => throw _privateConstructorUsedError;
  IssueCategory? get issueCategory => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get internalNotes => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  String? get warrantyCaseId => throw _privateConstructorUsedError;
  List<String> get attachmentUrls => throw _privateConstructorUsedError;

  /// Serializes this CreateMaintenanceDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateMaintenanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateMaintenanceDtoCopyWith<CreateMaintenanceDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateMaintenanceDtoCopyWith<$Res> {
  factory $CreateMaintenanceDtoCopyWith(
    CreateMaintenanceDto value,
    $Res Function(CreateMaintenanceDto) then,
  ) = _$CreateMaintenanceDtoCopyWithImpl<$Res, CreateMaintenanceDto>;
  @useResult
  $Res call({
    String productoId,
    MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    List<String> attachmentUrls,
  });
}

/// @nodoc
class _$CreateMaintenanceDtoCopyWithImpl<
  $Res,
  $Val extends CreateMaintenanceDto
>
    implements $CreateMaintenanceDtoCopyWith<$Res> {
  _$CreateMaintenanceDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateMaintenanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? maintenanceType = null,
    Object? statusBefore = freezed,
    Object? statusAfter = null,
    Object? issueCategory = freezed,
    Object? description = null,
    Object? internalNotes = freezed,
    Object? cost = freezed,
    Object? warrantyCaseId = freezed,
    Object? attachmentUrls = null,
  }) {
    return _then(
      _value.copyWith(
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            maintenanceType: null == maintenanceType
                ? _value.maintenanceType
                : maintenanceType // ignore: cast_nullable_to_non_nullable
                      as MaintenanceType,
            statusBefore: freezed == statusBefore
                ? _value.statusBefore
                : statusBefore // ignore: cast_nullable_to_non_nullable
                      as ProductHealthStatus?,
            statusAfter: null == statusAfter
                ? _value.statusAfter
                : statusAfter // ignore: cast_nullable_to_non_nullable
                      as ProductHealthStatus,
            issueCategory: freezed == issueCategory
                ? _value.issueCategory
                : issueCategory // ignore: cast_nullable_to_non_nullable
                      as IssueCategory?,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            internalNotes: freezed == internalNotes
                ? _value.internalNotes
                : internalNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            warrantyCaseId: freezed == warrantyCaseId
                ? _value.warrantyCaseId
                : warrantyCaseId // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentUrls: null == attachmentUrls
                ? _value.attachmentUrls
                : attachmentUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateMaintenanceDtoImplCopyWith<$Res>
    implements $CreateMaintenanceDtoCopyWith<$Res> {
  factory _$$CreateMaintenanceDtoImplCopyWith(
    _$CreateMaintenanceDtoImpl value,
    $Res Function(_$CreateMaintenanceDtoImpl) then,
  ) = __$$CreateMaintenanceDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productoId,
    MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    List<String> attachmentUrls,
  });
}

/// @nodoc
class __$$CreateMaintenanceDtoImplCopyWithImpl<$Res>
    extends _$CreateMaintenanceDtoCopyWithImpl<$Res, _$CreateMaintenanceDtoImpl>
    implements _$$CreateMaintenanceDtoImplCopyWith<$Res> {
  __$$CreateMaintenanceDtoImplCopyWithImpl(
    _$CreateMaintenanceDtoImpl _value,
    $Res Function(_$CreateMaintenanceDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateMaintenanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? maintenanceType = null,
    Object? statusBefore = freezed,
    Object? statusAfter = null,
    Object? issueCategory = freezed,
    Object? description = null,
    Object? internalNotes = freezed,
    Object? cost = freezed,
    Object? warrantyCaseId = freezed,
    Object? attachmentUrls = null,
  }) {
    return _then(
      _$CreateMaintenanceDtoImpl(
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        maintenanceType: null == maintenanceType
            ? _value.maintenanceType
            : maintenanceType // ignore: cast_nullable_to_non_nullable
                  as MaintenanceType,
        statusBefore: freezed == statusBefore
            ? _value.statusBefore
            : statusBefore // ignore: cast_nullable_to_non_nullable
                  as ProductHealthStatus?,
        statusAfter: null == statusAfter
            ? _value.statusAfter
            : statusAfter // ignore: cast_nullable_to_non_nullable
                  as ProductHealthStatus,
        issueCategory: freezed == issueCategory
            ? _value.issueCategory
            : issueCategory // ignore: cast_nullable_to_non_nullable
                  as IssueCategory?,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        internalNotes: freezed == internalNotes
            ? _value.internalNotes
            : internalNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        warrantyCaseId: freezed == warrantyCaseId
            ? _value.warrantyCaseId
            : warrantyCaseId // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentUrls: null == attachmentUrls
            ? _value._attachmentUrls
            : attachmentUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateMaintenanceDtoImpl implements _CreateMaintenanceDto {
  const _$CreateMaintenanceDtoImpl({
    required this.productoId,
    required this.maintenanceType,
    this.statusBefore,
    required this.statusAfter,
    this.issueCategory,
    required this.description,
    this.internalNotes,
    this.cost,
    this.warrantyCaseId,
    final List<String> attachmentUrls = const [],
  }) : _attachmentUrls = attachmentUrls;

  factory _$CreateMaintenanceDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateMaintenanceDtoImplFromJson(json);

  @override
  final String productoId;
  @override
  final MaintenanceType maintenanceType;
  @override
  final ProductHealthStatus? statusBefore;
  @override
  final ProductHealthStatus statusAfter;
  @override
  final IssueCategory? issueCategory;
  @override
  final String description;
  @override
  final String? internalNotes;
  @override
  final double? cost;
  @override
  final String? warrantyCaseId;
  final List<String> _attachmentUrls;
  @override
  @JsonKey()
  List<String> get attachmentUrls {
    if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentUrls);
  }

  @override
  String toString() {
    return 'CreateMaintenanceDto(productoId: $productoId, maintenanceType: $maintenanceType, statusBefore: $statusBefore, statusAfter: $statusAfter, issueCategory: $issueCategory, description: $description, internalNotes: $internalNotes, cost: $cost, warrantyCaseId: $warrantyCaseId, attachmentUrls: $attachmentUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateMaintenanceDtoImpl &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.maintenanceType, maintenanceType) ||
                other.maintenanceType == maintenanceType) &&
            (identical(other.statusBefore, statusBefore) ||
                other.statusBefore == statusBefore) &&
            (identical(other.statusAfter, statusAfter) ||
                other.statusAfter == statusAfter) &&
            (identical(other.issueCategory, issueCategory) ||
                other.issueCategory == issueCategory) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.internalNotes, internalNotes) ||
                other.internalNotes == internalNotes) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.warrantyCaseId, warrantyCaseId) ||
                other.warrantyCaseId == warrantyCaseId) &&
            const DeepCollectionEquality().equals(
              other._attachmentUrls,
              _attachmentUrls,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    productoId,
    maintenanceType,
    statusBefore,
    statusAfter,
    issueCategory,
    description,
    internalNotes,
    cost,
    warrantyCaseId,
    const DeepCollectionEquality().hash(_attachmentUrls),
  );

  /// Create a copy of CreateMaintenanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateMaintenanceDtoImplCopyWith<_$CreateMaintenanceDtoImpl>
  get copyWith =>
      __$$CreateMaintenanceDtoImplCopyWithImpl<_$CreateMaintenanceDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateMaintenanceDtoImplToJson(this);
  }
}

abstract class _CreateMaintenanceDto implements CreateMaintenanceDto {
  const factory _CreateMaintenanceDto({
    required final String productoId,
    required final MaintenanceType maintenanceType,
    final ProductHealthStatus? statusBefore,
    required final ProductHealthStatus statusAfter,
    final IssueCategory? issueCategory,
    required final String description,
    final String? internalNotes,
    final double? cost,
    final String? warrantyCaseId,
    final List<String> attachmentUrls,
  }) = _$CreateMaintenanceDtoImpl;

  factory _CreateMaintenanceDto.fromJson(Map<String, dynamic> json) =
      _$CreateMaintenanceDtoImpl.fromJson;

  @override
  String get productoId;
  @override
  MaintenanceType get maintenanceType;
  @override
  ProductHealthStatus? get statusBefore;
  @override
  ProductHealthStatus get statusAfter;
  @override
  IssueCategory? get issueCategory;
  @override
  String get description;
  @override
  String? get internalNotes;
  @override
  double? get cost;
  @override
  String? get warrantyCaseId;
  @override
  List<String> get attachmentUrls;

  /// Create a copy of CreateMaintenanceDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateMaintenanceDtoImplCopyWith<_$CreateMaintenanceDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CreateWarrantyDto _$CreateWarrantyDtoFromJson(Map<String, dynamic> json) {
  return _CreateWarrantyDto.fromJson(json);
}

/// @nodoc
mixin _$CreateWarrantyDto {
  String get productoId => throw _privateConstructorUsedError;
  String get problemDescription => throw _privateConstructorUsedError;
  String? get supplierName => throw _privateConstructorUsedError;
  String? get supplierTicket => throw _privateConstructorUsedError;
  List<String> get attachmentUrls => throw _privateConstructorUsedError;

  /// Serializes this CreateWarrantyDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateWarrantyDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateWarrantyDtoCopyWith<CreateWarrantyDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateWarrantyDtoCopyWith<$Res> {
  factory $CreateWarrantyDtoCopyWith(
    CreateWarrantyDto value,
    $Res Function(CreateWarrantyDto) then,
  ) = _$CreateWarrantyDtoCopyWithImpl<$Res, CreateWarrantyDto>;
  @useResult
  $Res call({
    String productoId,
    String problemDescription,
    String? supplierName,
    String? supplierTicket,
    List<String> attachmentUrls,
  });
}

/// @nodoc
class _$CreateWarrantyDtoCopyWithImpl<$Res, $Val extends CreateWarrantyDto>
    implements $CreateWarrantyDtoCopyWith<$Res> {
  _$CreateWarrantyDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateWarrantyDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? problemDescription = null,
    Object? supplierName = freezed,
    Object? supplierTicket = freezed,
    Object? attachmentUrls = null,
  }) {
    return _then(
      _value.copyWith(
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            problemDescription: null == problemDescription
                ? _value.problemDescription
                : problemDescription // ignore: cast_nullable_to_non_nullable
                      as String,
            supplierName: freezed == supplierName
                ? _value.supplierName
                : supplierName // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplierTicket: freezed == supplierTicket
                ? _value.supplierTicket
                : supplierTicket // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentUrls: null == attachmentUrls
                ? _value.attachmentUrls
                : attachmentUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateWarrantyDtoImplCopyWith<$Res>
    implements $CreateWarrantyDtoCopyWith<$Res> {
  factory _$$CreateWarrantyDtoImplCopyWith(
    _$CreateWarrantyDtoImpl value,
    $Res Function(_$CreateWarrantyDtoImpl) then,
  ) = __$$CreateWarrantyDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productoId,
    String problemDescription,
    String? supplierName,
    String? supplierTicket,
    List<String> attachmentUrls,
  });
}

/// @nodoc
class __$$CreateWarrantyDtoImplCopyWithImpl<$Res>
    extends _$CreateWarrantyDtoCopyWithImpl<$Res, _$CreateWarrantyDtoImpl>
    implements _$$CreateWarrantyDtoImplCopyWith<$Res> {
  __$$CreateWarrantyDtoImplCopyWithImpl(
    _$CreateWarrantyDtoImpl _value,
    $Res Function(_$CreateWarrantyDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateWarrantyDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? problemDescription = null,
    Object? supplierName = freezed,
    Object? supplierTicket = freezed,
    Object? attachmentUrls = null,
  }) {
    return _then(
      _$CreateWarrantyDtoImpl(
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        problemDescription: null == problemDescription
            ? _value.problemDescription
            : problemDescription // ignore: cast_nullable_to_non_nullable
                  as String,
        supplierName: freezed == supplierName
            ? _value.supplierName
            : supplierName // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplierTicket: freezed == supplierTicket
            ? _value.supplierTicket
            : supplierTicket // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentUrls: null == attachmentUrls
            ? _value._attachmentUrls
            : attachmentUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateWarrantyDtoImpl implements _CreateWarrantyDto {
  const _$CreateWarrantyDtoImpl({
    required this.productoId,
    required this.problemDescription,
    this.supplierName,
    this.supplierTicket,
    final List<String> attachmentUrls = const [],
  }) : _attachmentUrls = attachmentUrls;

  factory _$CreateWarrantyDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateWarrantyDtoImplFromJson(json);

  @override
  final String productoId;
  @override
  final String problemDescription;
  @override
  final String? supplierName;
  @override
  final String? supplierTicket;
  final List<String> _attachmentUrls;
  @override
  @JsonKey()
  List<String> get attachmentUrls {
    if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentUrls);
  }

  @override
  String toString() {
    return 'CreateWarrantyDto(productoId: $productoId, problemDescription: $problemDescription, supplierName: $supplierName, supplierTicket: $supplierTicket, attachmentUrls: $attachmentUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateWarrantyDtoImpl &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.problemDescription, problemDescription) ||
                other.problemDescription == problemDescription) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.supplierTicket, supplierTicket) ||
                other.supplierTicket == supplierTicket) &&
            const DeepCollectionEquality().equals(
              other._attachmentUrls,
              _attachmentUrls,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    productoId,
    problemDescription,
    supplierName,
    supplierTicket,
    const DeepCollectionEquality().hash(_attachmentUrls),
  );

  /// Create a copy of CreateWarrantyDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateWarrantyDtoImplCopyWith<_$CreateWarrantyDtoImpl> get copyWith =>
      __$$CreateWarrantyDtoImplCopyWithImpl<_$CreateWarrantyDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateWarrantyDtoImplToJson(this);
  }
}

abstract class _CreateWarrantyDto implements CreateWarrantyDto {
  const factory _CreateWarrantyDto({
    required final String productoId,
    required final String problemDescription,
    final String? supplierName,
    final String? supplierTicket,
    final List<String> attachmentUrls,
  }) = _$CreateWarrantyDtoImpl;

  factory _CreateWarrantyDto.fromJson(Map<String, dynamic> json) =
      _$CreateWarrantyDtoImpl.fromJson;

  @override
  String get productoId;
  @override
  String get problemDescription;
  @override
  String? get supplierName;
  @override
  String? get supplierTicket;
  @override
  List<String> get attachmentUrls;

  /// Create a copy of CreateWarrantyDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateWarrantyDtoImplCopyWith<_$CreateWarrantyDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateAuditDto _$CreateAuditDtoFromJson(Map<String, dynamic> json) {
  return _CreateAuditDto.fromJson(json);
}

/// @nodoc
mixin _$CreateAuditDto {
  DateTime get auditFromDate => throw _privateConstructorUsedError;
  DateTime get auditToDate => throw _privateConstructorUsedError;
  String get weekLabel => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this CreateAuditDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateAuditDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateAuditDtoCopyWith<CreateAuditDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateAuditDtoCopyWith<$Res> {
  factory $CreateAuditDtoCopyWith(
    CreateAuditDto value,
    $Res Function(CreateAuditDto) then,
  ) = _$CreateAuditDtoCopyWithImpl<$Res, CreateAuditDto>;
  @useResult
  $Res call({
    DateTime auditFromDate,
    DateTime auditToDate,
    String weekLabel,
    String? notes,
  });
}

/// @nodoc
class _$CreateAuditDtoCopyWithImpl<$Res, $Val extends CreateAuditDto>
    implements $CreateAuditDtoCopyWith<$Res> {
  _$CreateAuditDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateAuditDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auditFromDate = null,
    Object? auditToDate = null,
    Object? weekLabel = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            auditFromDate: null == auditFromDate
                ? _value.auditFromDate
                : auditFromDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            auditToDate: null == auditToDate
                ? _value.auditToDate
                : auditToDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            weekLabel: null == weekLabel
                ? _value.weekLabel
                : weekLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateAuditDtoImplCopyWith<$Res>
    implements $CreateAuditDtoCopyWith<$Res> {
  factory _$$CreateAuditDtoImplCopyWith(
    _$CreateAuditDtoImpl value,
    $Res Function(_$CreateAuditDtoImpl) then,
  ) = __$$CreateAuditDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime auditFromDate,
    DateTime auditToDate,
    String weekLabel,
    String? notes,
  });
}

/// @nodoc
class __$$CreateAuditDtoImplCopyWithImpl<$Res>
    extends _$CreateAuditDtoCopyWithImpl<$Res, _$CreateAuditDtoImpl>
    implements _$$CreateAuditDtoImplCopyWith<$Res> {
  __$$CreateAuditDtoImplCopyWithImpl(
    _$CreateAuditDtoImpl _value,
    $Res Function(_$CreateAuditDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateAuditDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auditFromDate = null,
    Object? auditToDate = null,
    Object? weekLabel = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$CreateAuditDtoImpl(
        auditFromDate: null == auditFromDate
            ? _value.auditFromDate
            : auditFromDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        auditToDate: null == auditToDate
            ? _value.auditToDate
            : auditToDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        weekLabel: null == weekLabel
            ? _value.weekLabel
            : weekLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateAuditDtoImpl implements _CreateAuditDto {
  const _$CreateAuditDtoImpl({
    required this.auditFromDate,
    required this.auditToDate,
    required this.weekLabel,
    this.notes,
  });

  factory _$CreateAuditDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateAuditDtoImplFromJson(json);

  @override
  final DateTime auditFromDate;
  @override
  final DateTime auditToDate;
  @override
  final String weekLabel;
  @override
  final String? notes;

  @override
  String toString() {
    return 'CreateAuditDto(auditFromDate: $auditFromDate, auditToDate: $auditToDate, weekLabel: $weekLabel, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateAuditDtoImpl &&
            (identical(other.auditFromDate, auditFromDate) ||
                other.auditFromDate == auditFromDate) &&
            (identical(other.auditToDate, auditToDate) ||
                other.auditToDate == auditToDate) &&
            (identical(other.weekLabel, weekLabel) ||
                other.weekLabel == weekLabel) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, auditFromDate, auditToDate, weekLabel, notes);

  /// Create a copy of CreateAuditDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateAuditDtoImplCopyWith<_$CreateAuditDtoImpl> get copyWith =>
      __$$CreateAuditDtoImplCopyWithImpl<_$CreateAuditDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateAuditDtoImplToJson(this);
  }
}

abstract class _CreateAuditDto implements CreateAuditDto {
  const factory _CreateAuditDto({
    required final DateTime auditFromDate,
    required final DateTime auditToDate,
    required final String weekLabel,
    final String? notes,
  }) = _$CreateAuditDtoImpl;

  factory _CreateAuditDto.fromJson(Map<String, dynamic> json) =
      _$CreateAuditDtoImpl.fromJson;

  @override
  DateTime get auditFromDate;
  @override
  DateTime get auditToDate;
  @override
  String get weekLabel;
  @override
  String? get notes;

  /// Create a copy of CreateAuditDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateAuditDtoImplCopyWith<_$CreateAuditDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateAuditItemDto _$CreateAuditItemDtoFromJson(Map<String, dynamic> json) {
  return _CreateAuditItemDto.fromJson(json);
}

/// @nodoc
mixin _$CreateAuditItemDto {
  String get productoId => throw _privateConstructorUsedError;
  int get expectedQty => throw _privateConstructorUsedError;
  int get countedQty => throw _privateConstructorUsedError;
  AuditReason? get reason => throw _privateConstructorUsedError;
  String? get explanation => throw _privateConstructorUsedError;
  AuditAction get actionTaken => throw _privateConstructorUsedError;

  /// Serializes this CreateAuditItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateAuditItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateAuditItemDtoCopyWith<CreateAuditItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateAuditItemDtoCopyWith<$Res> {
  factory $CreateAuditItemDtoCopyWith(
    CreateAuditItemDto value,
    $Res Function(CreateAuditItemDto) then,
  ) = _$CreateAuditItemDtoCopyWithImpl<$Res, CreateAuditItemDto>;
  @useResult
  $Res call({
    String productoId,
    int expectedQty,
    int countedQty,
    AuditReason? reason,
    String? explanation,
    AuditAction actionTaken,
  });
}

/// @nodoc
class _$CreateAuditItemDtoCopyWithImpl<$Res, $Val extends CreateAuditItemDto>
    implements $CreateAuditItemDtoCopyWith<$Res> {
  _$CreateAuditItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateAuditItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? expectedQty = null,
    Object? countedQty = null,
    Object? reason = freezed,
    Object? explanation = freezed,
    Object? actionTaken = null,
  }) {
    return _then(
      _value.copyWith(
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as String,
            expectedQty: null == expectedQty
                ? _value.expectedQty
                : expectedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            countedQty: null == countedQty
                ? _value.countedQty
                : countedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as AuditReason?,
            explanation: freezed == explanation
                ? _value.explanation
                : explanation // ignore: cast_nullable_to_non_nullable
                      as String?,
            actionTaken: null == actionTaken
                ? _value.actionTaken
                : actionTaken // ignore: cast_nullable_to_non_nullable
                      as AuditAction,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateAuditItemDtoImplCopyWith<$Res>
    implements $CreateAuditItemDtoCopyWith<$Res> {
  factory _$$CreateAuditItemDtoImplCopyWith(
    _$CreateAuditItemDtoImpl value,
    $Res Function(_$CreateAuditItemDtoImpl) then,
  ) = __$$CreateAuditItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productoId,
    int expectedQty,
    int countedQty,
    AuditReason? reason,
    String? explanation,
    AuditAction actionTaken,
  });
}

/// @nodoc
class __$$CreateAuditItemDtoImplCopyWithImpl<$Res>
    extends _$CreateAuditItemDtoCopyWithImpl<$Res, _$CreateAuditItemDtoImpl>
    implements _$$CreateAuditItemDtoImplCopyWith<$Res> {
  __$$CreateAuditItemDtoImplCopyWithImpl(
    _$CreateAuditItemDtoImpl _value,
    $Res Function(_$CreateAuditItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateAuditItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productoId = null,
    Object? expectedQty = null,
    Object? countedQty = null,
    Object? reason = freezed,
    Object? explanation = freezed,
    Object? actionTaken = null,
  }) {
    return _then(
      _$CreateAuditItemDtoImpl(
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as String,
        expectedQty: null == expectedQty
            ? _value.expectedQty
            : expectedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        countedQty: null == countedQty
            ? _value.countedQty
            : countedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as AuditReason?,
        explanation: freezed == explanation
            ? _value.explanation
            : explanation // ignore: cast_nullable_to_non_nullable
                  as String?,
        actionTaken: null == actionTaken
            ? _value.actionTaken
            : actionTaken // ignore: cast_nullable_to_non_nullable
                  as AuditAction,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateAuditItemDtoImpl implements _CreateAuditItemDto {
  const _$CreateAuditItemDtoImpl({
    required this.productoId,
    required this.expectedQty,
    required this.countedQty,
    this.reason,
    this.explanation,
    this.actionTaken = AuditAction.pendiente,
  });

  factory _$CreateAuditItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateAuditItemDtoImplFromJson(json);

  @override
  final String productoId;
  @override
  final int expectedQty;
  @override
  final int countedQty;
  @override
  final AuditReason? reason;
  @override
  final String? explanation;
  @override
  @JsonKey()
  final AuditAction actionTaken;

  @override
  String toString() {
    return 'CreateAuditItemDto(productoId: $productoId, expectedQty: $expectedQty, countedQty: $countedQty, reason: $reason, explanation: $explanation, actionTaken: $actionTaken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateAuditItemDtoImpl &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.expectedQty, expectedQty) ||
                other.expectedQty == expectedQty) &&
            (identical(other.countedQty, countedQty) ||
                other.countedQty == countedQty) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            (identical(other.actionTaken, actionTaken) ||
                other.actionTaken == actionTaken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    productoId,
    expectedQty,
    countedQty,
    reason,
    explanation,
    actionTaken,
  );

  /// Create a copy of CreateAuditItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateAuditItemDtoImplCopyWith<_$CreateAuditItemDtoImpl> get copyWith =>
      __$$CreateAuditItemDtoImplCopyWithImpl<_$CreateAuditItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateAuditItemDtoImplToJson(this);
  }
}

abstract class _CreateAuditItemDto implements CreateAuditItemDto {
  const factory _CreateAuditItemDto({
    required final String productoId,
    required final int expectedQty,
    required final int countedQty,
    final AuditReason? reason,
    final String? explanation,
    final AuditAction actionTaken,
  }) = _$CreateAuditItemDtoImpl;

  factory _CreateAuditItemDto.fromJson(Map<String, dynamic> json) =
      _$CreateAuditItemDtoImpl.fromJson;

  @override
  String get productoId;
  @override
  int get expectedQty;
  @override
  int get countedQty;
  @override
  AuditReason? get reason;
  @override
  String? get explanation;
  @override
  AuditAction get actionTaken;

  /// Create a copy of CreateAuditItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateAuditItemDtoImplCopyWith<_$CreateAuditItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
