// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomerListResponse _$CustomerListResponseFromJson(Map<String, dynamic> json) {
  return _CustomerListResponse.fromJson(json);
}

/// @nodoc
mixin _$CustomerListResponse {
  List<CustomerItem> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  CustomerStats get stats => throw _privateConstructorUsedError;
  List<ProductLookupItem> get topProducts => throw _privateConstructorUsedError;
  List<TopCustomer> get topCustomers => throw _privateConstructorUsedError;

  /// Serializes this CustomerListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerListResponseCopyWith<CustomerListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerListResponseCopyWith<$Res> {
  factory $CustomerListResponseCopyWith(
    CustomerListResponse value,
    $Res Function(CustomerListResponse) then,
  ) = _$CustomerListResponseCopyWithImpl<$Res, CustomerListResponse>;
  @useResult
  $Res call({
    List<CustomerItem> items,
    int total,
    CustomerStats stats,
    List<ProductLookupItem> topProducts,
    List<TopCustomer> topCustomers,
  });

  $CustomerStatsCopyWith<$Res> get stats;
}

/// @nodoc
class _$CustomerListResponseCopyWithImpl<
  $Res,
  $Val extends CustomerListResponse
>
    implements $CustomerListResponseCopyWith<$Res> {
  _$CustomerListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? stats = null,
    Object? topProducts = null,
    Object? topCustomers = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CustomerItem>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            stats: null == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as CustomerStats,
            topProducts: null == topProducts
                ? _value.topProducts
                : topProducts // ignore: cast_nullable_to_non_nullable
                      as List<ProductLookupItem>,
            topCustomers: null == topCustomers
                ? _value.topCustomers
                : topCustomers // ignore: cast_nullable_to_non_nullable
                      as List<TopCustomer>,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomerStatsCopyWith<$Res> get stats {
    return $CustomerStatsCopyWith<$Res>(_value.stats, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerListResponseImplCopyWith<$Res>
    implements $CustomerListResponseCopyWith<$Res> {
  factory _$$CustomerListResponseImplCopyWith(
    _$CustomerListResponseImpl value,
    $Res Function(_$CustomerListResponseImpl) then,
  ) = __$$CustomerListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<CustomerItem> items,
    int total,
    CustomerStats stats,
    List<ProductLookupItem> topProducts,
    List<TopCustomer> topCustomers,
  });

  @override
  $CustomerStatsCopyWith<$Res> get stats;
}

/// @nodoc
class __$$CustomerListResponseImplCopyWithImpl<$Res>
    extends _$CustomerListResponseCopyWithImpl<$Res, _$CustomerListResponseImpl>
    implements _$$CustomerListResponseImplCopyWith<$Res> {
  __$$CustomerListResponseImplCopyWithImpl(
    _$CustomerListResponseImpl _value,
    $Res Function(_$CustomerListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? stats = null,
    Object? topProducts = null,
    Object? topCustomers = null,
  }) {
    return _then(
      _$CustomerListResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CustomerItem>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        stats: null == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as CustomerStats,
        topProducts: null == topProducts
            ? _value._topProducts
            : topProducts // ignore: cast_nullable_to_non_nullable
                  as List<ProductLookupItem>,
        topCustomers: null == topCustomers
            ? _value._topCustomers
            : topCustomers // ignore: cast_nullable_to_non_nullable
                  as List<TopCustomer>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerListResponseImpl implements _CustomerListResponse {
  const _$CustomerListResponseImpl({
    required final List<CustomerItem> items,
    required this.total,
    required this.stats,
    required final List<ProductLookupItem> topProducts,
    required final List<TopCustomer> topCustomers,
  }) : _items = items,
       _topProducts = topProducts,
       _topCustomers = topCustomers;

  factory _$CustomerListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerListResponseImplFromJson(json);

  final List<CustomerItem> _items;
  @override
  List<CustomerItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final CustomerStats stats;
  final List<ProductLookupItem> _topProducts;
  @override
  List<ProductLookupItem> get topProducts {
    if (_topProducts is EqualUnmodifiableListView) return _topProducts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topProducts);
  }

  final List<TopCustomer> _topCustomers;
  @override
  List<TopCustomer> get topCustomers {
    if (_topCustomers is EqualUnmodifiableListView) return _topCustomers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topCustomers);
  }

  @override
  String toString() {
    return 'CustomerListResponse(items: $items, total: $total, stats: $stats, topProducts: $topProducts, topCustomers: $topCustomers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            const DeepCollectionEquality().equals(
              other._topProducts,
              _topProducts,
            ) &&
            const DeepCollectionEquality().equals(
              other._topCustomers,
              _topCustomers,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    stats,
    const DeepCollectionEquality().hash(_topProducts),
    const DeepCollectionEquality().hash(_topCustomers),
  );

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerListResponseImplCopyWith<_$CustomerListResponseImpl>
  get copyWith =>
      __$$CustomerListResponseImplCopyWithImpl<_$CustomerListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerListResponseImplToJson(this);
  }
}

abstract class _CustomerListResponse implements CustomerListResponse {
  const factory _CustomerListResponse({
    required final List<CustomerItem> items,
    required final int total,
    required final CustomerStats stats,
    required final List<ProductLookupItem> topProducts,
    required final List<TopCustomer> topCustomers,
  }) = _$CustomerListResponseImpl;

  factory _CustomerListResponse.fromJson(Map<String, dynamic> json) =
      _$CustomerListResponseImpl.fromJson;

  @override
  List<CustomerItem> get items;
  @override
  int get total;
  @override
  CustomerStats get stats;
  @override
  List<ProductLookupItem> get topProducts;
  @override
  List<TopCustomer> get topCustomers;

  /// Create a copy of CustomerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerListResponseImplCopyWith<_$CustomerListResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

TopCustomer _$TopCustomerFromJson(Map<String, dynamic> json) {
  return _TopCustomer.fromJson(json);
}

/// @nodoc
mixin _$TopCustomer {
  String get id => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  double get totalSpent => throw _privateConstructorUsedError;
  int get totalPurchasesCount => throw _privateConstructorUsedError;

  /// Serializes this TopCustomer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopCustomer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopCustomerCopyWith<TopCustomer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopCustomerCopyWith<$Res> {
  factory $TopCustomerCopyWith(
    TopCustomer value,
    $Res Function(TopCustomer) then,
  ) = _$TopCustomerCopyWithImpl<$Res, TopCustomer>;
  @useResult
  $Res call({
    String id,
    String fullName,
    double totalSpent,
    int totalPurchasesCount,
  });
}

/// @nodoc
class _$TopCustomerCopyWithImpl<$Res, $Val extends TopCustomer>
    implements $TopCustomerCopyWith<$Res> {
  _$TopCustomerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopCustomer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? totalSpent = null,
    Object? totalPurchasesCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            totalSpent: null == totalSpent
                ? _value.totalSpent
                : totalSpent // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPurchasesCount: null == totalPurchasesCount
                ? _value.totalPurchasesCount
                : totalPurchasesCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TopCustomerImplCopyWith<$Res>
    implements $TopCustomerCopyWith<$Res> {
  factory _$$TopCustomerImplCopyWith(
    _$TopCustomerImpl value,
    $Res Function(_$TopCustomerImpl) then,
  ) = __$$TopCustomerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fullName,
    double totalSpent,
    int totalPurchasesCount,
  });
}

/// @nodoc
class __$$TopCustomerImplCopyWithImpl<$Res>
    extends _$TopCustomerCopyWithImpl<$Res, _$TopCustomerImpl>
    implements _$$TopCustomerImplCopyWith<$Res> {
  __$$TopCustomerImplCopyWithImpl(
    _$TopCustomerImpl _value,
    $Res Function(_$TopCustomerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopCustomer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? totalSpent = null,
    Object? totalPurchasesCount = null,
  }) {
    return _then(
      _$TopCustomerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSpent: null == totalSpent
            ? _value.totalSpent
            : totalSpent // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPurchasesCount: null == totalPurchasesCount
            ? _value.totalPurchasesCount
            : totalPurchasesCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopCustomerImpl implements _TopCustomer {
  const _$TopCustomerImpl({
    required this.id,
    required this.fullName,
    required this.totalSpent,
    required this.totalPurchasesCount,
  });

  factory _$TopCustomerImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopCustomerImplFromJson(json);

  @override
  final String id;
  @override
  final String fullName;
  @override
  final double totalSpent;
  @override
  final int totalPurchasesCount;

  @override
  String toString() {
    return 'TopCustomer(id: $id, fullName: $fullName, totalSpent: $totalSpent, totalPurchasesCount: $totalPurchasesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopCustomerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.totalSpent, totalSpent) ||
                other.totalSpent == totalSpent) &&
            (identical(other.totalPurchasesCount, totalPurchasesCount) ||
                other.totalPurchasesCount == totalPurchasesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, fullName, totalSpent, totalPurchasesCount);

  /// Create a copy of TopCustomer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopCustomerImplCopyWith<_$TopCustomerImpl> get copyWith =>
      __$$TopCustomerImplCopyWithImpl<_$TopCustomerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopCustomerImplToJson(this);
  }
}

abstract class _TopCustomer implements TopCustomer {
  const factory _TopCustomer({
    required final String id,
    required final String fullName,
    required final double totalSpent,
    required final int totalPurchasesCount,
  }) = _$TopCustomerImpl;

  factory _TopCustomer.fromJson(Map<String, dynamic> json) =
      _$TopCustomerImpl.fromJson;

  @override
  String get id;
  @override
  String get fullName;
  @override
  double get totalSpent;
  @override
  int get totalPurchasesCount;

  /// Create a copy of TopCustomer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopCustomerImplCopyWith<_$TopCustomerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerItem _$CustomerItemFromJson(Map<String, dynamic> json) {
  return _CustomerItem.fromJson(json);
}

/// @nodoc
mixin _$CustomerItem {
  String get id => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get whatsappId => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get isActiveCustomer => throw _privateConstructorUsedError;
  int get totalPurchasesCount => throw _privateConstructorUsedError;
  double get totalSpent => throw _privateConstructorUsedError;
  String? get lastPurchaseAt => throw _privateConstructorUsedError;
  String? get lastChatAt => throw _privateConstructorUsedError;
  String? get lastMessagePreview => throw _privateConstructorUsedError;
  LastProduct? get assignedProduct => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  bool get important => throw _privateConstructorUsedError;
  String? get internalNote => throw _privateConstructorUsedError;

  /// Serializes this CustomerItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerItemCopyWith<CustomerItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerItemCopyWith<$Res> {
  factory $CustomerItemCopyWith(
    CustomerItem value,
    $Res Function(CustomerItem) then,
  ) = _$CustomerItemCopyWithImpl<$Res, CustomerItem>;
  @useResult
  $Res call({
    String id,
    String fullName,
    String phone,
    String? whatsappId,
    String? avatarUrl,
    String status,
    bool isActiveCustomer,
    int totalPurchasesCount,
    double totalSpent,
    String? lastPurchaseAt,
    String? lastChatAt,
    String? lastMessagePreview,
    LastProduct? assignedProduct,
    List<String> tags,
    bool important,
    String? internalNote,
  });

  $LastProductCopyWith<$Res>? get assignedProduct;
}

/// @nodoc
class _$CustomerItemCopyWithImpl<$Res, $Val extends CustomerItem>
    implements $CustomerItemCopyWith<$Res> {
  _$CustomerItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? whatsappId = freezed,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? isActiveCustomer = null,
    Object? totalPurchasesCount = null,
    Object? totalSpent = null,
    Object? lastPurchaseAt = freezed,
    Object? lastChatAt = freezed,
    Object? lastMessagePreview = freezed,
    Object? assignedProduct = freezed,
    Object? tags = null,
    Object? important = null,
    Object? internalNote = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            whatsappId: freezed == whatsappId
                ? _value.whatsappId
                : whatsappId // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isActiveCustomer: null == isActiveCustomer
                ? _value.isActiveCustomer
                : isActiveCustomer // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalPurchasesCount: null == totalPurchasesCount
                ? _value.totalPurchasesCount
                : totalPurchasesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSpent: null == totalSpent
                ? _value.totalSpent
                : totalSpent // ignore: cast_nullable_to_non_nullable
                      as double,
            lastPurchaseAt: freezed == lastPurchaseAt
                ? _value.lastPurchaseAt
                : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastChatAt: freezed == lastChatAt
                ? _value.lastChatAt
                : lastChatAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessagePreview: freezed == lastMessagePreview
                ? _value.lastMessagePreview
                : lastMessagePreview // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedProduct: freezed == assignedProduct
                ? _value.assignedProduct
                : assignedProduct // ignore: cast_nullable_to_non_nullable
                      as LastProduct?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            important: null == important
                ? _value.important
                : important // ignore: cast_nullable_to_non_nullable
                      as bool,
            internalNote: freezed == internalNote
                ? _value.internalNote
                : internalNote // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LastProductCopyWith<$Res>? get assignedProduct {
    if (_value.assignedProduct == null) {
      return null;
    }

    return $LastProductCopyWith<$Res>(_value.assignedProduct!, (value) {
      return _then(_value.copyWith(assignedProduct: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerItemImplCopyWith<$Res>
    implements $CustomerItemCopyWith<$Res> {
  factory _$$CustomerItemImplCopyWith(
    _$CustomerItemImpl value,
    $Res Function(_$CustomerItemImpl) then,
  ) = __$$CustomerItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fullName,
    String phone,
    String? whatsappId,
    String? avatarUrl,
    String status,
    bool isActiveCustomer,
    int totalPurchasesCount,
    double totalSpent,
    String? lastPurchaseAt,
    String? lastChatAt,
    String? lastMessagePreview,
    LastProduct? assignedProduct,
    List<String> tags,
    bool important,
    String? internalNote,
  });

  @override
  $LastProductCopyWith<$Res>? get assignedProduct;
}

/// @nodoc
class __$$CustomerItemImplCopyWithImpl<$Res>
    extends _$CustomerItemCopyWithImpl<$Res, _$CustomerItemImpl>
    implements _$$CustomerItemImplCopyWith<$Res> {
  __$$CustomerItemImplCopyWithImpl(
    _$CustomerItemImpl _value,
    $Res Function(_$CustomerItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? whatsappId = freezed,
    Object? avatarUrl = freezed,
    Object? status = null,
    Object? isActiveCustomer = null,
    Object? totalPurchasesCount = null,
    Object? totalSpent = null,
    Object? lastPurchaseAt = freezed,
    Object? lastChatAt = freezed,
    Object? lastMessagePreview = freezed,
    Object? assignedProduct = freezed,
    Object? tags = null,
    Object? important = null,
    Object? internalNote = freezed,
  }) {
    return _then(
      _$CustomerItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        whatsappId: freezed == whatsappId
            ? _value.whatsappId
            : whatsappId // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isActiveCustomer: null == isActiveCustomer
            ? _value.isActiveCustomer
            : isActiveCustomer // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalPurchasesCount: null == totalPurchasesCount
            ? _value.totalPurchasesCount
            : totalPurchasesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpent: null == totalSpent
            ? _value.totalSpent
            : totalSpent // ignore: cast_nullable_to_non_nullable
                  as double,
        lastPurchaseAt: freezed == lastPurchaseAt
            ? _value.lastPurchaseAt
            : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastChatAt: freezed == lastChatAt
            ? _value.lastChatAt
            : lastChatAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessagePreview: freezed == lastMessagePreview
            ? _value.lastMessagePreview
            : lastMessagePreview // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedProduct: freezed == assignedProduct
            ? _value.assignedProduct
            : assignedProduct // ignore: cast_nullable_to_non_nullable
                  as LastProduct?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        important: null == important
            ? _value.important
            : important // ignore: cast_nullable_to_non_nullable
                  as bool,
        internalNote: freezed == internalNote
            ? _value.internalNote
            : internalNote // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerItemImpl implements _CustomerItem {
  const _$CustomerItemImpl({
    required this.id,
    required this.fullName,
    required this.phone,
    this.whatsappId,
    this.avatarUrl,
    required this.status,
    required this.isActiveCustomer,
    required this.totalPurchasesCount,
    required this.totalSpent,
    this.lastPurchaseAt,
    this.lastChatAt,
    this.lastMessagePreview,
    this.assignedProduct,
    required final List<String> tags,
    required this.important,
    this.internalNote,
  }) : _tags = tags;

  factory _$CustomerItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerItemImplFromJson(json);

  @override
  final String id;
  @override
  final String fullName;
  @override
  final String phone;
  @override
  final String? whatsappId;
  @override
  final String? avatarUrl;
  @override
  final String status;
  @override
  final bool isActiveCustomer;
  @override
  final int totalPurchasesCount;
  @override
  final double totalSpent;
  @override
  final String? lastPurchaseAt;
  @override
  final String? lastChatAt;
  @override
  final String? lastMessagePreview;
  @override
  final LastProduct? assignedProduct;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final bool important;
  @override
  final String? internalNote;

  @override
  String toString() {
    return 'CustomerItem(id: $id, fullName: $fullName, phone: $phone, whatsappId: $whatsappId, avatarUrl: $avatarUrl, status: $status, isActiveCustomer: $isActiveCustomer, totalPurchasesCount: $totalPurchasesCount, totalSpent: $totalSpent, lastPurchaseAt: $lastPurchaseAt, lastChatAt: $lastChatAt, lastMessagePreview: $lastMessagePreview, assignedProduct: $assignedProduct, tags: $tags, important: $important, internalNote: $internalNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.whatsappId, whatsappId) ||
                other.whatsappId == whatsappId) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isActiveCustomer, isActiveCustomer) ||
                other.isActiveCustomer == isActiveCustomer) &&
            (identical(other.totalPurchasesCount, totalPurchasesCount) ||
                other.totalPurchasesCount == totalPurchasesCount) &&
            (identical(other.totalSpent, totalSpent) ||
                other.totalSpent == totalSpent) &&
            (identical(other.lastPurchaseAt, lastPurchaseAt) ||
                other.lastPurchaseAt == lastPurchaseAt) &&
            (identical(other.lastChatAt, lastChatAt) ||
                other.lastChatAt == lastChatAt) &&
            (identical(other.lastMessagePreview, lastMessagePreview) ||
                other.lastMessagePreview == lastMessagePreview) &&
            (identical(other.assignedProduct, assignedProduct) ||
                other.assignedProduct == assignedProduct) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.important, important) ||
                other.important == important) &&
            (identical(other.internalNote, internalNote) ||
                other.internalNote == internalNote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fullName,
    phone,
    whatsappId,
    avatarUrl,
    status,
    isActiveCustomer,
    totalPurchasesCount,
    totalSpent,
    lastPurchaseAt,
    lastChatAt,
    lastMessagePreview,
    assignedProduct,
    const DeepCollectionEquality().hash(_tags),
    important,
    internalNote,
  );

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerItemImplCopyWith<_$CustomerItemImpl> get copyWith =>
      __$$CustomerItemImplCopyWithImpl<_$CustomerItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerItemImplToJson(this);
  }
}

abstract class _CustomerItem implements CustomerItem {
  const factory _CustomerItem({
    required final String id,
    required final String fullName,
    required final String phone,
    final String? whatsappId,
    final String? avatarUrl,
    required final String status,
    required final bool isActiveCustomer,
    required final int totalPurchasesCount,
    required final double totalSpent,
    final String? lastPurchaseAt,
    final String? lastChatAt,
    final String? lastMessagePreview,
    final LastProduct? assignedProduct,
    required final List<String> tags,
    required final bool important,
    final String? internalNote,
  }) = _$CustomerItemImpl;

  factory _CustomerItem.fromJson(Map<String, dynamic> json) =
      _$CustomerItemImpl.fromJson;

  @override
  String get id;
  @override
  String get fullName;
  @override
  String get phone;
  @override
  String? get whatsappId;
  @override
  String? get avatarUrl;
  @override
  String get status;
  @override
  bool get isActiveCustomer;
  @override
  int get totalPurchasesCount;
  @override
  double get totalSpent;
  @override
  String? get lastPurchaseAt;
  @override
  String? get lastChatAt;
  @override
  String? get lastMessagePreview;
  @override
  LastProduct? get assignedProduct;
  @override
  List<String> get tags;
  @override
  bool get important;
  @override
  String? get internalNote;

  /// Create a copy of CustomerItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerItemImplCopyWith<_$CustomerItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LastProduct _$LastProductFromJson(Map<String, dynamic> json) {
  return _LastProduct.fromJson(json);
}

/// @nodoc
mixin _$LastProduct {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this LastProduct to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LastProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LastProductCopyWith<LastProduct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LastProductCopyWith<$Res> {
  factory $LastProductCopyWith(
    LastProduct value,
    $Res Function(LastProduct) then,
  ) = _$LastProductCopyWithImpl<$Res, LastProduct>;
  @useResult
  $Res call({String id, String name, double price, String? imageUrl});
}

/// @nodoc
class _$LastProductCopyWithImpl<$Res, $Val extends LastProduct>
    implements $LastProductCopyWith<$Res> {
  _$LastProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LastProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LastProductImplCopyWith<$Res>
    implements $LastProductCopyWith<$Res> {
  factory _$$LastProductImplCopyWith(
    _$LastProductImpl value,
    $Res Function(_$LastProductImpl) then,
  ) = __$$LastProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, double price, String? imageUrl});
}

/// @nodoc
class __$$LastProductImplCopyWithImpl<$Res>
    extends _$LastProductCopyWithImpl<$Res, _$LastProductImpl>
    implements _$$LastProductImplCopyWith<$Res> {
  __$$LastProductImplCopyWithImpl(
    _$LastProductImpl _value,
    $Res Function(_$LastProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LastProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _$LastProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LastProductImpl implements _LastProduct {
  const _$LastProductImpl({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory _$LastProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$LastProductImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double price;
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'LastProduct(id: $id, name: $name, price: $price, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LastProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, price, imageUrl);

  /// Create a copy of LastProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LastProductImplCopyWith<_$LastProductImpl> get copyWith =>
      __$$LastProductImplCopyWithImpl<_$LastProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LastProductImplToJson(this);
  }
}

abstract class _LastProduct implements LastProduct {
  const factory _LastProduct({
    required final String id,
    required final String name,
    required final double price,
    final String? imageUrl,
  }) = _$LastProductImpl;

  factory _LastProduct.fromJson(Map<String, dynamic> json) =
      _$LastProductImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get price;
  @override
  String? get imageUrl;

  /// Create a copy of LastProduct
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LastProductImplCopyWith<_$LastProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerStats _$CustomerStatsFromJson(Map<String, dynamic> json) {
  return _CustomerStats.fromJson(json);
}

/// @nodoc
mixin _$CustomerStats {
  int get totalCustomers => throw _privateConstructorUsedError;
  int get activeCustomers => throw _privateConstructorUsedError;
  Map<String, int> get byStatus => throw _privateConstructorUsedError;

  /// Serializes this CustomerStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerStatsCopyWith<CustomerStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerStatsCopyWith<$Res> {
  factory $CustomerStatsCopyWith(
    CustomerStats value,
    $Res Function(CustomerStats) then,
  ) = _$CustomerStatsCopyWithImpl<$Res, CustomerStats>;
  @useResult
  $Res call({
    int totalCustomers,
    int activeCustomers,
    Map<String, int> byStatus,
  });
}

/// @nodoc
class _$CustomerStatsCopyWithImpl<$Res, $Val extends CustomerStats>
    implements $CustomerStatsCopyWith<$Res> {
  _$CustomerStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCustomers = null,
    Object? activeCustomers = null,
    Object? byStatus = null,
  }) {
    return _then(
      _value.copyWith(
            totalCustomers: null == totalCustomers
                ? _value.totalCustomers
                : totalCustomers // ignore: cast_nullable_to_non_nullable
                      as int,
            activeCustomers: null == activeCustomers
                ? _value.activeCustomers
                : activeCustomers // ignore: cast_nullable_to_non_nullable
                      as int,
            byStatus: null == byStatus
                ? _value.byStatus
                : byStatus // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerStatsImplCopyWith<$Res>
    implements $CustomerStatsCopyWith<$Res> {
  factory _$$CustomerStatsImplCopyWith(
    _$CustomerStatsImpl value,
    $Res Function(_$CustomerStatsImpl) then,
  ) = __$$CustomerStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalCustomers,
    int activeCustomers,
    Map<String, int> byStatus,
  });
}

/// @nodoc
class __$$CustomerStatsImplCopyWithImpl<$Res>
    extends _$CustomerStatsCopyWithImpl<$Res, _$CustomerStatsImpl>
    implements _$$CustomerStatsImplCopyWith<$Res> {
  __$$CustomerStatsImplCopyWithImpl(
    _$CustomerStatsImpl _value,
    $Res Function(_$CustomerStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCustomers = null,
    Object? activeCustomers = null,
    Object? byStatus = null,
  }) {
    return _then(
      _$CustomerStatsImpl(
        totalCustomers: null == totalCustomers
            ? _value.totalCustomers
            : totalCustomers // ignore: cast_nullable_to_non_nullable
                  as int,
        activeCustomers: null == activeCustomers
            ? _value.activeCustomers
            : activeCustomers // ignore: cast_nullable_to_non_nullable
                  as int,
        byStatus: null == byStatus
            ? _value._byStatus
            : byStatus // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerStatsImpl implements _CustomerStats {
  const _$CustomerStatsImpl({
    required this.totalCustomers,
    required this.activeCustomers,
    required final Map<String, int> byStatus,
  }) : _byStatus = byStatus;

  factory _$CustomerStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerStatsImplFromJson(json);

  @override
  final int totalCustomers;
  @override
  final int activeCustomers;
  final Map<String, int> _byStatus;
  @override
  Map<String, int> get byStatus {
    if (_byStatus is EqualUnmodifiableMapView) return _byStatus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byStatus);
  }

  @override
  String toString() {
    return 'CustomerStats(totalCustomers: $totalCustomers, activeCustomers: $activeCustomers, byStatus: $byStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerStatsImpl &&
            (identical(other.totalCustomers, totalCustomers) ||
                other.totalCustomers == totalCustomers) &&
            (identical(other.activeCustomers, activeCustomers) ||
                other.activeCustomers == activeCustomers) &&
            const DeepCollectionEquality().equals(other._byStatus, _byStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalCustomers,
    activeCustomers,
    const DeepCollectionEquality().hash(_byStatus),
  );

  /// Create a copy of CustomerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerStatsImplCopyWith<_$CustomerStatsImpl> get copyWith =>
      __$$CustomerStatsImplCopyWithImpl<_$CustomerStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerStatsImplToJson(this);
  }
}

abstract class _CustomerStats implements CustomerStats {
  const factory _CustomerStats({
    required final int totalCustomers,
    required final int activeCustomers,
    required final Map<String, int> byStatus,
  }) = _$CustomerStatsImpl;

  factory _CustomerStats.fromJson(Map<String, dynamic> json) =
      _$CustomerStatsImpl.fromJson;

  @override
  int get totalCustomers;
  @override
  int get activeCustomers;
  @override
  Map<String, int> get byStatus;

  /// Create a copy of CustomerStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerStatsImplCopyWith<_$CustomerStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerDetailResponse _$CustomerDetailResponseFromJson(
  Map<String, dynamic> json,
) {
  return _CustomerDetailResponse.fromJson(json);
}

/// @nodoc
mixin _$CustomerDetailResponse {
  CustomerDetail get customer => throw _privateConstructorUsedError;
  List<CustomerPurchase> get purchases => throw _privateConstructorUsedError;
  CustomerDetailStats get stats => throw _privateConstructorUsedError;
  List<CustomerChatItem> get chats => throw _privateConstructorUsedError;

  /// Serializes this CustomerDetailResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerDetailResponseCopyWith<CustomerDetailResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerDetailResponseCopyWith<$Res> {
  factory $CustomerDetailResponseCopyWith(
    CustomerDetailResponse value,
    $Res Function(CustomerDetailResponse) then,
  ) = _$CustomerDetailResponseCopyWithImpl<$Res, CustomerDetailResponse>;
  @useResult
  $Res call({
    CustomerDetail customer,
    List<CustomerPurchase> purchases,
    CustomerDetailStats stats,
    List<CustomerChatItem> chats,
  });

  $CustomerDetailCopyWith<$Res> get customer;
  $CustomerDetailStatsCopyWith<$Res> get stats;
}

/// @nodoc
class _$CustomerDetailResponseCopyWithImpl<
  $Res,
  $Val extends CustomerDetailResponse
>
    implements $CustomerDetailResponseCopyWith<$Res> {
  _$CustomerDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customer = null,
    Object? purchases = null,
    Object? stats = null,
    Object? chats = null,
  }) {
    return _then(
      _value.copyWith(
            customer: null == customer
                ? _value.customer
                : customer // ignore: cast_nullable_to_non_nullable
                      as CustomerDetail,
            purchases: null == purchases
                ? _value.purchases
                : purchases // ignore: cast_nullable_to_non_nullable
                      as List<CustomerPurchase>,
            stats: null == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as CustomerDetailStats,
            chats: null == chats
                ? _value.chats
                : chats // ignore: cast_nullable_to_non_nullable
                      as List<CustomerChatItem>,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomerDetailCopyWith<$Res> get customer {
    return $CustomerDetailCopyWith<$Res>(_value.customer, (value) {
      return _then(_value.copyWith(customer: value) as $Val);
    });
  }

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomerDetailStatsCopyWith<$Res> get stats {
    return $CustomerDetailStatsCopyWith<$Res>(_value.stats, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerDetailResponseImplCopyWith<$Res>
    implements $CustomerDetailResponseCopyWith<$Res> {
  factory _$$CustomerDetailResponseImplCopyWith(
    _$CustomerDetailResponseImpl value,
    $Res Function(_$CustomerDetailResponseImpl) then,
  ) = __$$CustomerDetailResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CustomerDetail customer,
    List<CustomerPurchase> purchases,
    CustomerDetailStats stats,
    List<CustomerChatItem> chats,
  });

  @override
  $CustomerDetailCopyWith<$Res> get customer;
  @override
  $CustomerDetailStatsCopyWith<$Res> get stats;
}

/// @nodoc
class __$$CustomerDetailResponseImplCopyWithImpl<$Res>
    extends
        _$CustomerDetailResponseCopyWithImpl<$Res, _$CustomerDetailResponseImpl>
    implements _$$CustomerDetailResponseImplCopyWith<$Res> {
  __$$CustomerDetailResponseImplCopyWithImpl(
    _$CustomerDetailResponseImpl _value,
    $Res Function(_$CustomerDetailResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customer = null,
    Object? purchases = null,
    Object? stats = null,
    Object? chats = null,
  }) {
    return _then(
      _$CustomerDetailResponseImpl(
        customer: null == customer
            ? _value.customer
            : customer // ignore: cast_nullable_to_non_nullable
                  as CustomerDetail,
        purchases: null == purchases
            ? _value._purchases
            : purchases // ignore: cast_nullable_to_non_nullable
                  as List<CustomerPurchase>,
        stats: null == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as CustomerDetailStats,
        chats: null == chats
            ? _value._chats
            : chats // ignore: cast_nullable_to_non_nullable
                  as List<CustomerChatItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerDetailResponseImpl implements _CustomerDetailResponse {
  const _$CustomerDetailResponseImpl({
    required this.customer,
    required final List<CustomerPurchase> purchases,
    required this.stats,
    required final List<CustomerChatItem> chats,
  }) : _purchases = purchases,
       _chats = chats;

  factory _$CustomerDetailResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerDetailResponseImplFromJson(json);

  @override
  final CustomerDetail customer;
  final List<CustomerPurchase> _purchases;
  @override
  List<CustomerPurchase> get purchases {
    if (_purchases is EqualUnmodifiableListView) return _purchases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_purchases);
  }

  @override
  final CustomerDetailStats stats;
  final List<CustomerChatItem> _chats;
  @override
  List<CustomerChatItem> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @override
  String toString() {
    return 'CustomerDetailResponse(customer: $customer, purchases: $purchases, stats: $stats, chats: $chats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerDetailResponseImpl &&
            (identical(other.customer, customer) ||
                other.customer == customer) &&
            const DeepCollectionEquality().equals(
              other._purchases,
              _purchases,
            ) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            const DeepCollectionEquality().equals(other._chats, _chats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    customer,
    const DeepCollectionEquality().hash(_purchases),
    stats,
    const DeepCollectionEquality().hash(_chats),
  );

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerDetailResponseImplCopyWith<_$CustomerDetailResponseImpl>
  get copyWith =>
      __$$CustomerDetailResponseImplCopyWithImpl<_$CustomerDetailResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerDetailResponseImplToJson(this);
  }
}

abstract class _CustomerDetailResponse implements CustomerDetailResponse {
  const factory _CustomerDetailResponse({
    required final CustomerDetail customer,
    required final List<CustomerPurchase> purchases,
    required final CustomerDetailStats stats,
    required final List<CustomerChatItem> chats,
  }) = _$CustomerDetailResponseImpl;

  factory _CustomerDetailResponse.fromJson(Map<String, dynamic> json) =
      _$CustomerDetailResponseImpl.fromJson;

  @override
  CustomerDetail get customer;
  @override
  List<CustomerPurchase> get purchases;
  @override
  CustomerDetailStats get stats;
  @override
  List<CustomerChatItem> get chats;

  /// Create a copy of CustomerDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerDetailResponseImplCopyWith<_$CustomerDetailResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CustomerDetail _$CustomerDetailFromJson(Map<String, dynamic> json) {
  return _CustomerDetail.fromJson(json);
}

/// @nodoc
mixin _$CustomerDetail {
  String get id => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get whatsappId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get internalNote => throw _privateConstructorUsedError;
  bool get important => throw _privateConstructorUsedError;
  LastProduct? get assignedProduct => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CustomerDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerDetailCopyWith<CustomerDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerDetailCopyWith<$Res> {
  factory $CustomerDetailCopyWith(
    CustomerDetail value,
    $Res Function(CustomerDetail) then,
  ) = _$CustomerDetailCopyWithImpl<$Res, CustomerDetail>;
  @useResult
  $Res call({
    String id,
    String fullName,
    String phone,
    String? whatsappId,
    String status,
    String? email,
    String? address,
    List<String> tags,
    String? internalNote,
    bool important,
    LastProduct? assignedProduct,
    String createdAt,
    String updatedAt,
  });

  $LastProductCopyWith<$Res>? get assignedProduct;
}

/// @nodoc
class _$CustomerDetailCopyWithImpl<$Res, $Val extends CustomerDetail>
    implements $CustomerDetailCopyWith<$Res> {
  _$CustomerDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? whatsappId = freezed,
    Object? status = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? tags = null,
    Object? internalNote = freezed,
    Object? important = null,
    Object? assignedProduct = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            whatsappId: freezed == whatsappId
                ? _value.whatsappId
                : whatsappId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            internalNote: freezed == internalNote
                ? _value.internalNote
                : internalNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            important: null == important
                ? _value.important
                : important // ignore: cast_nullable_to_non_nullable
                      as bool,
            assignedProduct: freezed == assignedProduct
                ? _value.assignedProduct
                : assignedProduct // ignore: cast_nullable_to_non_nullable
                      as LastProduct?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LastProductCopyWith<$Res>? get assignedProduct {
    if (_value.assignedProduct == null) {
      return null;
    }

    return $LastProductCopyWith<$Res>(_value.assignedProduct!, (value) {
      return _then(_value.copyWith(assignedProduct: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerDetailImplCopyWith<$Res>
    implements $CustomerDetailCopyWith<$Res> {
  factory _$$CustomerDetailImplCopyWith(
    _$CustomerDetailImpl value,
    $Res Function(_$CustomerDetailImpl) then,
  ) = __$$CustomerDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fullName,
    String phone,
    String? whatsappId,
    String status,
    String? email,
    String? address,
    List<String> tags,
    String? internalNote,
    bool important,
    LastProduct? assignedProduct,
    String createdAt,
    String updatedAt,
  });

  @override
  $LastProductCopyWith<$Res>? get assignedProduct;
}

/// @nodoc
class __$$CustomerDetailImplCopyWithImpl<$Res>
    extends _$CustomerDetailCopyWithImpl<$Res, _$CustomerDetailImpl>
    implements _$$CustomerDetailImplCopyWith<$Res> {
  __$$CustomerDetailImplCopyWithImpl(
    _$CustomerDetailImpl _value,
    $Res Function(_$CustomerDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? phone = null,
    Object? whatsappId = freezed,
    Object? status = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? tags = null,
    Object? internalNote = freezed,
    Object? important = null,
    Object? assignedProduct = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$CustomerDetailImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        whatsappId: freezed == whatsappId
            ? _value.whatsappId
            : whatsappId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        internalNote: freezed == internalNote
            ? _value.internalNote
            : internalNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        important: null == important
            ? _value.important
            : important // ignore: cast_nullable_to_non_nullable
                  as bool,
        assignedProduct: freezed == assignedProduct
            ? _value.assignedProduct
            : assignedProduct // ignore: cast_nullable_to_non_nullable
                  as LastProduct?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerDetailImpl implements _CustomerDetail {
  const _$CustomerDetailImpl({
    required this.id,
    required this.fullName,
    required this.phone,
    this.whatsappId,
    required this.status,
    this.email,
    this.address,
    required final List<String> tags,
    this.internalNote,
    required this.important,
    this.assignedProduct,
    required this.createdAt,
    required this.updatedAt,
  }) : _tags = tags;

  factory _$CustomerDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String fullName;
  @override
  final String phone;
  @override
  final String? whatsappId;
  @override
  final String status;
  @override
  final String? email;
  @override
  final String? address;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? internalNote;
  @override
  final bool important;
  @override
  final LastProduct? assignedProduct;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'CustomerDetail(id: $id, fullName: $fullName, phone: $phone, whatsappId: $whatsappId, status: $status, email: $email, address: $address, tags: $tags, internalNote: $internalNote, important: $important, assignedProduct: $assignedProduct, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.whatsappId, whatsappId) ||
                other.whatsappId == whatsappId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.internalNote, internalNote) ||
                other.internalNote == internalNote) &&
            (identical(other.important, important) ||
                other.important == important) &&
            (identical(other.assignedProduct, assignedProduct) ||
                other.assignedProduct == assignedProduct) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fullName,
    phone,
    whatsappId,
    status,
    email,
    address,
    const DeepCollectionEquality().hash(_tags),
    internalNote,
    important,
    assignedProduct,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerDetailImplCopyWith<_$CustomerDetailImpl> get copyWith =>
      __$$CustomerDetailImplCopyWithImpl<_$CustomerDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerDetailImplToJson(this);
  }
}

abstract class _CustomerDetail implements CustomerDetail {
  const factory _CustomerDetail({
    required final String id,
    required final String fullName,
    required final String phone,
    final String? whatsappId,
    required final String status,
    final String? email,
    final String? address,
    required final List<String> tags,
    final String? internalNote,
    required final bool important,
    final LastProduct? assignedProduct,
    required final String createdAt,
    required final String updatedAt,
  }) = _$CustomerDetailImpl;

  factory _CustomerDetail.fromJson(Map<String, dynamic> json) =
      _$CustomerDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get fullName;
  @override
  String get phone;
  @override
  String? get whatsappId;
  @override
  String get status;
  @override
  String? get email;
  @override
  String? get address;
  @override
  List<String> get tags;
  @override
  String? get internalNote;
  @override
  bool get important;
  @override
  LastProduct? get assignedProduct;
  @override
  String get createdAt;
  @override
  String get updatedAt;

  /// Create a copy of CustomerDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerDetailImplCopyWith<_$CustomerDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerDetailStats _$CustomerDetailStatsFromJson(Map<String, dynamic> json) {
  return _CustomerDetailStats.fromJson(json);
}

/// @nodoc
mixin _$CustomerDetailStats {
  int get totalPurchases => throw _privateConstructorUsedError;
  double get totalSpent => throw _privateConstructorUsedError;
  String? get lastPurchaseAt => throw _privateConstructorUsedError;

  /// Serializes this CustomerDetailStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerDetailStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerDetailStatsCopyWith<CustomerDetailStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerDetailStatsCopyWith<$Res> {
  factory $CustomerDetailStatsCopyWith(
    CustomerDetailStats value,
    $Res Function(CustomerDetailStats) then,
  ) = _$CustomerDetailStatsCopyWithImpl<$Res, CustomerDetailStats>;
  @useResult
  $Res call({int totalPurchases, double totalSpent, String? lastPurchaseAt});
}

/// @nodoc
class _$CustomerDetailStatsCopyWithImpl<$Res, $Val extends CustomerDetailStats>
    implements $CustomerDetailStatsCopyWith<$Res> {
  _$CustomerDetailStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerDetailStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPurchases = null,
    Object? totalSpent = null,
    Object? lastPurchaseAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalPurchases: null == totalPurchases
                ? _value.totalPurchases
                : totalPurchases // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSpent: null == totalSpent
                ? _value.totalSpent
                : totalSpent // ignore: cast_nullable_to_non_nullable
                      as double,
            lastPurchaseAt: freezed == lastPurchaseAt
                ? _value.lastPurchaseAt
                : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerDetailStatsImplCopyWith<$Res>
    implements $CustomerDetailStatsCopyWith<$Res> {
  factory _$$CustomerDetailStatsImplCopyWith(
    _$CustomerDetailStatsImpl value,
    $Res Function(_$CustomerDetailStatsImpl) then,
  ) = __$$CustomerDetailStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int totalPurchases, double totalSpent, String? lastPurchaseAt});
}

/// @nodoc
class __$$CustomerDetailStatsImplCopyWithImpl<$Res>
    extends _$CustomerDetailStatsCopyWithImpl<$Res, _$CustomerDetailStatsImpl>
    implements _$$CustomerDetailStatsImplCopyWith<$Res> {
  __$$CustomerDetailStatsImplCopyWithImpl(
    _$CustomerDetailStatsImpl _value,
    $Res Function(_$CustomerDetailStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerDetailStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalPurchases = null,
    Object? totalSpent = null,
    Object? lastPurchaseAt = freezed,
  }) {
    return _then(
      _$CustomerDetailStatsImpl(
        totalPurchases: null == totalPurchases
            ? _value.totalPurchases
            : totalPurchases // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpent: null == totalSpent
            ? _value.totalSpent
            : totalSpent // ignore: cast_nullable_to_non_nullable
                  as double,
        lastPurchaseAt: freezed == lastPurchaseAt
            ? _value.lastPurchaseAt
            : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerDetailStatsImpl implements _CustomerDetailStats {
  const _$CustomerDetailStatsImpl({
    required this.totalPurchases,
    required this.totalSpent,
    this.lastPurchaseAt,
  });

  factory _$CustomerDetailStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerDetailStatsImplFromJson(json);

  @override
  final int totalPurchases;
  @override
  final double totalSpent;
  @override
  final String? lastPurchaseAt;

  @override
  String toString() {
    return 'CustomerDetailStats(totalPurchases: $totalPurchases, totalSpent: $totalSpent, lastPurchaseAt: $lastPurchaseAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerDetailStatsImpl &&
            (identical(other.totalPurchases, totalPurchases) ||
                other.totalPurchases == totalPurchases) &&
            (identical(other.totalSpent, totalSpent) ||
                other.totalSpent == totalSpent) &&
            (identical(other.lastPurchaseAt, lastPurchaseAt) ||
                other.lastPurchaseAt == lastPurchaseAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalPurchases, totalSpent, lastPurchaseAt);

  /// Create a copy of CustomerDetailStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerDetailStatsImplCopyWith<_$CustomerDetailStatsImpl> get copyWith =>
      __$$CustomerDetailStatsImplCopyWithImpl<_$CustomerDetailStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerDetailStatsImplToJson(this);
  }
}

abstract class _CustomerDetailStats implements CustomerDetailStats {
  const factory _CustomerDetailStats({
    required final int totalPurchases,
    required final double totalSpent,
    final String? lastPurchaseAt,
  }) = _$CustomerDetailStatsImpl;

  factory _CustomerDetailStats.fromJson(Map<String, dynamic> json) =
      _$CustomerDetailStatsImpl.fromJson;

  @override
  int get totalPurchases;
  @override
  double get totalSpent;
  @override
  String? get lastPurchaseAt;

  /// Create a copy of CustomerDetailStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerDetailStatsImplCopyWith<_$CustomerDetailStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerPurchase _$CustomerPurchaseFromJson(Map<String, dynamic> json) {
  return _CustomerPurchase.fromJson(json);
}

/// @nodoc
mixin _$CustomerPurchase {
  String get id => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  PurchaseProduct? get product => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;

  /// Serializes this CustomerPurchase to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerPurchaseCopyWith<CustomerPurchase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerPurchaseCopyWith<$Res> {
  factory $CustomerPurchaseCopyWith(
    CustomerPurchase value,
    $Res Function(CustomerPurchase) then,
  ) = _$CustomerPurchaseCopyWithImpl<$Res, CustomerPurchase>;
  @useResult
  $Res call({
    String id,
    String date,
    PurchaseProduct? product,
    int quantity,
    double total,
    String? paymentMethod,
  });

  $PurchaseProductCopyWith<$Res>? get product;
}

/// @nodoc
class _$CustomerPurchaseCopyWithImpl<$Res, $Val extends CustomerPurchase>
    implements $CustomerPurchaseCopyWith<$Res> {
  _$CustomerPurchaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? product = freezed,
    Object? quantity = null,
    Object? total = null,
    Object? paymentMethod = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            product: freezed == product
                ? _value.product
                : product // ignore: cast_nullable_to_non_nullable
                      as PurchaseProduct?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PurchaseProductCopyWith<$Res>? get product {
    if (_value.product == null) {
      return null;
    }

    return $PurchaseProductCopyWith<$Res>(_value.product!, (value) {
      return _then(_value.copyWith(product: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerPurchaseImplCopyWith<$Res>
    implements $CustomerPurchaseCopyWith<$Res> {
  factory _$$CustomerPurchaseImplCopyWith(
    _$CustomerPurchaseImpl value,
    $Res Function(_$CustomerPurchaseImpl) then,
  ) = __$$CustomerPurchaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String date,
    PurchaseProduct? product,
    int quantity,
    double total,
    String? paymentMethod,
  });

  @override
  $PurchaseProductCopyWith<$Res>? get product;
}

/// @nodoc
class __$$CustomerPurchaseImplCopyWithImpl<$Res>
    extends _$CustomerPurchaseCopyWithImpl<$Res, _$CustomerPurchaseImpl>
    implements _$$CustomerPurchaseImplCopyWith<$Res> {
  __$$CustomerPurchaseImplCopyWithImpl(
    _$CustomerPurchaseImpl _value,
    $Res Function(_$CustomerPurchaseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? product = freezed,
    Object? quantity = null,
    Object? total = null,
    Object? paymentMethod = freezed,
  }) {
    return _then(
      _$CustomerPurchaseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        product: freezed == product
            ? _value.product
            : product // ignore: cast_nullable_to_non_nullable
                  as PurchaseProduct?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerPurchaseImpl implements _CustomerPurchase {
  const _$CustomerPurchaseImpl({
    required this.id,
    required this.date,
    this.product,
    required this.quantity,
    required this.total,
    this.paymentMethod,
  });

  factory _$CustomerPurchaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerPurchaseImplFromJson(json);

  @override
  final String id;
  @override
  final String date;
  @override
  final PurchaseProduct? product;
  @override
  final int quantity;
  @override
  final double total;
  @override
  final String? paymentMethod;

  @override
  String toString() {
    return 'CustomerPurchase(id: $id, date: $date, product: $product, quantity: $quantity, total: $total, paymentMethod: $paymentMethod)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerPurchaseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.product, product) || other.product == product) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    product,
    quantity,
    total,
    paymentMethod,
  );

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerPurchaseImplCopyWith<_$CustomerPurchaseImpl> get copyWith =>
      __$$CustomerPurchaseImplCopyWithImpl<_$CustomerPurchaseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerPurchaseImplToJson(this);
  }
}

abstract class _CustomerPurchase implements CustomerPurchase {
  const factory _CustomerPurchase({
    required final String id,
    required final String date,
    final PurchaseProduct? product,
    required final int quantity,
    required final double total,
    final String? paymentMethod,
  }) = _$CustomerPurchaseImpl;

  factory _CustomerPurchase.fromJson(Map<String, dynamic> json) =
      _$CustomerPurchaseImpl.fromJson;

  @override
  String get id;
  @override
  String get date;
  @override
  PurchaseProduct? get product;
  @override
  int get quantity;
  @override
  double get total;
  @override
  String? get paymentMethod;

  /// Create a copy of CustomerPurchase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerPurchaseImplCopyWith<_$CustomerPurchaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseProduct _$PurchaseProductFromJson(Map<String, dynamic> json) {
  return _PurchaseProduct.fromJson(json);
}

/// @nodoc
mixin _$PurchaseProduct {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this PurchaseProduct to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseProductCopyWith<PurchaseProduct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseProductCopyWith<$Res> {
  factory $PurchaseProductCopyWith(
    PurchaseProduct value,
    $Res Function(PurchaseProduct) then,
  ) = _$PurchaseProductCopyWithImpl<$Res, PurchaseProduct>;
  @useResult
  $Res call({String id, String name, String? imageUrl});
}

/// @nodoc
class _$PurchaseProductCopyWithImpl<$Res, $Val extends PurchaseProduct>
    implements $PurchaseProductCopyWith<$Res> {
  _$PurchaseProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PurchaseProductImplCopyWith<$Res>
    implements $PurchaseProductCopyWith<$Res> {
  factory _$$PurchaseProductImplCopyWith(
    _$PurchaseProductImpl value,
    $Res Function(_$PurchaseProductImpl) then,
  ) = __$$PurchaseProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? imageUrl});
}

/// @nodoc
class __$$PurchaseProductImplCopyWithImpl<$Res>
    extends _$PurchaseProductCopyWithImpl<$Res, _$PurchaseProductImpl>
    implements _$$PurchaseProductImplCopyWith<$Res> {
  __$$PurchaseProductImplCopyWithImpl(
    _$PurchaseProductImpl _value,
    $Res Function(_$PurchaseProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _$PurchaseProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseProductImpl implements _PurchaseProduct {
  const _$PurchaseProductImpl({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory _$PurchaseProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseProductImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'PurchaseProduct(id: $id, name: $name, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, imageUrl);

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseProductImplCopyWith<_$PurchaseProductImpl> get copyWith =>
      __$$PurchaseProductImplCopyWithImpl<_$PurchaseProductImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseProductImplToJson(this);
  }
}

abstract class _PurchaseProduct implements PurchaseProduct {
  const factory _PurchaseProduct({
    required final String id,
    required final String name,
    final String? imageUrl,
  }) = _$PurchaseProductImpl;

  factory _PurchaseProduct.fromJson(Map<String, dynamic> json) =
      _$PurchaseProductImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get imageUrl;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseProductImplCopyWith<_$PurchaseProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerChatItem _$CustomerChatItemFromJson(Map<String, dynamic> json) {
  return _CustomerChatItem.fromJson(json);
}

/// @nodoc
mixin _$CustomerChatItem {
  String get chatId => throw _privateConstructorUsedError;
  String get whatsappId => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get lastMessagePreview => throw _privateConstructorUsedError;
  String? get lastMessageAt => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  /// Serializes this CustomerChatItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerChatItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerChatItemCopyWith<CustomerChatItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerChatItemCopyWith<$Res> {
  factory $CustomerChatItemCopyWith(
    CustomerChatItem value,
    $Res Function(CustomerChatItem) then,
  ) = _$CustomerChatItemCopyWithImpl<$Res, CustomerChatItem>;
  @useResult
  $Res call({
    String chatId,
    String whatsappId,
    String? displayName,
    String? lastMessagePreview,
    String? lastMessageAt,
    int unreadCount,
  });
}

/// @nodoc
class _$CustomerChatItemCopyWithImpl<$Res, $Val extends CustomerChatItem>
    implements $CustomerChatItemCopyWith<$Res> {
  _$CustomerChatItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerChatItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? whatsappId = null,
    Object? displayName = freezed,
    Object? lastMessagePreview = freezed,
    Object? lastMessageAt = freezed,
    Object? unreadCount = null,
  }) {
    return _then(
      _value.copyWith(
            chatId: null == chatId
                ? _value.chatId
                : chatId // ignore: cast_nullable_to_non_nullable
                      as String,
            whatsappId: null == whatsappId
                ? _value.whatsappId
                : whatsappId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessagePreview: freezed == lastMessagePreview
                ? _value.lastMessagePreview
                : lastMessagePreview // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessageAt: freezed == lastMessageAt
                ? _value.lastMessageAt
                : lastMessageAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            unreadCount: null == unreadCount
                ? _value.unreadCount
                : unreadCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerChatItemImplCopyWith<$Res>
    implements $CustomerChatItemCopyWith<$Res> {
  factory _$$CustomerChatItemImplCopyWith(
    _$CustomerChatItemImpl value,
    $Res Function(_$CustomerChatItemImpl) then,
  ) = __$$CustomerChatItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String chatId,
    String whatsappId,
    String? displayName,
    String? lastMessagePreview,
    String? lastMessageAt,
    int unreadCount,
  });
}

/// @nodoc
class __$$CustomerChatItemImplCopyWithImpl<$Res>
    extends _$CustomerChatItemCopyWithImpl<$Res, _$CustomerChatItemImpl>
    implements _$$CustomerChatItemImplCopyWith<$Res> {
  __$$CustomerChatItemImplCopyWithImpl(
    _$CustomerChatItemImpl _value,
    $Res Function(_$CustomerChatItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerChatItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? whatsappId = null,
    Object? displayName = freezed,
    Object? lastMessagePreview = freezed,
    Object? lastMessageAt = freezed,
    Object? unreadCount = null,
  }) {
    return _then(
      _$CustomerChatItemImpl(
        chatId: null == chatId
            ? _value.chatId
            : chatId // ignore: cast_nullable_to_non_nullable
                  as String,
        whatsappId: null == whatsappId
            ? _value.whatsappId
            : whatsappId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessagePreview: freezed == lastMessagePreview
            ? _value.lastMessagePreview
            : lastMessagePreview // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessageAt: freezed == lastMessageAt
            ? _value.lastMessageAt
            : lastMessageAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        unreadCount: null == unreadCount
            ? _value.unreadCount
            : unreadCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerChatItemImpl implements _CustomerChatItem {
  const _$CustomerChatItemImpl({
    required this.chatId,
    required this.whatsappId,
    this.displayName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory _$CustomerChatItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerChatItemImplFromJson(json);

  @override
  final String chatId;
  @override
  final String whatsappId;
  @override
  final String? displayName;
  @override
  final String? lastMessagePreview;
  @override
  final String? lastMessageAt;
  @override
  final int unreadCount;

  @override
  String toString() {
    return 'CustomerChatItem(chatId: $chatId, whatsappId: $whatsappId, displayName: $displayName, lastMessagePreview: $lastMessagePreview, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerChatItemImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.whatsappId, whatsappId) ||
                other.whatsappId == whatsappId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.lastMessagePreview, lastMessagePreview) ||
                other.lastMessagePreview == lastMessagePreview) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    chatId,
    whatsappId,
    displayName,
    lastMessagePreview,
    lastMessageAt,
    unreadCount,
  );

  /// Create a copy of CustomerChatItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerChatItemImplCopyWith<_$CustomerChatItemImpl> get copyWith =>
      __$$CustomerChatItemImplCopyWithImpl<_$CustomerChatItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerChatItemImplToJson(this);
  }
}

abstract class _CustomerChatItem implements CustomerChatItem {
  const factory _CustomerChatItem({
    required final String chatId,
    required final String whatsappId,
    final String? displayName,
    final String? lastMessagePreview,
    final String? lastMessageAt,
    required final int unreadCount,
  }) = _$CustomerChatItemImpl;

  factory _CustomerChatItem.fromJson(Map<String, dynamic> json) =
      _$CustomerChatItemImpl.fromJson;

  @override
  String get chatId;
  @override
  String get whatsappId;
  @override
  String? get displayName;
  @override
  String? get lastMessagePreview;
  @override
  String? get lastMessageAt;
  @override
  int get unreadCount;

  /// Create a copy of CustomerChatItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerChatItemImplCopyWith<_$CustomerChatItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductLookupItem _$ProductLookupItemFromJson(Map<String, dynamic> json) {
  return _ProductLookupItem.fromJson(json);
}

/// @nodoc
mixin _$ProductLookupItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this ProductLookupItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductLookupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductLookupItemCopyWith<ProductLookupItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductLookupItemCopyWith<$Res> {
  factory $ProductLookupItemCopyWith(
    ProductLookupItem value,
    $Res Function(ProductLookupItem) then,
  ) = _$ProductLookupItemCopyWithImpl<$Res, ProductLookupItem>;
  @useResult
  $Res call({String id, String name, double price, String? imageUrl});
}

/// @nodoc
class _$ProductLookupItemCopyWithImpl<$Res, $Val extends ProductLookupItem>
    implements $ProductLookupItemCopyWith<$Res> {
  _$ProductLookupItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductLookupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductLookupItemImplCopyWith<$Res>
    implements $ProductLookupItemCopyWith<$Res> {
  factory _$$ProductLookupItemImplCopyWith(
    _$ProductLookupItemImpl value,
    $Res Function(_$ProductLookupItemImpl) then,
  ) = __$$ProductLookupItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, double price, String? imageUrl});
}

/// @nodoc
class __$$ProductLookupItemImplCopyWithImpl<$Res>
    extends _$ProductLookupItemCopyWithImpl<$Res, _$ProductLookupItemImpl>
    implements _$$ProductLookupItemImplCopyWith<$Res> {
  __$$ProductLookupItemImplCopyWithImpl(
    _$ProductLookupItemImpl _value,
    $Res Function(_$ProductLookupItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductLookupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _$ProductLookupItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductLookupItemImpl implements _ProductLookupItem {
  const _$ProductLookupItemImpl({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory _$ProductLookupItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductLookupItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double price;
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'ProductLookupItem(id: $id, name: $name, price: $price, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductLookupItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, price, imageUrl);

  /// Create a copy of ProductLookupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductLookupItemImplCopyWith<_$ProductLookupItemImpl> get copyWith =>
      __$$ProductLookupItemImplCopyWithImpl<_$ProductLookupItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductLookupItemImplToJson(this);
  }
}

abstract class _ProductLookupItem implements ProductLookupItem {
  const factory _ProductLookupItem({
    required final String id,
    required final String name,
    required final double price,
    final String? imageUrl,
  }) = _$ProductLookupItemImpl;

  factory _ProductLookupItem.fromJson(Map<String, dynamic> json) =
      _$ProductLookupItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get price;
  @override
  String? get imageUrl;

  /// Create a copy of ProductLookupItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductLookupItemImplCopyWith<_$ProductLookupItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
