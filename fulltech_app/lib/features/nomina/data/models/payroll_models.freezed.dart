// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PayrollPeriod _$PayrollPeriodFromJson(Map<String, dynamic> json) {
  return _PayrollPeriod.fromJson(json);
}

/// @nodoc
mixin _$PayrollPeriod {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'year')
  int get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'month')
  int get month => throw _privateConstructorUsedError;
  @JsonKey(name: 'half')
  PayrollHalf get half => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_from')
  DateTime get dateFrom => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_to')
  DateTime get dateTo => throw _privateConstructorUsedError;
  @JsonKey(name: 'status')
  String? get status => throw _privateConstructorUsedError;

  /// Serializes this PayrollPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollPeriodCopyWith<PayrollPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollPeriodCopyWith<$Res> {
  factory $PayrollPeriodCopyWith(
    PayrollPeriod value,
    $Res Function(PayrollPeriod) then,
  ) = _$PayrollPeriodCopyWithImpl<$Res, PayrollPeriod>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'year') int year,
    @JsonKey(name: 'month') int month,
    @JsonKey(name: 'half') PayrollHalf half,
    @JsonKey(name: 'date_from') DateTime dateFrom,
    @JsonKey(name: 'date_to') DateTime dateTo,
    @JsonKey(name: 'status') String? status,
  });
}

/// @nodoc
class _$PayrollPeriodCopyWithImpl<$Res, $Val extends PayrollPeriod>
    implements $PayrollPeriodCopyWith<$Res> {
  _$PayrollPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? year = null,
    Object? month = null,
    Object? half = null,
    Object? dateFrom = null,
    Object? dateTo = null,
    Object? status = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as int,
            half: null == half
                ? _value.half
                : half // ignore: cast_nullable_to_non_nullable
                      as PayrollHalf,
            dateFrom: null == dateFrom
                ? _value.dateFrom
                : dateFrom // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dateTo: null == dateTo
                ? _value.dateTo
                : dateTo // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollPeriodImplCopyWith<$Res>
    implements $PayrollPeriodCopyWith<$Res> {
  factory _$$PayrollPeriodImplCopyWith(
    _$PayrollPeriodImpl value,
    $Res Function(_$PayrollPeriodImpl) then,
  ) = __$$PayrollPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'year') int year,
    @JsonKey(name: 'month') int month,
    @JsonKey(name: 'half') PayrollHalf half,
    @JsonKey(name: 'date_from') DateTime dateFrom,
    @JsonKey(name: 'date_to') DateTime dateTo,
    @JsonKey(name: 'status') String? status,
  });
}

/// @nodoc
class __$$PayrollPeriodImplCopyWithImpl<$Res>
    extends _$PayrollPeriodCopyWithImpl<$Res, _$PayrollPeriodImpl>
    implements _$$PayrollPeriodImplCopyWith<$Res> {
  __$$PayrollPeriodImplCopyWithImpl(
    _$PayrollPeriodImpl _value,
    $Res Function(_$PayrollPeriodImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? year = null,
    Object? month = null,
    Object? half = null,
    Object? dateFrom = null,
    Object? dateTo = null,
    Object? status = freezed,
  }) {
    return _then(
      _$PayrollPeriodImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        half: null == half
            ? _value.half
            : half // ignore: cast_nullable_to_non_nullable
                  as PayrollHalf,
        dateFrom: null == dateFrom
            ? _value.dateFrom
            : dateFrom // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dateTo: null == dateTo
            ? _value.dateTo
            : dateTo // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollPeriodImpl implements _PayrollPeriod {
  const _$PayrollPeriodImpl({
    required this.id,
    @JsonKey(name: 'year') required this.year,
    @JsonKey(name: 'month') required this.month,
    @JsonKey(name: 'half') required this.half,
    @JsonKey(name: 'date_from') required this.dateFrom,
    @JsonKey(name: 'date_to') required this.dateTo,
    @JsonKey(name: 'status') this.status,
  });

  factory _$PayrollPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollPeriodImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'year')
  final int year;
  @override
  @JsonKey(name: 'month')
  final int month;
  @override
  @JsonKey(name: 'half')
  final PayrollHalf half;
  @override
  @JsonKey(name: 'date_from')
  final DateTime dateFrom;
  @override
  @JsonKey(name: 'date_to')
  final DateTime dateTo;
  @override
  @JsonKey(name: 'status')
  final String? status;

  @override
  String toString() {
    return 'PayrollPeriod(id: $id, year: $year, month: $month, half: $half, dateFrom: $dateFrom, dateTo: $dateTo, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollPeriodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.half, half) || other.half == half) &&
            (identical(other.dateFrom, dateFrom) ||
                other.dateFrom == dateFrom) &&
            (identical(other.dateTo, dateTo) || other.dateTo == dateTo) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, year, month, half, dateFrom, dateTo, status);

  /// Create a copy of PayrollPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollPeriodImplCopyWith<_$PayrollPeriodImpl> get copyWith =>
      __$$PayrollPeriodImplCopyWithImpl<_$PayrollPeriodImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollPeriodImplToJson(this);
  }
}

abstract class _PayrollPeriod implements PayrollPeriod {
  const factory _PayrollPeriod({
    required final String id,
    @JsonKey(name: 'year') required final int year,
    @JsonKey(name: 'month') required final int month,
    @JsonKey(name: 'half') required final PayrollHalf half,
    @JsonKey(name: 'date_from') required final DateTime dateFrom,
    @JsonKey(name: 'date_to') required final DateTime dateTo,
    @JsonKey(name: 'status') final String? status,
  }) = _$PayrollPeriodImpl;

  factory _PayrollPeriod.fromJson(Map<String, dynamic> json) =
      _$PayrollPeriodImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'year')
  int get year;
  @override
  @JsonKey(name: 'month')
  int get month;
  @override
  @JsonKey(name: 'half')
  PayrollHalf get half;
  @override
  @JsonKey(name: 'date_from')
  DateTime get dateFrom;
  @override
  @JsonKey(name: 'date_to')
  DateTime get dateTo;
  @override
  @JsonKey(name: 'status')
  String? get status;

  /// Create a copy of PayrollPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollPeriodImplCopyWith<_$PayrollPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollRunTotals _$PayrollRunTotalsFromJson(Map<String, dynamic> json) {
  return _PayrollRunTotals.fromJson(json);
}

/// @nodoc
mixin _$PayrollRunTotals {
  double get gross => throw _privateConstructorUsedError;
  double get deductions => throw _privateConstructorUsedError;
  double get net => throw _privateConstructorUsedError;

  /// Serializes this PayrollRunTotals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRunTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRunTotalsCopyWith<PayrollRunTotals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRunTotalsCopyWith<$Res> {
  factory $PayrollRunTotalsCopyWith(
    PayrollRunTotals value,
    $Res Function(PayrollRunTotals) then,
  ) = _$PayrollRunTotalsCopyWithImpl<$Res, PayrollRunTotals>;
  @useResult
  $Res call({double gross, double deductions, double net});
}

/// @nodoc
class _$PayrollRunTotalsCopyWithImpl<$Res, $Val extends PayrollRunTotals>
    implements $PayrollRunTotalsCopyWith<$Res> {
  _$PayrollRunTotalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRunTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gross = null,
    Object? deductions = null,
    Object? net = null,
  }) {
    return _then(
      _value.copyWith(
            gross: null == gross
                ? _value.gross
                : gross // ignore: cast_nullable_to_non_nullable
                      as double,
            deductions: null == deductions
                ? _value.deductions
                : deductions // ignore: cast_nullable_to_non_nullable
                      as double,
            net: null == net
                ? _value.net
                : net // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollRunTotalsImplCopyWith<$Res>
    implements $PayrollRunTotalsCopyWith<$Res> {
  factory _$$PayrollRunTotalsImplCopyWith(
    _$PayrollRunTotalsImpl value,
    $Res Function(_$PayrollRunTotalsImpl) then,
  ) = __$$PayrollRunTotalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double gross, double deductions, double net});
}

/// @nodoc
class __$$PayrollRunTotalsImplCopyWithImpl<$Res>
    extends _$PayrollRunTotalsCopyWithImpl<$Res, _$PayrollRunTotalsImpl>
    implements _$$PayrollRunTotalsImplCopyWith<$Res> {
  __$$PayrollRunTotalsImplCopyWithImpl(
    _$PayrollRunTotalsImpl _value,
    $Res Function(_$PayrollRunTotalsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRunTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gross = null,
    Object? deductions = null,
    Object? net = null,
  }) {
    return _then(
      _$PayrollRunTotalsImpl(
        gross: null == gross
            ? _value.gross
            : gross // ignore: cast_nullable_to_non_nullable
                  as double,
        deductions: null == deductions
            ? _value.deductions
            : deductions // ignore: cast_nullable_to_non_nullable
                  as double,
        net: null == net
            ? _value.net
            : net // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollRunTotalsImpl implements _PayrollRunTotals {
  const _$PayrollRunTotalsImpl({
    required this.gross,
    required this.deductions,
    required this.net,
  });

  factory _$PayrollRunTotalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRunTotalsImplFromJson(json);

  @override
  final double gross;
  @override
  final double deductions;
  @override
  final double net;

  @override
  String toString() {
    return 'PayrollRunTotals(gross: $gross, deductions: $deductions, net: $net)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRunTotalsImpl &&
            (identical(other.gross, gross) || other.gross == gross) &&
            (identical(other.deductions, deductions) ||
                other.deductions == deductions) &&
            (identical(other.net, net) || other.net == net));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, gross, deductions, net);

  /// Create a copy of PayrollRunTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRunTotalsImplCopyWith<_$PayrollRunTotalsImpl> get copyWith =>
      __$$PayrollRunTotalsImplCopyWithImpl<_$PayrollRunTotalsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRunTotalsImplToJson(this);
  }
}

abstract class _PayrollRunTotals implements PayrollRunTotals {
  const factory _PayrollRunTotals({
    required final double gross,
    required final double deductions,
    required final double net,
  }) = _$PayrollRunTotalsImpl;

  factory _PayrollRunTotals.fromJson(Map<String, dynamic> json) =
      _$PayrollRunTotalsImpl.fromJson;

  @override
  double get gross;
  @override
  double get deductions;
  @override
  double get net;

  /// Create a copy of PayrollRunTotals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRunTotalsImplCopyWith<_$PayrollRunTotalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollRunListItem _$PayrollRunListItemFromJson(Map<String, dynamic> json) {
  return _PayrollRunListItem.fromJson(json);
}

/// @nodoc
mixin _$PayrollRunListItem {
  String get id => throw _privateConstructorUsedError;
  PayrollRunStatus get status => throw _privateConstructorUsedError;
  PayrollPeriod? get period => throw _privateConstructorUsedError;
  PayrollRunTotals? get totals => throw _privateConstructorUsedError;
  @JsonKey(name: 'employeesCount')
  int? get employeesCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this PayrollRunListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRunListItemCopyWith<PayrollRunListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRunListItemCopyWith<$Res> {
  factory $PayrollRunListItemCopyWith(
    PayrollRunListItem value,
    $Res Function(PayrollRunListItem) then,
  ) = _$PayrollRunListItemCopyWithImpl<$Res, PayrollRunListItem>;
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod? period,
    PayrollRunTotals? totals,
    @JsonKey(name: 'employeesCount') int? employeesCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    String? notes,
  });

  $PayrollPeriodCopyWith<$Res>? get period;
  $PayrollRunTotalsCopyWith<$Res>? get totals;
}

/// @nodoc
class _$PayrollRunListItemCopyWithImpl<$Res, $Val extends PayrollRunListItem>
    implements $PayrollRunListItemCopyWith<$Res> {
  _$PayrollRunListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = freezed,
    Object? totals = freezed,
    Object? employeesCount = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? paidAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayrollRunStatus,
            period: freezed == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as PayrollPeriod?,
            totals: freezed == totals
                ? _value.totals
                : totals // ignore: cast_nullable_to_non_nullable
                      as PayrollRunTotals?,
            employeesCount: freezed == employeesCount
                ? _value.employeesCount
                : employeesCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollPeriodCopyWith<$Res>? get period {
    if (_value.period == null) {
      return null;
    }

    return $PayrollPeriodCopyWith<$Res>(_value.period!, (value) {
      return _then(_value.copyWith(period: value) as $Val);
    });
  }

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollRunTotalsCopyWith<$Res>? get totals {
    if (_value.totals == null) {
      return null;
    }

    return $PayrollRunTotalsCopyWith<$Res>(_value.totals!, (value) {
      return _then(_value.copyWith(totals: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PayrollRunListItemImplCopyWith<$Res>
    implements $PayrollRunListItemCopyWith<$Res> {
  factory _$$PayrollRunListItemImplCopyWith(
    _$PayrollRunListItemImpl value,
    $Res Function(_$PayrollRunListItemImpl) then,
  ) = __$$PayrollRunListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod? period,
    PayrollRunTotals? totals,
    @JsonKey(name: 'employeesCount') int? employeesCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    String? notes,
  });

  @override
  $PayrollPeriodCopyWith<$Res>? get period;
  @override
  $PayrollRunTotalsCopyWith<$Res>? get totals;
}

/// @nodoc
class __$$PayrollRunListItemImplCopyWithImpl<$Res>
    extends _$PayrollRunListItemCopyWithImpl<$Res, _$PayrollRunListItemImpl>
    implements _$$PayrollRunListItemImplCopyWith<$Res> {
  __$$PayrollRunListItemImplCopyWithImpl(
    _$PayrollRunListItemImpl _value,
    $Res Function(_$PayrollRunListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = freezed,
    Object? totals = freezed,
    Object? employeesCount = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? paidAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$PayrollRunListItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayrollRunStatus,
        period: freezed == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as PayrollPeriod?,
        totals: freezed == totals
            ? _value.totals
            : totals // ignore: cast_nullable_to_non_nullable
                  as PayrollRunTotals?,
        employeesCount: freezed == employeesCount
            ? _value.employeesCount
            : employeesCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
class _$PayrollRunListItemImpl implements _PayrollRunListItem {
  const _$PayrollRunListItemImpl({
    required this.id,
    required this.status,
    this.period,
    this.totals,
    @JsonKey(name: 'employeesCount') this.employeesCount,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'paid_at') this.paidAt,
    this.notes,
  });

  factory _$PayrollRunListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRunListItemImplFromJson(json);

  @override
  final String id;
  @override
  final PayrollRunStatus status;
  @override
  final PayrollPeriod? period;
  @override
  final PayrollRunTotals? totals;
  @override
  @JsonKey(name: 'employeesCount')
  final int? employeesCount;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;
  @override
  final String? notes;

  @override
  String toString() {
    return 'PayrollRunListItem(id: $id, status: $status, period: $period, totals: $totals, employeesCount: $employeesCount, createdAt: $createdAt, updatedAt: $updatedAt, paidAt: $paidAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRunListItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.totals, totals) || other.totals == totals) &&
            (identical(other.employeesCount, employeesCount) ||
                other.employeesCount == employeesCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    period,
    totals,
    employeesCount,
    createdAt,
    updatedAt,
    paidAt,
    notes,
  );

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRunListItemImplCopyWith<_$PayrollRunListItemImpl> get copyWith =>
      __$$PayrollRunListItemImplCopyWithImpl<_$PayrollRunListItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRunListItemImplToJson(this);
  }
}

abstract class _PayrollRunListItem implements PayrollRunListItem {
  const factory _PayrollRunListItem({
    required final String id,
    required final PayrollRunStatus status,
    final PayrollPeriod? period,
    final PayrollRunTotals? totals,
    @JsonKey(name: 'employeesCount') final int? employeesCount,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'paid_at') final DateTime? paidAt,
    final String? notes,
  }) = _$PayrollRunListItemImpl;

  factory _PayrollRunListItem.fromJson(Map<String, dynamic> json) =
      _$PayrollRunListItemImpl.fromJson;

  @override
  String get id;
  @override
  PayrollRunStatus get status;
  @override
  PayrollPeriod? get period;
  @override
  PayrollRunTotals? get totals;
  @override
  @JsonKey(name: 'employeesCount')
  int? get employeesCount;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt;
  @override
  String? get notes;

  /// Create a copy of PayrollRunListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRunListItemImplCopyWith<_$PayrollRunListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollEmployee _$PayrollEmployeeFromJson(Map<String, dynamic> json) {
  return _PayrollEmployee.fromJson(json);
}

/// @nodoc
mixin _$PayrollEmployee {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'nombre_completo')
  String get nombreCompleto => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'rol')
  String get rol => throw _privateConstructorUsedError;
  @JsonKey(name: 'foto_perfil_url')
  String? get fotoPerfilUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'salario_mensual')
  double? get salarioMensual => throw _privateConstructorUsedError;

  /// Serializes this PayrollEmployee to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollEmployee
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollEmployeeCopyWith<PayrollEmployee> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollEmployeeCopyWith<$Res> {
  factory $PayrollEmployeeCopyWith(
    PayrollEmployee value,
    $Res Function(PayrollEmployee) then,
  ) = _$PayrollEmployeeCopyWithImpl<$Res, PayrollEmployee>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'nombre_completo') String nombreCompleto,
    String email,
    @JsonKey(name: 'rol') String rol,
    @JsonKey(name: 'foto_perfil_url') String? fotoPerfilUrl,
    @JsonKey(name: 'salario_mensual') double? salarioMensual,
  });
}

/// @nodoc
class _$PayrollEmployeeCopyWithImpl<$Res, $Val extends PayrollEmployee>
    implements $PayrollEmployeeCopyWith<$Res> {
  _$PayrollEmployeeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollEmployee
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = null,
    Object? rol = null,
    Object? fotoPerfilUrl = freezed,
    Object? salarioMensual = freezed,
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
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            rol: null == rol
                ? _value.rol
                : rol // ignore: cast_nullable_to_non_nullable
                      as String,
            fotoPerfilUrl: freezed == fotoPerfilUrl
                ? _value.fotoPerfilUrl
                : fotoPerfilUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            salarioMensual: freezed == salarioMensual
                ? _value.salarioMensual
                : salarioMensual // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollEmployeeImplCopyWith<$Res>
    implements $PayrollEmployeeCopyWith<$Res> {
  factory _$$PayrollEmployeeImplCopyWith(
    _$PayrollEmployeeImpl value,
    $Res Function(_$PayrollEmployeeImpl) then,
  ) = __$$PayrollEmployeeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'nombre_completo') String nombreCompleto,
    String email,
    @JsonKey(name: 'rol') String rol,
    @JsonKey(name: 'foto_perfil_url') String? fotoPerfilUrl,
    @JsonKey(name: 'salario_mensual') double? salarioMensual,
  });
}

/// @nodoc
class __$$PayrollEmployeeImplCopyWithImpl<$Res>
    extends _$PayrollEmployeeCopyWithImpl<$Res, _$PayrollEmployeeImpl>
    implements _$$PayrollEmployeeImplCopyWith<$Res> {
  __$$PayrollEmployeeImplCopyWithImpl(
    _$PayrollEmployeeImpl _value,
    $Res Function(_$PayrollEmployeeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollEmployee
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = null,
    Object? rol = null,
    Object? fotoPerfilUrl = freezed,
    Object? salarioMensual = freezed,
  }) {
    return _then(
      _$PayrollEmployeeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nombreCompleto: null == nombreCompleto
            ? _value.nombreCompleto
            : nombreCompleto // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        rol: null == rol
            ? _value.rol
            : rol // ignore: cast_nullable_to_non_nullable
                  as String,
        fotoPerfilUrl: freezed == fotoPerfilUrl
            ? _value.fotoPerfilUrl
            : fotoPerfilUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        salarioMensual: freezed == salarioMensual
            ? _value.salarioMensual
            : salarioMensual // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollEmployeeImpl implements _PayrollEmployee {
  const _$PayrollEmployeeImpl({
    required this.id,
    @JsonKey(name: 'nombre_completo') required this.nombreCompleto,
    required this.email,
    @JsonKey(name: 'rol') required this.rol,
    @JsonKey(name: 'foto_perfil_url') this.fotoPerfilUrl,
    @JsonKey(name: 'salario_mensual') this.salarioMensual,
  });

  factory _$PayrollEmployeeImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollEmployeeImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'nombre_completo')
  final String nombreCompleto;
  @override
  final String email;
  @override
  @JsonKey(name: 'rol')
  final String rol;
  @override
  @JsonKey(name: 'foto_perfil_url')
  final String? fotoPerfilUrl;
  @override
  @JsonKey(name: 'salario_mensual')
  final double? salarioMensual;

  @override
  String toString() {
    return 'PayrollEmployee(id: $id, nombreCompleto: $nombreCompleto, email: $email, rol: $rol, fotoPerfilUrl: $fotoPerfilUrl, salarioMensual: $salarioMensual)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollEmployeeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombreCompleto, nombreCompleto) ||
                other.nombreCompleto == nombreCompleto) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.rol, rol) || other.rol == rol) &&
            (identical(other.fotoPerfilUrl, fotoPerfilUrl) ||
                other.fotoPerfilUrl == fotoPerfilUrl) &&
            (identical(other.salarioMensual, salarioMensual) ||
                other.salarioMensual == salarioMensual));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nombreCompleto,
    email,
    rol,
    fotoPerfilUrl,
    salarioMensual,
  );

  /// Create a copy of PayrollEmployee
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollEmployeeImplCopyWith<_$PayrollEmployeeImpl> get copyWith =>
      __$$PayrollEmployeeImplCopyWithImpl<_$PayrollEmployeeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollEmployeeImplToJson(this);
  }
}

abstract class _PayrollEmployee implements PayrollEmployee {
  const factory _PayrollEmployee({
    required final String id,
    @JsonKey(name: 'nombre_completo') required final String nombreCompleto,
    required final String email,
    @JsonKey(name: 'rol') required final String rol,
    @JsonKey(name: 'foto_perfil_url') final String? fotoPerfilUrl,
    @JsonKey(name: 'salario_mensual') final double? salarioMensual,
  }) = _$PayrollEmployeeImpl;

  factory _PayrollEmployee.fromJson(Map<String, dynamic> json) =
      _$PayrollEmployeeImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'nombre_completo')
  String get nombreCompleto;
  @override
  String get email;
  @override
  @JsonKey(name: 'rol')
  String get rol;
  @override
  @JsonKey(name: 'foto_perfil_url')
  String? get fotoPerfilUrl;
  @override
  @JsonKey(name: 'salario_mensual')
  double? get salarioMensual;

  /// Create a copy of PayrollEmployee
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollEmployeeImplCopyWith<_$PayrollEmployeeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollLineItem _$PayrollLineItemFromJson(Map<String, dynamic> json) {
  return _PayrollLineItem.fromJson(json);
}

/// @nodoc
mixin _$PayrollLineItem {
  String get id => throw _privateConstructorUsedError;
  PayrollLineItemType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'concept_code')
  String get conceptCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'concept_name')
  String get conceptName => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;

  /// Serializes this PayrollLineItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollLineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollLineItemCopyWith<PayrollLineItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollLineItemCopyWith<$Res> {
  factory $PayrollLineItemCopyWith(
    PayrollLineItem value,
    $Res Function(PayrollLineItem) then,
  ) = _$PayrollLineItemCopyWithImpl<$Res, PayrollLineItem>;
  @useResult
  $Res call({
    String id,
    PayrollLineItemType type,
    @JsonKey(name: 'concept_code') String conceptCode,
    @JsonKey(name: 'concept_name') String conceptName,
    double amount,
  });
}

/// @nodoc
class _$PayrollLineItemCopyWithImpl<$Res, $Val extends PayrollLineItem>
    implements $PayrollLineItemCopyWith<$Res> {
  _$PayrollLineItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollLineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? conceptCode = null,
    Object? conceptName = null,
    Object? amount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PayrollLineItemType,
            conceptCode: null == conceptCode
                ? _value.conceptCode
                : conceptCode // ignore: cast_nullable_to_non_nullable
                      as String,
            conceptName: null == conceptName
                ? _value.conceptName
                : conceptName // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollLineItemImplCopyWith<$Res>
    implements $PayrollLineItemCopyWith<$Res> {
  factory _$$PayrollLineItemImplCopyWith(
    _$PayrollLineItemImpl value,
    $Res Function(_$PayrollLineItemImpl) then,
  ) = __$$PayrollLineItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PayrollLineItemType type,
    @JsonKey(name: 'concept_code') String conceptCode,
    @JsonKey(name: 'concept_name') String conceptName,
    double amount,
  });
}

/// @nodoc
class __$$PayrollLineItemImplCopyWithImpl<$Res>
    extends _$PayrollLineItemCopyWithImpl<$Res, _$PayrollLineItemImpl>
    implements _$$PayrollLineItemImplCopyWith<$Res> {
  __$$PayrollLineItemImplCopyWithImpl(
    _$PayrollLineItemImpl _value,
    $Res Function(_$PayrollLineItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollLineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? conceptCode = null,
    Object? conceptName = null,
    Object? amount = null,
  }) {
    return _then(
      _$PayrollLineItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PayrollLineItemType,
        conceptCode: null == conceptCode
            ? _value.conceptCode
            : conceptCode // ignore: cast_nullable_to_non_nullable
                  as String,
        conceptName: null == conceptName
            ? _value.conceptName
            : conceptName // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollLineItemImpl implements _PayrollLineItem {
  const _$PayrollLineItemImpl({
    required this.id,
    required this.type,
    @JsonKey(name: 'concept_code') required this.conceptCode,
    @JsonKey(name: 'concept_name') required this.conceptName,
    required this.amount,
  });

  factory _$PayrollLineItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollLineItemImplFromJson(json);

  @override
  final String id;
  @override
  final PayrollLineItemType type;
  @override
  @JsonKey(name: 'concept_code')
  final String conceptCode;
  @override
  @JsonKey(name: 'concept_name')
  final String conceptName;
  @override
  final double amount;

  @override
  String toString() {
    return 'PayrollLineItem(id: $id, type: $type, conceptCode: $conceptCode, conceptName: $conceptName, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollLineItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.conceptCode, conceptCode) ||
                other.conceptCode == conceptCode) &&
            (identical(other.conceptName, conceptName) ||
                other.conceptName == conceptName) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, type, conceptCode, conceptName, amount);

  /// Create a copy of PayrollLineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollLineItemImplCopyWith<_$PayrollLineItemImpl> get copyWith =>
      __$$PayrollLineItemImplCopyWithImpl<_$PayrollLineItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollLineItemImplToJson(this);
  }
}

abstract class _PayrollLineItem implements PayrollLineItem {
  const factory _PayrollLineItem({
    required final String id,
    required final PayrollLineItemType type,
    @JsonKey(name: 'concept_code') required final String conceptCode,
    @JsonKey(name: 'concept_name') required final String conceptName,
    required final double amount,
  }) = _$PayrollLineItemImpl;

  factory _PayrollLineItem.fromJson(Map<String, dynamic> json) =
      _$PayrollLineItemImpl.fromJson;

  @override
  String get id;
  @override
  PayrollLineItemType get type;
  @override
  @JsonKey(name: 'concept_code')
  String get conceptCode;
  @override
  @JsonKey(name: 'concept_name')
  String get conceptName;
  @override
  double get amount;

  /// Create a copy of PayrollLineItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollLineItemImplCopyWith<_$PayrollLineItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollEmployeeSummary _$PayrollEmployeeSummaryFromJson(
  Map<String, dynamic> json,
) {
  return _PayrollEmployeeSummary.fromJson(json);
}

/// @nodoc
mixin _$PayrollEmployeeSummary {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'employee_user_id')
  String get employeeUserId => throw _privateConstructorUsedError;
  PayrollEmployee get employee => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_salary_amount')
  double get baseSalaryAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'commissions_amount')
  double get commissionsAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'other_earnings_amount')
  double get otherEarningsAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'gross_amount')
  double get grossAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'statutory_deductions_amount')
  double get statutoryDeductionsAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'other_deductions_amount')
  double get otherDeductionsAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'net_amount')
  double get netAmount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  PayrollEmployeeStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'line_items')
  List<PayrollLineItem> get lineItems => throw _privateConstructorUsedError;

  /// Serializes this PayrollEmployeeSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollEmployeeSummaryCopyWith<PayrollEmployeeSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollEmployeeSummaryCopyWith<$Res> {
  factory $PayrollEmployeeSummaryCopyWith(
    PayrollEmployeeSummary value,
    $Res Function(PayrollEmployeeSummary) then,
  ) = _$PayrollEmployeeSummaryCopyWithImpl<$Res, PayrollEmployeeSummary>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'employee_user_id') String employeeUserId,
    PayrollEmployee employee,
    @JsonKey(name: 'base_salary_amount') double baseSalaryAmount,
    @JsonKey(name: 'commissions_amount') double commissionsAmount,
    @JsonKey(name: 'other_earnings_amount') double otherEarningsAmount,
    @JsonKey(name: 'gross_amount') double grossAmount,
    @JsonKey(name: 'statutory_deductions_amount')
    double statutoryDeductionsAmount,
    @JsonKey(name: 'other_deductions_amount') double otherDeductionsAmount,
    @JsonKey(name: 'net_amount') double netAmount,
    String currency,
    PayrollEmployeeStatus status,
    @JsonKey(name: 'line_items') List<PayrollLineItem> lineItems,
  });

  $PayrollEmployeeCopyWith<$Res> get employee;
}

/// @nodoc
class _$PayrollEmployeeSummaryCopyWithImpl<
  $Res,
  $Val extends PayrollEmployeeSummary
>
    implements $PayrollEmployeeSummaryCopyWith<$Res> {
  _$PayrollEmployeeSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeUserId = null,
    Object? employee = null,
    Object? baseSalaryAmount = null,
    Object? commissionsAmount = null,
    Object? otherEarningsAmount = null,
    Object? grossAmount = null,
    Object? statutoryDeductionsAmount = null,
    Object? otherDeductionsAmount = null,
    Object? netAmount = null,
    Object? currency = null,
    Object? status = null,
    Object? lineItems = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            employeeUserId: null == employeeUserId
                ? _value.employeeUserId
                : employeeUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            employee: null == employee
                ? _value.employee
                : employee // ignore: cast_nullable_to_non_nullable
                      as PayrollEmployee,
            baseSalaryAmount: null == baseSalaryAmount
                ? _value.baseSalaryAmount
                : baseSalaryAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            commissionsAmount: null == commissionsAmount
                ? _value.commissionsAmount
                : commissionsAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            otherEarningsAmount: null == otherEarningsAmount
                ? _value.otherEarningsAmount
                : otherEarningsAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            grossAmount: null == grossAmount
                ? _value.grossAmount
                : grossAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            statutoryDeductionsAmount: null == statutoryDeductionsAmount
                ? _value.statutoryDeductionsAmount
                : statutoryDeductionsAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            otherDeductionsAmount: null == otherDeductionsAmount
                ? _value.otherDeductionsAmount
                : otherDeductionsAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            netAmount: null == netAmount
                ? _value.netAmount
                : netAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayrollEmployeeStatus,
            lineItems: null == lineItems
                ? _value.lineItems
                : lineItems // ignore: cast_nullable_to_non_nullable
                      as List<PayrollLineItem>,
          )
          as $Val,
    );
  }

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollEmployeeCopyWith<$Res> get employee {
    return $PayrollEmployeeCopyWith<$Res>(_value.employee, (value) {
      return _then(_value.copyWith(employee: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PayrollEmployeeSummaryImplCopyWith<$Res>
    implements $PayrollEmployeeSummaryCopyWith<$Res> {
  factory _$$PayrollEmployeeSummaryImplCopyWith(
    _$PayrollEmployeeSummaryImpl value,
    $Res Function(_$PayrollEmployeeSummaryImpl) then,
  ) = __$$PayrollEmployeeSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'employee_user_id') String employeeUserId,
    PayrollEmployee employee,
    @JsonKey(name: 'base_salary_amount') double baseSalaryAmount,
    @JsonKey(name: 'commissions_amount') double commissionsAmount,
    @JsonKey(name: 'other_earnings_amount') double otherEarningsAmount,
    @JsonKey(name: 'gross_amount') double grossAmount,
    @JsonKey(name: 'statutory_deductions_amount')
    double statutoryDeductionsAmount,
    @JsonKey(name: 'other_deductions_amount') double otherDeductionsAmount,
    @JsonKey(name: 'net_amount') double netAmount,
    String currency,
    PayrollEmployeeStatus status,
    @JsonKey(name: 'line_items') List<PayrollLineItem> lineItems,
  });

  @override
  $PayrollEmployeeCopyWith<$Res> get employee;
}

/// @nodoc
class __$$PayrollEmployeeSummaryImplCopyWithImpl<$Res>
    extends
        _$PayrollEmployeeSummaryCopyWithImpl<$Res, _$PayrollEmployeeSummaryImpl>
    implements _$$PayrollEmployeeSummaryImplCopyWith<$Res> {
  __$$PayrollEmployeeSummaryImplCopyWithImpl(
    _$PayrollEmployeeSummaryImpl _value,
    $Res Function(_$PayrollEmployeeSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeUserId = null,
    Object? employee = null,
    Object? baseSalaryAmount = null,
    Object? commissionsAmount = null,
    Object? otherEarningsAmount = null,
    Object? grossAmount = null,
    Object? statutoryDeductionsAmount = null,
    Object? otherDeductionsAmount = null,
    Object? netAmount = null,
    Object? currency = null,
    Object? status = null,
    Object? lineItems = null,
  }) {
    return _then(
      _$PayrollEmployeeSummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        employeeUserId: null == employeeUserId
            ? _value.employeeUserId
            : employeeUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        employee: null == employee
            ? _value.employee
            : employee // ignore: cast_nullable_to_non_nullable
                  as PayrollEmployee,
        baseSalaryAmount: null == baseSalaryAmount
            ? _value.baseSalaryAmount
            : baseSalaryAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        commissionsAmount: null == commissionsAmount
            ? _value.commissionsAmount
            : commissionsAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        otherEarningsAmount: null == otherEarningsAmount
            ? _value.otherEarningsAmount
            : otherEarningsAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        grossAmount: null == grossAmount
            ? _value.grossAmount
            : grossAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        statutoryDeductionsAmount: null == statutoryDeductionsAmount
            ? _value.statutoryDeductionsAmount
            : statutoryDeductionsAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        otherDeductionsAmount: null == otherDeductionsAmount
            ? _value.otherDeductionsAmount
            : otherDeductionsAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        netAmount: null == netAmount
            ? _value.netAmount
            : netAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayrollEmployeeStatus,
        lineItems: null == lineItems
            ? _value._lineItems
            : lineItems // ignore: cast_nullable_to_non_nullable
                  as List<PayrollLineItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollEmployeeSummaryImpl implements _PayrollEmployeeSummary {
  const _$PayrollEmployeeSummaryImpl({
    required this.id,
    @JsonKey(name: 'employee_user_id') required this.employeeUserId,
    required this.employee,
    @JsonKey(name: 'base_salary_amount') required this.baseSalaryAmount,
    @JsonKey(name: 'commissions_amount') required this.commissionsAmount,
    @JsonKey(name: 'other_earnings_amount') required this.otherEarningsAmount,
    @JsonKey(name: 'gross_amount') required this.grossAmount,
    @JsonKey(name: 'statutory_deductions_amount')
    required this.statutoryDeductionsAmount,
    @JsonKey(name: 'other_deductions_amount')
    required this.otherDeductionsAmount,
    @JsonKey(name: 'net_amount') required this.netAmount,
    required this.currency,
    required this.status,
    @JsonKey(name: 'line_items') required final List<PayrollLineItem> lineItems,
  }) : _lineItems = lineItems;

  factory _$PayrollEmployeeSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollEmployeeSummaryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'employee_user_id')
  final String employeeUserId;
  @override
  final PayrollEmployee employee;
  @override
  @JsonKey(name: 'base_salary_amount')
  final double baseSalaryAmount;
  @override
  @JsonKey(name: 'commissions_amount')
  final double commissionsAmount;
  @override
  @JsonKey(name: 'other_earnings_amount')
  final double otherEarningsAmount;
  @override
  @JsonKey(name: 'gross_amount')
  final double grossAmount;
  @override
  @JsonKey(name: 'statutory_deductions_amount')
  final double statutoryDeductionsAmount;
  @override
  @JsonKey(name: 'other_deductions_amount')
  final double otherDeductionsAmount;
  @override
  @JsonKey(name: 'net_amount')
  final double netAmount;
  @override
  final String currency;
  @override
  final PayrollEmployeeStatus status;
  final List<PayrollLineItem> _lineItems;
  @override
  @JsonKey(name: 'line_items')
  List<PayrollLineItem> get lineItems {
    if (_lineItems is EqualUnmodifiableListView) return _lineItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lineItems);
  }

  @override
  String toString() {
    return 'PayrollEmployeeSummary(id: $id, employeeUserId: $employeeUserId, employee: $employee, baseSalaryAmount: $baseSalaryAmount, commissionsAmount: $commissionsAmount, otherEarningsAmount: $otherEarningsAmount, grossAmount: $grossAmount, statutoryDeductionsAmount: $statutoryDeductionsAmount, otherDeductionsAmount: $otherDeductionsAmount, netAmount: $netAmount, currency: $currency, status: $status, lineItems: $lineItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollEmployeeSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.employeeUserId, employeeUserId) ||
                other.employeeUserId == employeeUserId) &&
            (identical(other.employee, employee) ||
                other.employee == employee) &&
            (identical(other.baseSalaryAmount, baseSalaryAmount) ||
                other.baseSalaryAmount == baseSalaryAmount) &&
            (identical(other.commissionsAmount, commissionsAmount) ||
                other.commissionsAmount == commissionsAmount) &&
            (identical(other.otherEarningsAmount, otherEarningsAmount) ||
                other.otherEarningsAmount == otherEarningsAmount) &&
            (identical(other.grossAmount, grossAmount) ||
                other.grossAmount == grossAmount) &&
            (identical(
                  other.statutoryDeductionsAmount,
                  statutoryDeductionsAmount,
                ) ||
                other.statutoryDeductionsAmount == statutoryDeductionsAmount) &&
            (identical(other.otherDeductionsAmount, otherDeductionsAmount) ||
                other.otherDeductionsAmount == otherDeductionsAmount) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._lineItems,
              _lineItems,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    employeeUserId,
    employee,
    baseSalaryAmount,
    commissionsAmount,
    otherEarningsAmount,
    grossAmount,
    statutoryDeductionsAmount,
    otherDeductionsAmount,
    netAmount,
    currency,
    status,
    const DeepCollectionEquality().hash(_lineItems),
  );

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollEmployeeSummaryImplCopyWith<_$PayrollEmployeeSummaryImpl>
  get copyWith =>
      __$$PayrollEmployeeSummaryImplCopyWithImpl<_$PayrollEmployeeSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollEmployeeSummaryImplToJson(this);
  }
}

abstract class _PayrollEmployeeSummary implements PayrollEmployeeSummary {
  const factory _PayrollEmployeeSummary({
    required final String id,
    @JsonKey(name: 'employee_user_id') required final String employeeUserId,
    required final PayrollEmployee employee,
    @JsonKey(name: 'base_salary_amount') required final double baseSalaryAmount,
    @JsonKey(name: 'commissions_amount')
    required final double commissionsAmount,
    @JsonKey(name: 'other_earnings_amount')
    required final double otherEarningsAmount,
    @JsonKey(name: 'gross_amount') required final double grossAmount,
    @JsonKey(name: 'statutory_deductions_amount')
    required final double statutoryDeductionsAmount,
    @JsonKey(name: 'other_deductions_amount')
    required final double otherDeductionsAmount,
    @JsonKey(name: 'net_amount') required final double netAmount,
    required final String currency,
    required final PayrollEmployeeStatus status,
    @JsonKey(name: 'line_items') required final List<PayrollLineItem> lineItems,
  }) = _$PayrollEmployeeSummaryImpl;

  factory _PayrollEmployeeSummary.fromJson(Map<String, dynamic> json) =
      _$PayrollEmployeeSummaryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'employee_user_id')
  String get employeeUserId;
  @override
  PayrollEmployee get employee;
  @override
  @JsonKey(name: 'base_salary_amount')
  double get baseSalaryAmount;
  @override
  @JsonKey(name: 'commissions_amount')
  double get commissionsAmount;
  @override
  @JsonKey(name: 'other_earnings_amount')
  double get otherEarningsAmount;
  @override
  @JsonKey(name: 'gross_amount')
  double get grossAmount;
  @override
  @JsonKey(name: 'statutory_deductions_amount')
  double get statutoryDeductionsAmount;
  @override
  @JsonKey(name: 'other_deductions_amount')
  double get otherDeductionsAmount;
  @override
  @JsonKey(name: 'net_amount')
  double get netAmount;
  @override
  String get currency;
  @override
  PayrollEmployeeStatus get status;
  @override
  @JsonKey(name: 'line_items')
  List<PayrollLineItem> get lineItems;

  /// Create a copy of PayrollEmployeeSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollEmployeeSummaryImplCopyWith<_$PayrollEmployeeSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PayrollRunUser _$PayrollRunUserFromJson(Map<String, dynamic> json) {
  return _PayrollRunUser.fromJson(json);
}

/// @nodoc
mixin _$PayrollRunUser {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'nombre_completo')
  String get nombreCompleto => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Serializes this PayrollRunUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRunUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRunUserCopyWith<PayrollRunUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRunUserCopyWith<$Res> {
  factory $PayrollRunUserCopyWith(
    PayrollRunUser value,
    $Res Function(PayrollRunUser) then,
  ) = _$PayrollRunUserCopyWithImpl<$Res, PayrollRunUser>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'nombre_completo') String nombreCompleto,
    String email,
  });
}

/// @nodoc
class _$PayrollRunUserCopyWithImpl<$Res, $Val extends PayrollRunUser>
    implements $PayrollRunUserCopyWith<$Res> {
  _$PayrollRunUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRunUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = null,
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
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollRunUserImplCopyWith<$Res>
    implements $PayrollRunUserCopyWith<$Res> {
  factory _$$PayrollRunUserImplCopyWith(
    _$PayrollRunUserImpl value,
    $Res Function(_$PayrollRunUserImpl) then,
  ) = __$$PayrollRunUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'nombre_completo') String nombreCompleto,
    String email,
  });
}

/// @nodoc
class __$$PayrollRunUserImplCopyWithImpl<$Res>
    extends _$PayrollRunUserCopyWithImpl<$Res, _$PayrollRunUserImpl>
    implements _$$PayrollRunUserImplCopyWith<$Res> {
  __$$PayrollRunUserImplCopyWithImpl(
    _$PayrollRunUserImpl _value,
    $Res Function(_$PayrollRunUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRunUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombreCompleto = null,
    Object? email = null,
  }) {
    return _then(
      _$PayrollRunUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nombreCompleto: null == nombreCompleto
            ? _value.nombreCompleto
            : nombreCompleto // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollRunUserImpl implements _PayrollRunUser {
  const _$PayrollRunUserImpl({
    required this.id,
    @JsonKey(name: 'nombre_completo') required this.nombreCompleto,
    required this.email,
  });

  factory _$PayrollRunUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRunUserImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'nombre_completo')
  final String nombreCompleto;
  @override
  final String email;

  @override
  String toString() {
    return 'PayrollRunUser(id: $id, nombreCompleto: $nombreCompleto, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRunUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombreCompleto, nombreCompleto) ||
                other.nombreCompleto == nombreCompleto) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nombreCompleto, email);

  /// Create a copy of PayrollRunUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRunUserImplCopyWith<_$PayrollRunUserImpl> get copyWith =>
      __$$PayrollRunUserImplCopyWithImpl<_$PayrollRunUserImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRunUserImplToJson(this);
  }
}

abstract class _PayrollRunUser implements PayrollRunUser {
  const factory _PayrollRunUser({
    required final String id,
    @JsonKey(name: 'nombre_completo') required final String nombreCompleto,
    required final String email,
  }) = _$PayrollRunUserImpl;

  factory _PayrollRunUser.fromJson(Map<String, dynamic> json) =
      _$PayrollRunUserImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'nombre_completo')
  String get nombreCompleto;
  @override
  String get email;

  /// Create a copy of PayrollRunUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRunUserImplCopyWith<_$PayrollRunUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollRunDetail _$PayrollRunDetailFromJson(Map<String, dynamic> json) {
  return _PayrollRunDetail.fromJson(json);
}

/// @nodoc
mixin _$PayrollRunDetail {
  String get id => throw _privateConstructorUsedError;
  PayrollRunStatus get status => throw _privateConstructorUsedError;
  PayrollPeriod get period => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  PayrollRunUser? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'approved_by')
  PayrollRunUser? get approvedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_by')
  PayrollRunUser? get paidBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'employee_summaries')
  List<PayrollEmployeeSummary> get employeeSummaries =>
      throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this PayrollRunDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRunDetailCopyWith<PayrollRunDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRunDetailCopyWith<$Res> {
  factory $PayrollRunDetailCopyWith(
    PayrollRunDetail value,
    $Res Function(PayrollRunDetail) then,
  ) = _$PayrollRunDetailCopyWithImpl<$Res, PayrollRunDetail>;
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'created_by') PayrollRunUser? createdBy,
    @JsonKey(name: 'approved_by') PayrollRunUser? approvedBy,
    @JsonKey(name: 'paid_by') PayrollRunUser? paidBy,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'employee_summaries')
    List<PayrollEmployeeSummary> employeeSummaries,
    String? notes,
  });

  $PayrollPeriodCopyWith<$Res> get period;
  $PayrollRunUserCopyWith<$Res>? get createdBy;
  $PayrollRunUserCopyWith<$Res>? get approvedBy;
  $PayrollRunUserCopyWith<$Res>? get paidBy;
}

/// @nodoc
class _$PayrollRunDetailCopyWithImpl<$Res, $Val extends PayrollRunDetail>
    implements $PayrollRunDetailCopyWith<$Res> {
  _$PayrollRunDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = null,
    Object? createdBy = freezed,
    Object? approvedBy = freezed,
    Object? paidBy = freezed,
    Object? paidAt = freezed,
    Object? employeeSummaries = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayrollRunStatus,
            period: null == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as PayrollPeriod,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as PayrollRunUser?,
            approvedBy: freezed == approvedBy
                ? _value.approvedBy
                : approvedBy // ignore: cast_nullable_to_non_nullable
                      as PayrollRunUser?,
            paidBy: freezed == paidBy
                ? _value.paidBy
                : paidBy // ignore: cast_nullable_to_non_nullable
                      as PayrollRunUser?,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            employeeSummaries: null == employeeSummaries
                ? _value.employeeSummaries
                : employeeSummaries // ignore: cast_nullable_to_non_nullable
                      as List<PayrollEmployeeSummary>,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollPeriodCopyWith<$Res> get period {
    return $PayrollPeriodCopyWith<$Res>(_value.period, (value) {
      return _then(_value.copyWith(period: value) as $Val);
    });
  }

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollRunUserCopyWith<$Res>? get createdBy {
    if (_value.createdBy == null) {
      return null;
    }

    return $PayrollRunUserCopyWith<$Res>(_value.createdBy!, (value) {
      return _then(_value.copyWith(createdBy: value) as $Val);
    });
  }

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollRunUserCopyWith<$Res>? get approvedBy {
    if (_value.approvedBy == null) {
      return null;
    }

    return $PayrollRunUserCopyWith<$Res>(_value.approvedBy!, (value) {
      return _then(_value.copyWith(approvedBy: value) as $Val);
    });
  }

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollRunUserCopyWith<$Res>? get paidBy {
    if (_value.paidBy == null) {
      return null;
    }

    return $PayrollRunUserCopyWith<$Res>(_value.paidBy!, (value) {
      return _then(_value.copyWith(paidBy: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PayrollRunDetailImplCopyWith<$Res>
    implements $PayrollRunDetailCopyWith<$Res> {
  factory _$$PayrollRunDetailImplCopyWith(
    _$PayrollRunDetailImpl value,
    $Res Function(_$PayrollRunDetailImpl) then,
  ) = __$$PayrollRunDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'created_by') PayrollRunUser? createdBy,
    @JsonKey(name: 'approved_by') PayrollRunUser? approvedBy,
    @JsonKey(name: 'paid_by') PayrollRunUser? paidBy,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'employee_summaries')
    List<PayrollEmployeeSummary> employeeSummaries,
    String? notes,
  });

  @override
  $PayrollPeriodCopyWith<$Res> get period;
  @override
  $PayrollRunUserCopyWith<$Res>? get createdBy;
  @override
  $PayrollRunUserCopyWith<$Res>? get approvedBy;
  @override
  $PayrollRunUserCopyWith<$Res>? get paidBy;
}

/// @nodoc
class __$$PayrollRunDetailImplCopyWithImpl<$Res>
    extends _$PayrollRunDetailCopyWithImpl<$Res, _$PayrollRunDetailImpl>
    implements _$$PayrollRunDetailImplCopyWith<$Res> {
  __$$PayrollRunDetailImplCopyWithImpl(
    _$PayrollRunDetailImpl _value,
    $Res Function(_$PayrollRunDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = null,
    Object? createdBy = freezed,
    Object? approvedBy = freezed,
    Object? paidBy = freezed,
    Object? paidAt = freezed,
    Object? employeeSummaries = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$PayrollRunDetailImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayrollRunStatus,
        period: null == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as PayrollPeriod,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as PayrollRunUser?,
        approvedBy: freezed == approvedBy
            ? _value.approvedBy
            : approvedBy // ignore: cast_nullable_to_non_nullable
                  as PayrollRunUser?,
        paidBy: freezed == paidBy
            ? _value.paidBy
            : paidBy // ignore: cast_nullable_to_non_nullable
                  as PayrollRunUser?,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        employeeSummaries: null == employeeSummaries
            ? _value._employeeSummaries
            : employeeSummaries // ignore: cast_nullable_to_non_nullable
                  as List<PayrollEmployeeSummary>,
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
class _$PayrollRunDetailImpl implements _PayrollRunDetail {
  const _$PayrollRunDetailImpl({
    required this.id,
    required this.status,
    required this.period,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'approved_by') this.approvedBy,
    @JsonKey(name: 'paid_by') this.paidBy,
    @JsonKey(name: 'paid_at') this.paidAt,
    @JsonKey(name: 'employee_summaries')
    required final List<PayrollEmployeeSummary> employeeSummaries,
    this.notes,
  }) : _employeeSummaries = employeeSummaries;

  factory _$PayrollRunDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRunDetailImplFromJson(json);

  @override
  final String id;
  @override
  final PayrollRunStatus status;
  @override
  final PayrollPeriod period;
  @override
  @JsonKey(name: 'created_by')
  final PayrollRunUser? createdBy;
  @override
  @JsonKey(name: 'approved_by')
  final PayrollRunUser? approvedBy;
  @override
  @JsonKey(name: 'paid_by')
  final PayrollRunUser? paidBy;
  @override
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;
  final List<PayrollEmployeeSummary> _employeeSummaries;
  @override
  @JsonKey(name: 'employee_summaries')
  List<PayrollEmployeeSummary> get employeeSummaries {
    if (_employeeSummaries is EqualUnmodifiableListView)
      return _employeeSummaries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_employeeSummaries);
  }

  @override
  final String? notes;

  @override
  String toString() {
    return 'PayrollRunDetail(id: $id, status: $status, period: $period, createdBy: $createdBy, approvedBy: $approvedBy, paidBy: $paidBy, paidAt: $paidAt, employeeSummaries: $employeeSummaries, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRunDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.approvedBy, approvedBy) ||
                other.approvedBy == approvedBy) &&
            (identical(other.paidBy, paidBy) || other.paidBy == paidBy) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            const DeepCollectionEquality().equals(
              other._employeeSummaries,
              _employeeSummaries,
            ) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    period,
    createdBy,
    approvedBy,
    paidBy,
    paidAt,
    const DeepCollectionEquality().hash(_employeeSummaries),
    notes,
  );

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRunDetailImplCopyWith<_$PayrollRunDetailImpl> get copyWith =>
      __$$PayrollRunDetailImplCopyWithImpl<_$PayrollRunDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRunDetailImplToJson(this);
  }
}

abstract class _PayrollRunDetail implements PayrollRunDetail {
  const factory _PayrollRunDetail({
    required final String id,
    required final PayrollRunStatus status,
    required final PayrollPeriod period,
    @JsonKey(name: 'created_by') final PayrollRunUser? createdBy,
    @JsonKey(name: 'approved_by') final PayrollRunUser? approvedBy,
    @JsonKey(name: 'paid_by') final PayrollRunUser? paidBy,
    @JsonKey(name: 'paid_at') final DateTime? paidAt,
    @JsonKey(name: 'employee_summaries')
    required final List<PayrollEmployeeSummary> employeeSummaries,
    final String? notes,
  }) = _$PayrollRunDetailImpl;

  factory _PayrollRunDetail.fromJson(Map<String, dynamic> json) =
      _$PayrollRunDetailImpl.fromJson;

  @override
  String get id;
  @override
  PayrollRunStatus get status;
  @override
  PayrollPeriod get period;
  @override
  @JsonKey(name: 'created_by')
  PayrollRunUser? get createdBy;
  @override
  @JsonKey(name: 'approved_by')
  PayrollRunUser? get approvedBy;
  @override
  @JsonKey(name: 'paid_by')
  PayrollRunUser? get paidBy;
  @override
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt;
  @override
  @JsonKey(name: 'employee_summaries')
  List<PayrollEmployeeSummary> get employeeSummaries;
  @override
  String? get notes;

  /// Create a copy of PayrollRunDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRunDetailImplCopyWith<_$PayrollRunDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollRunDetailResponse _$PayrollRunDetailResponseFromJson(
  Map<String, dynamic> json,
) {
  return _PayrollRunDetailResponse.fromJson(json);
}

/// @nodoc
mixin _$PayrollRunDetailResponse {
  PayrollRunDetail get run => throw _privateConstructorUsedError;
  Map<String, dynamic> get totals => throw _privateConstructorUsedError;

  /// Serializes this PayrollRunDetailResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRunDetailResponseCopyWith<PayrollRunDetailResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRunDetailResponseCopyWith<$Res> {
  factory $PayrollRunDetailResponseCopyWith(
    PayrollRunDetailResponse value,
    $Res Function(PayrollRunDetailResponse) then,
  ) = _$PayrollRunDetailResponseCopyWithImpl<$Res, PayrollRunDetailResponse>;
  @useResult
  $Res call({PayrollRunDetail run, Map<String, dynamic> totals});

  $PayrollRunDetailCopyWith<$Res> get run;
}

/// @nodoc
class _$PayrollRunDetailResponseCopyWithImpl<
  $Res,
  $Val extends PayrollRunDetailResponse
>
    implements $PayrollRunDetailResponseCopyWith<$Res> {
  _$PayrollRunDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? run = null, Object? totals = null}) {
    return _then(
      _value.copyWith(
            run: null == run
                ? _value.run
                : run // ignore: cast_nullable_to_non_nullable
                      as PayrollRunDetail,
            totals: null == totals
                ? _value.totals
                : totals // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollRunDetailCopyWith<$Res> get run {
    return $PayrollRunDetailCopyWith<$Res>(_value.run, (value) {
      return _then(_value.copyWith(run: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PayrollRunDetailResponseImplCopyWith<$Res>
    implements $PayrollRunDetailResponseCopyWith<$Res> {
  factory _$$PayrollRunDetailResponseImplCopyWith(
    _$PayrollRunDetailResponseImpl value,
    $Res Function(_$PayrollRunDetailResponseImpl) then,
  ) = __$$PayrollRunDetailResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PayrollRunDetail run, Map<String, dynamic> totals});

  @override
  $PayrollRunDetailCopyWith<$Res> get run;
}

/// @nodoc
class __$$PayrollRunDetailResponseImplCopyWithImpl<$Res>
    extends
        _$PayrollRunDetailResponseCopyWithImpl<
          $Res,
          _$PayrollRunDetailResponseImpl
        >
    implements _$$PayrollRunDetailResponseImplCopyWith<$Res> {
  __$$PayrollRunDetailResponseImplCopyWithImpl(
    _$PayrollRunDetailResponseImpl _value,
    $Res Function(_$PayrollRunDetailResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? run = null, Object? totals = null}) {
    return _then(
      _$PayrollRunDetailResponseImpl(
        run: null == run
            ? _value.run
            : run // ignore: cast_nullable_to_non_nullable
                  as PayrollRunDetail,
        totals: null == totals
            ? _value._totals
            : totals // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollRunDetailResponseImpl implements _PayrollRunDetailResponse {
  const _$PayrollRunDetailResponseImpl({
    required this.run,
    required final Map<String, dynamic> totals,
  }) : _totals = totals;

  factory _$PayrollRunDetailResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRunDetailResponseImplFromJson(json);

  @override
  final PayrollRunDetail run;
  final Map<String, dynamic> _totals;
  @override
  Map<String, dynamic> get totals {
    if (_totals is EqualUnmodifiableMapView) return _totals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_totals);
  }

  @override
  String toString() {
    return 'PayrollRunDetailResponse(run: $run, totals: $totals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRunDetailResponseImpl &&
            (identical(other.run, run) || other.run == run) &&
            const DeepCollectionEquality().equals(other._totals, _totals));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    run,
    const DeepCollectionEquality().hash(_totals),
  );

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRunDetailResponseImplCopyWith<_$PayrollRunDetailResponseImpl>
  get copyWith =>
      __$$PayrollRunDetailResponseImplCopyWithImpl<
        _$PayrollRunDetailResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRunDetailResponseImplToJson(this);
  }
}

abstract class _PayrollRunDetailResponse implements PayrollRunDetailResponse {
  const factory _PayrollRunDetailResponse({
    required final PayrollRunDetail run,
    required final Map<String, dynamic> totals,
  }) = _$PayrollRunDetailResponseImpl;

  factory _PayrollRunDetailResponse.fromJson(Map<String, dynamic> json) =
      _$PayrollRunDetailResponseImpl.fromJson;

  @override
  PayrollRunDetail get run;
  @override
  Map<String, dynamic> get totals;

  /// Create a copy of PayrollRunDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRunDetailResponseImplCopyWith<_$PayrollRunDetailResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MyPayrollHistoryItem _$MyPayrollHistoryItemFromJson(Map<String, dynamic> json) {
  return _MyPayrollHistoryItem.fromJson(json);
}

/// @nodoc
mixin _$MyPayrollHistoryItem {
  String get runId => throw _privateConstructorUsedError;
  PayrollRunStatus get status => throw _privateConstructorUsedError;
  PayrollPeriod get period => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'net_amount')
  double get netAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'gross_amount')
  double get grossAmount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Serializes this MyPayrollHistoryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPayrollHistoryItemCopyWith<MyPayrollHistoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPayrollHistoryItemCopyWith<$Res> {
  factory $MyPayrollHistoryItemCopyWith(
    MyPayrollHistoryItem value,
    $Res Function(MyPayrollHistoryItem) then,
  ) = _$MyPayrollHistoryItemCopyWithImpl<$Res, MyPayrollHistoryItem>;
  @useResult
  $Res call({
    String runId,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'net_amount') double netAmount,
    @JsonKey(name: 'gross_amount') double grossAmount,
    String currency,
  });

  $PayrollPeriodCopyWith<$Res> get period;
}

/// @nodoc
class _$MyPayrollHistoryItemCopyWithImpl<
  $Res,
  $Val extends MyPayrollHistoryItem
>
    implements $MyPayrollHistoryItemCopyWith<$Res> {
  _$MyPayrollHistoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? status = null,
    Object? period = null,
    Object? paidAt = freezed,
    Object? netAmount = null,
    Object? grossAmount = null,
    Object? currency = null,
  }) {
    return _then(
      _value.copyWith(
            runId: null == runId
                ? _value.runId
                : runId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayrollRunStatus,
            period: null == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as PayrollPeriod,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            netAmount: null == netAmount
                ? _value.netAmount
                : netAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            grossAmount: null == grossAmount
                ? _value.grossAmount
                : grossAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollPeriodCopyWith<$Res> get period {
    return $PayrollPeriodCopyWith<$Res>(_value.period, (value) {
      return _then(_value.copyWith(period: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MyPayrollHistoryItemImplCopyWith<$Res>
    implements $MyPayrollHistoryItemCopyWith<$Res> {
  factory _$$MyPayrollHistoryItemImplCopyWith(
    _$MyPayrollHistoryItemImpl value,
    $Res Function(_$MyPayrollHistoryItemImpl) then,
  ) = __$$MyPayrollHistoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String runId,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'net_amount') double netAmount,
    @JsonKey(name: 'gross_amount') double grossAmount,
    String currency,
  });

  @override
  $PayrollPeriodCopyWith<$Res> get period;
}

/// @nodoc
class __$$MyPayrollHistoryItemImplCopyWithImpl<$Res>
    extends _$MyPayrollHistoryItemCopyWithImpl<$Res, _$MyPayrollHistoryItemImpl>
    implements _$$MyPayrollHistoryItemImplCopyWith<$Res> {
  __$$MyPayrollHistoryItemImplCopyWithImpl(
    _$MyPayrollHistoryItemImpl _value,
    $Res Function(_$MyPayrollHistoryItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? status = null,
    Object? period = null,
    Object? paidAt = freezed,
    Object? netAmount = null,
    Object? grossAmount = null,
    Object? currency = null,
  }) {
    return _then(
      _$MyPayrollHistoryItemImpl(
        runId: null == runId
            ? _value.runId
            : runId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayrollRunStatus,
        period: null == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as PayrollPeriod,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        netAmount: null == netAmount
            ? _value.netAmount
            : netAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        grossAmount: null == grossAmount
            ? _value.grossAmount
            : grossAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MyPayrollHistoryItemImpl implements _MyPayrollHistoryItem {
  const _$MyPayrollHistoryItemImpl({
    required this.runId,
    required this.status,
    required this.period,
    @JsonKey(name: 'paid_at') this.paidAt,
    @JsonKey(name: 'net_amount') required this.netAmount,
    @JsonKey(name: 'gross_amount') required this.grossAmount,
    required this.currency,
  });

  factory _$MyPayrollHistoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyPayrollHistoryItemImplFromJson(json);

  @override
  final String runId;
  @override
  final PayrollRunStatus status;
  @override
  final PayrollPeriod period;
  @override
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;
  @override
  @JsonKey(name: 'net_amount')
  final double netAmount;
  @override
  @JsonKey(name: 'gross_amount')
  final double grossAmount;
  @override
  final String currency;

  @override
  String toString() {
    return 'MyPayrollHistoryItem(runId: $runId, status: $status, period: $period, paidAt: $paidAt, netAmount: $netAmount, grossAmount: $grossAmount, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPayrollHistoryItemImpl &&
            (identical(other.runId, runId) || other.runId == runId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount) &&
            (identical(other.grossAmount, grossAmount) ||
                other.grossAmount == grossAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    runId,
    status,
    period,
    paidAt,
    netAmount,
    grossAmount,
    currency,
  );

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPayrollHistoryItemImplCopyWith<_$MyPayrollHistoryItemImpl>
  get copyWith =>
      __$$MyPayrollHistoryItemImplCopyWithImpl<_$MyPayrollHistoryItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MyPayrollHistoryItemImplToJson(this);
  }
}

abstract class _MyPayrollHistoryItem implements MyPayrollHistoryItem {
  const factory _MyPayrollHistoryItem({
    required final String runId,
    required final PayrollRunStatus status,
    required final PayrollPeriod period,
    @JsonKey(name: 'paid_at') final DateTime? paidAt,
    @JsonKey(name: 'net_amount') required final double netAmount,
    @JsonKey(name: 'gross_amount') required final double grossAmount,
    required final String currency,
  }) = _$MyPayrollHistoryItemImpl;

  factory _MyPayrollHistoryItem.fromJson(Map<String, dynamic> json) =
      _$MyPayrollHistoryItemImpl.fromJson;

  @override
  String get runId;
  @override
  PayrollRunStatus get status;
  @override
  PayrollPeriod get period;
  @override
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt;
  @override
  @JsonKey(name: 'net_amount')
  double get netAmount;
  @override
  @JsonKey(name: 'gross_amount')
  double get grossAmount;
  @override
  String get currency;

  /// Create a copy of MyPayrollHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPayrollHistoryItemImplCopyWith<_$MyPayrollHistoryItemImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MyPayrollHistoryResponse _$MyPayrollHistoryResponseFromJson(
  Map<String, dynamic> json,
) {
  return _MyPayrollHistoryResponse.fromJson(json);
}

/// @nodoc
mixin _$MyPayrollHistoryResponse {
  List<MyPayrollHistoryItem> get items => throw _privateConstructorUsedError;

  /// Serializes this MyPayrollHistoryResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyPayrollHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPayrollHistoryResponseCopyWith<MyPayrollHistoryResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPayrollHistoryResponseCopyWith<$Res> {
  factory $MyPayrollHistoryResponseCopyWith(
    MyPayrollHistoryResponse value,
    $Res Function(MyPayrollHistoryResponse) then,
  ) = _$MyPayrollHistoryResponseCopyWithImpl<$Res, MyPayrollHistoryResponse>;
  @useResult
  $Res call({List<MyPayrollHistoryItem> items});
}

/// @nodoc
class _$MyPayrollHistoryResponseCopyWithImpl<
  $Res,
  $Val extends MyPayrollHistoryResponse
>
    implements $MyPayrollHistoryResponseCopyWith<$Res> {
  _$MyPayrollHistoryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPayrollHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MyPayrollHistoryItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MyPayrollHistoryResponseImplCopyWith<$Res>
    implements $MyPayrollHistoryResponseCopyWith<$Res> {
  factory _$$MyPayrollHistoryResponseImplCopyWith(
    _$MyPayrollHistoryResponseImpl value,
    $Res Function(_$MyPayrollHistoryResponseImpl) then,
  ) = __$$MyPayrollHistoryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MyPayrollHistoryItem> items});
}

/// @nodoc
class __$$MyPayrollHistoryResponseImplCopyWithImpl<$Res>
    extends
        _$MyPayrollHistoryResponseCopyWithImpl<
          $Res,
          _$MyPayrollHistoryResponseImpl
        >
    implements _$$MyPayrollHistoryResponseImplCopyWith<$Res> {
  __$$MyPayrollHistoryResponseImplCopyWithImpl(
    _$MyPayrollHistoryResponseImpl _value,
    $Res Function(_$MyPayrollHistoryResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPayrollHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$MyPayrollHistoryResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MyPayrollHistoryItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MyPayrollHistoryResponseImpl implements _MyPayrollHistoryResponse {
  const _$MyPayrollHistoryResponseImpl({
    required final List<MyPayrollHistoryItem> items,
  }) : _items = items;

  factory _$MyPayrollHistoryResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyPayrollHistoryResponseImplFromJson(json);

  final List<MyPayrollHistoryItem> _items;
  @override
  List<MyPayrollHistoryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MyPayrollHistoryResponse(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPayrollHistoryResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of MyPayrollHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPayrollHistoryResponseImplCopyWith<_$MyPayrollHistoryResponseImpl>
  get copyWith =>
      __$$MyPayrollHistoryResponseImplCopyWithImpl<
        _$MyPayrollHistoryResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyPayrollHistoryResponseImplToJson(this);
  }
}

abstract class _MyPayrollHistoryResponse implements MyPayrollHistoryResponse {
  const factory _MyPayrollHistoryResponse({
    required final List<MyPayrollHistoryItem> items,
  }) = _$MyPayrollHistoryResponseImpl;

  factory _MyPayrollHistoryResponse.fromJson(Map<String, dynamic> json) =
      _$MyPayrollHistoryResponseImpl.fromJson;

  @override
  List<MyPayrollHistoryItem> get items;

  /// Create a copy of MyPayrollHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPayrollHistoryResponseImplCopyWith<_$MyPayrollHistoryResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PayrollPayslip _$PayrollPayslipFromJson(Map<String, dynamic> json) {
  return _PayrollPayslip.fromJson(json);
}

/// @nodoc
mixin _$PayrollPayslip {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'pdf_url')
  String? get pdfUrl => throw _privateConstructorUsedError;
  Map<String, dynamic> get snapshot => throw _privateConstructorUsedError;

  /// Serializes this PayrollPayslip to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollPayslip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollPayslipCopyWith<PayrollPayslip> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollPayslipCopyWith<$Res> {
  factory $PayrollPayslipCopyWith(
    PayrollPayslip value,
    $Res Function(PayrollPayslip) then,
  ) = _$PayrollPayslipCopyWithImpl<$Res, PayrollPayslip>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'pdf_url') String? pdfUrl,
    Map<String, dynamic> snapshot,
  });
}

/// @nodoc
class _$PayrollPayslipCopyWithImpl<$Res, $Val extends PayrollPayslip>
    implements $PayrollPayslipCopyWith<$Res> {
  _$PayrollPayslipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollPayslip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pdfUrl = freezed,
    Object? snapshot = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            pdfUrl: freezed == pdfUrl
                ? _value.pdfUrl
                : pdfUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            snapshot: null == snapshot
                ? _value.snapshot
                : snapshot // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollPayslipImplCopyWith<$Res>
    implements $PayrollPayslipCopyWith<$Res> {
  factory _$$PayrollPayslipImplCopyWith(
    _$PayrollPayslipImpl value,
    $Res Function(_$PayrollPayslipImpl) then,
  ) = __$$PayrollPayslipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'pdf_url') String? pdfUrl,
    Map<String, dynamic> snapshot,
  });
}

/// @nodoc
class __$$PayrollPayslipImplCopyWithImpl<$Res>
    extends _$PayrollPayslipCopyWithImpl<$Res, _$PayrollPayslipImpl>
    implements _$$PayrollPayslipImplCopyWith<$Res> {
  __$$PayrollPayslipImplCopyWithImpl(
    _$PayrollPayslipImpl _value,
    $Res Function(_$PayrollPayslipImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollPayslip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pdfUrl = freezed,
    Object? snapshot = null,
  }) {
    return _then(
      _$PayrollPayslipImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        pdfUrl: freezed == pdfUrl
            ? _value.pdfUrl
            : pdfUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        snapshot: null == snapshot
            ? _value._snapshot
            : snapshot // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollPayslipImpl implements _PayrollPayslip {
  const _$PayrollPayslipImpl({
    required this.id,
    @JsonKey(name: 'pdf_url') this.pdfUrl,
    required final Map<String, dynamic> snapshot,
  }) : _snapshot = snapshot;

  factory _$PayrollPayslipImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollPayslipImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'pdf_url')
  final String? pdfUrl;
  final Map<String, dynamic> _snapshot;
  @override
  Map<String, dynamic> get snapshot {
    if (_snapshot is EqualUnmodifiableMapView) return _snapshot;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_snapshot);
  }

  @override
  String toString() {
    return 'PayrollPayslip(id: $id, pdfUrl: $pdfUrl, snapshot: $snapshot)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollPayslipImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            const DeepCollectionEquality().equals(other._snapshot, _snapshot));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    pdfUrl,
    const DeepCollectionEquality().hash(_snapshot),
  );

  /// Create a copy of PayrollPayslip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollPayslipImplCopyWith<_$PayrollPayslipImpl> get copyWith =>
      __$$PayrollPayslipImplCopyWithImpl<_$PayrollPayslipImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollPayslipImplToJson(this);
  }
}

abstract class _PayrollPayslip implements PayrollPayslip {
  const factory _PayrollPayslip({
    required final String id,
    @JsonKey(name: 'pdf_url') final String? pdfUrl,
    required final Map<String, dynamic> snapshot,
  }) = _$PayrollPayslipImpl;

  factory _PayrollPayslip.fromJson(Map<String, dynamic> json) =
      _$PayrollPayslipImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'pdf_url')
  String? get pdfUrl;
  @override
  Map<String, dynamic> get snapshot;

  /// Create a copy of PayrollPayslip
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollPayslipImplCopyWith<_$PayrollPayslipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyPayrollDetailRun _$MyPayrollDetailRunFromJson(Map<String, dynamic> json) {
  return _MyPayrollDetailRun.fromJson(json);
}

/// @nodoc
mixin _$MyPayrollDetailRun {
  String get id => throw _privateConstructorUsedError;
  PayrollRunStatus get status => throw _privateConstructorUsedError;
  PayrollPeriod get period => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt => throw _privateConstructorUsedError;

  /// Serializes this MyPayrollDetailRun to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPayrollDetailRunCopyWith<MyPayrollDetailRun> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPayrollDetailRunCopyWith<$Res> {
  factory $MyPayrollDetailRunCopyWith(
    MyPayrollDetailRun value,
    $Res Function(MyPayrollDetailRun) then,
  ) = _$MyPayrollDetailRunCopyWithImpl<$Res, MyPayrollDetailRun>;
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
  });

  $PayrollPeriodCopyWith<$Res> get period;
}

/// @nodoc
class _$MyPayrollDetailRunCopyWithImpl<$Res, $Val extends MyPayrollDetailRun>
    implements $MyPayrollDetailRunCopyWith<$Res> {
  _$MyPayrollDetailRunCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = null,
    Object? paidAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayrollRunStatus,
            period: null == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as PayrollPeriod,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollPeriodCopyWith<$Res> get period {
    return $PayrollPeriodCopyWith<$Res>(_value.period, (value) {
      return _then(_value.copyWith(period: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MyPayrollDetailRunImplCopyWith<$Res>
    implements $MyPayrollDetailRunCopyWith<$Res> {
  factory _$$MyPayrollDetailRunImplCopyWith(
    _$MyPayrollDetailRunImpl value,
    $Res Function(_$MyPayrollDetailRunImpl) then,
  ) = __$$MyPayrollDetailRunImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PayrollRunStatus status,
    PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
  });

  @override
  $PayrollPeriodCopyWith<$Res> get period;
}

/// @nodoc
class __$$MyPayrollDetailRunImplCopyWithImpl<$Res>
    extends _$MyPayrollDetailRunCopyWithImpl<$Res, _$MyPayrollDetailRunImpl>
    implements _$$MyPayrollDetailRunImplCopyWith<$Res> {
  __$$MyPayrollDetailRunImplCopyWithImpl(
    _$MyPayrollDetailRunImpl _value,
    $Res Function(_$MyPayrollDetailRunImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? period = null,
    Object? paidAt = freezed,
  }) {
    return _then(
      _$MyPayrollDetailRunImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayrollRunStatus,
        period: null == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as PayrollPeriod,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MyPayrollDetailRunImpl implements _MyPayrollDetailRun {
  const _$MyPayrollDetailRunImpl({
    required this.id,
    required this.status,
    required this.period,
    @JsonKey(name: 'paid_at') this.paidAt,
  });

  factory _$MyPayrollDetailRunImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyPayrollDetailRunImplFromJson(json);

  @override
  final String id;
  @override
  final PayrollRunStatus status;
  @override
  final PayrollPeriod period;
  @override
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;

  @override
  String toString() {
    return 'MyPayrollDetailRun(id: $id, status: $status, period: $period, paidAt: $paidAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPayrollDetailRunImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, status, period, paidAt);

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPayrollDetailRunImplCopyWith<_$MyPayrollDetailRunImpl> get copyWith =>
      __$$MyPayrollDetailRunImplCopyWithImpl<_$MyPayrollDetailRunImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MyPayrollDetailRunImplToJson(this);
  }
}

abstract class _MyPayrollDetailRun implements MyPayrollDetailRun {
  const factory _MyPayrollDetailRun({
    required final String id,
    required final PayrollRunStatus status,
    required final PayrollPeriod period,
    @JsonKey(name: 'paid_at') final DateTime? paidAt,
  }) = _$MyPayrollDetailRunImpl;

  factory _MyPayrollDetailRun.fromJson(Map<String, dynamic> json) =
      _$MyPayrollDetailRunImpl.fromJson;

  @override
  String get id;
  @override
  PayrollRunStatus get status;
  @override
  PayrollPeriod get period;
  @override
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt;

  /// Create a copy of MyPayrollDetailRun
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPayrollDetailRunImplCopyWith<_$MyPayrollDetailRunImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyPayrollDetailResponse _$MyPayrollDetailResponseFromJson(
  Map<String, dynamic> json,
) {
  return _MyPayrollDetailResponse.fromJson(json);
}

/// @nodoc
mixin _$MyPayrollDetailResponse {
  MyPayrollDetailRun get run => throw _privateConstructorUsedError;
  PayrollPayslip get payslip => throw _privateConstructorUsedError;

  /// Serializes this MyPayrollDetailResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPayrollDetailResponseCopyWith<MyPayrollDetailResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPayrollDetailResponseCopyWith<$Res> {
  factory $MyPayrollDetailResponseCopyWith(
    MyPayrollDetailResponse value,
    $Res Function(MyPayrollDetailResponse) then,
  ) = _$MyPayrollDetailResponseCopyWithImpl<$Res, MyPayrollDetailResponse>;
  @useResult
  $Res call({MyPayrollDetailRun run, PayrollPayslip payslip});

  $MyPayrollDetailRunCopyWith<$Res> get run;
  $PayrollPayslipCopyWith<$Res> get payslip;
}

/// @nodoc
class _$MyPayrollDetailResponseCopyWithImpl<
  $Res,
  $Val extends MyPayrollDetailResponse
>
    implements $MyPayrollDetailResponseCopyWith<$Res> {
  _$MyPayrollDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? run = null, Object? payslip = null}) {
    return _then(
      _value.copyWith(
            run: null == run
                ? _value.run
                : run // ignore: cast_nullable_to_non_nullable
                      as MyPayrollDetailRun,
            payslip: null == payslip
                ? _value.payslip
                : payslip // ignore: cast_nullable_to_non_nullable
                      as PayrollPayslip,
          )
          as $Val,
    );
  }

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MyPayrollDetailRunCopyWith<$Res> get run {
    return $MyPayrollDetailRunCopyWith<$Res>(_value.run, (value) {
      return _then(_value.copyWith(run: value) as $Val);
    });
  }

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayrollPayslipCopyWith<$Res> get payslip {
    return $PayrollPayslipCopyWith<$Res>(_value.payslip, (value) {
      return _then(_value.copyWith(payslip: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MyPayrollDetailResponseImplCopyWith<$Res>
    implements $MyPayrollDetailResponseCopyWith<$Res> {
  factory _$$MyPayrollDetailResponseImplCopyWith(
    _$MyPayrollDetailResponseImpl value,
    $Res Function(_$MyPayrollDetailResponseImpl) then,
  ) = __$$MyPayrollDetailResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MyPayrollDetailRun run, PayrollPayslip payslip});

  @override
  $MyPayrollDetailRunCopyWith<$Res> get run;
  @override
  $PayrollPayslipCopyWith<$Res> get payslip;
}

/// @nodoc
class __$$MyPayrollDetailResponseImplCopyWithImpl<$Res>
    extends
        _$MyPayrollDetailResponseCopyWithImpl<
          $Res,
          _$MyPayrollDetailResponseImpl
        >
    implements _$$MyPayrollDetailResponseImplCopyWith<$Res> {
  __$$MyPayrollDetailResponseImplCopyWithImpl(
    _$MyPayrollDetailResponseImpl _value,
    $Res Function(_$MyPayrollDetailResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? run = null, Object? payslip = null}) {
    return _then(
      _$MyPayrollDetailResponseImpl(
        run: null == run
            ? _value.run
            : run // ignore: cast_nullable_to_non_nullable
                  as MyPayrollDetailRun,
        payslip: null == payslip
            ? _value.payslip
            : payslip // ignore: cast_nullable_to_non_nullable
                  as PayrollPayslip,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MyPayrollDetailResponseImpl implements _MyPayrollDetailResponse {
  const _$MyPayrollDetailResponseImpl({
    required this.run,
    required this.payslip,
  });

  factory _$MyPayrollDetailResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyPayrollDetailResponseImplFromJson(json);

  @override
  final MyPayrollDetailRun run;
  @override
  final PayrollPayslip payslip;

  @override
  String toString() {
    return 'MyPayrollDetailResponse(run: $run, payslip: $payslip)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPayrollDetailResponseImpl &&
            (identical(other.run, run) || other.run == run) &&
            (identical(other.payslip, payslip) || other.payslip == payslip));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, run, payslip);

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPayrollDetailResponseImplCopyWith<_$MyPayrollDetailResponseImpl>
  get copyWith =>
      __$$MyPayrollDetailResponseImplCopyWithImpl<
        _$MyPayrollDetailResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyPayrollDetailResponseImplToJson(this);
  }
}

abstract class _MyPayrollDetailResponse implements MyPayrollDetailResponse {
  const factory _MyPayrollDetailResponse({
    required final MyPayrollDetailRun run,
    required final PayrollPayslip payslip,
  }) = _$MyPayrollDetailResponseImpl;

  factory _MyPayrollDetailResponse.fromJson(Map<String, dynamic> json) =
      _$MyPayrollDetailResponseImpl.fromJson;

  @override
  MyPayrollDetailRun get run;
  @override
  PayrollPayslip get payslip;

  /// Create a copy of MyPayrollDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPayrollDetailResponseImplCopyWith<_$MyPayrollDetailResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PayrollNotificationItem _$PayrollNotificationItemFromJson(
  Map<String, dynamic> json,
) {
  return _PayrollNotificationItem.fromJson(json);
}

/// @nodoc
mixin _$PayrollNotificationItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get runId => throw _privateConstructorUsedError;
  String? get pdfUrl => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Serializes this PayrollNotificationItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollNotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollNotificationItemCopyWith<PayrollNotificationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollNotificationItemCopyWith<$Res> {
  factory $PayrollNotificationItemCopyWith(
    PayrollNotificationItem value,
    $Res Function(PayrollNotificationItem) then,
  ) = _$PayrollNotificationItemCopyWithImpl<$Res, PayrollNotificationItem>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'created_at') DateTime createdAt,
    String? runId,
    String? pdfUrl,
    String message,
  });
}

/// @nodoc
class _$PayrollNotificationItemCopyWithImpl<
  $Res,
  $Val extends PayrollNotificationItem
>
    implements $PayrollNotificationItemCopyWith<$Res> {
  _$PayrollNotificationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollNotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? runId = freezed,
    Object? pdfUrl = freezed,
    Object? message = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            runId: freezed == runId
                ? _value.runId
                : runId // ignore: cast_nullable_to_non_nullable
                      as String?,
            pdfUrl: freezed == pdfUrl
                ? _value.pdfUrl
                : pdfUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollNotificationItemImplCopyWith<$Res>
    implements $PayrollNotificationItemCopyWith<$Res> {
  factory _$$PayrollNotificationItemImplCopyWith(
    _$PayrollNotificationItemImpl value,
    $Res Function(_$PayrollNotificationItemImpl) then,
  ) = __$$PayrollNotificationItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'created_at') DateTime createdAt,
    String? runId,
    String? pdfUrl,
    String message,
  });
}

/// @nodoc
class __$$PayrollNotificationItemImplCopyWithImpl<$Res>
    extends
        _$PayrollNotificationItemCopyWithImpl<
          $Res,
          _$PayrollNotificationItemImpl
        >
    implements _$$PayrollNotificationItemImplCopyWith<$Res> {
  __$$PayrollNotificationItemImplCopyWithImpl(
    _$PayrollNotificationItemImpl _value,
    $Res Function(_$PayrollNotificationItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollNotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? runId = freezed,
    Object? pdfUrl = freezed,
    Object? message = null,
  }) {
    return _then(
      _$PayrollNotificationItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        runId: freezed == runId
            ? _value.runId
            : runId // ignore: cast_nullable_to_non_nullable
                  as String?,
        pdfUrl: freezed == pdfUrl
            ? _value.pdfUrl
            : pdfUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollNotificationItemImpl implements _PayrollNotificationItem {
  const _$PayrollNotificationItemImpl({
    required this.id,
    @JsonKey(name: 'created_at') required this.createdAt,
    this.runId,
    this.pdfUrl,
    required this.message,
  });

  factory _$PayrollNotificationItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollNotificationItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  final String? runId;
  @override
  final String? pdfUrl;
  @override
  final String message;

  @override
  String toString() {
    return 'PayrollNotificationItem(id: $id, createdAt: $createdAt, runId: $runId, pdfUrl: $pdfUrl, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollNotificationItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.runId, runId) || other.runId == runId) &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, createdAt, runId, pdfUrl, message);

  /// Create a copy of PayrollNotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollNotificationItemImplCopyWith<_$PayrollNotificationItemImpl>
  get copyWith =>
      __$$PayrollNotificationItemImplCopyWithImpl<
        _$PayrollNotificationItemImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollNotificationItemImplToJson(this);
  }
}

abstract class _PayrollNotificationItem implements PayrollNotificationItem {
  const factory _PayrollNotificationItem({
    required final String id,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    final String? runId,
    final String? pdfUrl,
    required final String message,
  }) = _$PayrollNotificationItemImpl;

  factory _PayrollNotificationItem.fromJson(Map<String, dynamic> json) =
      _$PayrollNotificationItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  String? get runId;
  @override
  String? get pdfUrl;
  @override
  String get message;

  /// Create a copy of PayrollNotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollNotificationItemImplCopyWith<_$PayrollNotificationItemImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PayrollNotificationsResponse _$PayrollNotificationsResponseFromJson(
  Map<String, dynamic> json,
) {
  return _PayrollNotificationsResponse.fromJson(json);
}

/// @nodoc
mixin _$PayrollNotificationsResponse {
  List<PayrollNotificationItem> get items => throw _privateConstructorUsedError;

  /// Serializes this PayrollNotificationsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollNotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollNotificationsResponseCopyWith<PayrollNotificationsResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollNotificationsResponseCopyWith<$Res> {
  factory $PayrollNotificationsResponseCopyWith(
    PayrollNotificationsResponse value,
    $Res Function(PayrollNotificationsResponse) then,
  ) =
      _$PayrollNotificationsResponseCopyWithImpl<
        $Res,
        PayrollNotificationsResponse
      >;
  @useResult
  $Res call({List<PayrollNotificationItem> items});
}

/// @nodoc
class _$PayrollNotificationsResponseCopyWithImpl<
  $Res,
  $Val extends PayrollNotificationsResponse
>
    implements $PayrollNotificationsResponseCopyWith<$Res> {
  _$PayrollNotificationsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollNotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<PayrollNotificationItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollNotificationsResponseImplCopyWith<$Res>
    implements $PayrollNotificationsResponseCopyWith<$Res> {
  factory _$$PayrollNotificationsResponseImplCopyWith(
    _$PayrollNotificationsResponseImpl value,
    $Res Function(_$PayrollNotificationsResponseImpl) then,
  ) = __$$PayrollNotificationsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PayrollNotificationItem> items});
}

/// @nodoc
class __$$PayrollNotificationsResponseImplCopyWithImpl<$Res>
    extends
        _$PayrollNotificationsResponseCopyWithImpl<
          $Res,
          _$PayrollNotificationsResponseImpl
        >
    implements _$$PayrollNotificationsResponseImplCopyWith<$Res> {
  __$$PayrollNotificationsResponseImplCopyWithImpl(
    _$PayrollNotificationsResponseImpl _value,
    $Res Function(_$PayrollNotificationsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollNotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$PayrollNotificationsResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PayrollNotificationItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollNotificationsResponseImpl
    implements _PayrollNotificationsResponse {
  const _$PayrollNotificationsResponseImpl({
    required final List<PayrollNotificationItem> items,
  }) : _items = items;

  factory _$PayrollNotificationsResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$PayrollNotificationsResponseImplFromJson(json);

  final List<PayrollNotificationItem> _items;
  @override
  List<PayrollNotificationItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'PayrollNotificationsResponse(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollNotificationsResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of PayrollNotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollNotificationsResponseImplCopyWith<
    _$PayrollNotificationsResponseImpl
  >
  get copyWith =>
      __$$PayrollNotificationsResponseImplCopyWithImpl<
        _$PayrollNotificationsResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollNotificationsResponseImplToJson(this);
  }
}

abstract class _PayrollNotificationsResponse
    implements PayrollNotificationsResponse {
  const factory _PayrollNotificationsResponse({
    required final List<PayrollNotificationItem> items,
  }) = _$PayrollNotificationsResponseImpl;

  factory _PayrollNotificationsResponse.fromJson(Map<String, dynamic> json) =
      _$PayrollNotificationsResponseImpl.fromJson;

  @override
  List<PayrollNotificationItem> get items;

  /// Create a copy of PayrollNotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollNotificationsResponseImplCopyWith<
    _$PayrollNotificationsResponseImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
