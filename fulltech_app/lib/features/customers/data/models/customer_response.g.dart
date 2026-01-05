// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerListResponseImpl _$$CustomerListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerListResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => CustomerItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  stats: CustomerStats.fromJson(json['stats'] as Map<String, dynamic>),
  topProducts: (json['topProducts'] as List<dynamic>)
      .map((e) => ProductLookupItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  topCustomers: (json['topCustomers'] as List<dynamic>)
      .map((e) => TopCustomer.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$CustomerListResponseImplToJson(
  _$CustomerListResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'stats': instance.stats,
  'topProducts': instance.topProducts,
  'topCustomers': instance.topCustomers,
};

_$TopCustomerImpl _$$TopCustomerImplFromJson(Map<String, dynamic> json) =>
    _$TopCustomerImpl(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      totalPurchasesCount: (json['totalPurchasesCount'] as num).toInt(),
    );

Map<String, dynamic> _$$TopCustomerImplToJson(_$TopCustomerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'totalSpent': instance.totalSpent,
      'totalPurchasesCount': instance.totalPurchasesCount,
    };

_$CustomerItemImpl _$$CustomerItemImplFromJson(Map<String, dynamic> json) =>
    _$CustomerItemImpl(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      whatsappId: json['whatsappId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String,
      isActiveCustomer: json['isActiveCustomer'] as bool,
      totalPurchasesCount: (json['totalPurchasesCount'] as num).toInt(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      lastPurchaseAt: json['lastPurchaseAt'] as String?,
      lastChatAt: json['lastChatAt'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      assignedProduct: json['assignedProduct'] == null
          ? null
          : LastProduct.fromJson(
              json['assignedProduct'] as Map<String, dynamic>,
            ),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      important: json['important'] as bool,
      internalNote: json['internalNote'] as String?,
    );

Map<String, dynamic> _$$CustomerItemImplToJson(_$CustomerItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phone': instance.phone,
      'whatsappId': instance.whatsappId,
      'avatarUrl': instance.avatarUrl,
      'status': instance.status,
      'isActiveCustomer': instance.isActiveCustomer,
      'totalPurchasesCount': instance.totalPurchasesCount,
      'totalSpent': instance.totalSpent,
      'lastPurchaseAt': instance.lastPurchaseAt,
      'lastChatAt': instance.lastChatAt,
      'lastMessagePreview': instance.lastMessagePreview,
      'assignedProduct': instance.assignedProduct,
      'tags': instance.tags,
      'important': instance.important,
      'internalNote': instance.internalNote,
    };

_$LastProductImpl _$$LastProductImplFromJson(Map<String, dynamic> json) =>
    _$LastProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$LastProductImplToJson(_$LastProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
    };

_$CustomerStatsImpl _$$CustomerStatsImplFromJson(Map<String, dynamic> json) =>
    _$CustomerStatsImpl(
      totalCustomers: (json['totalCustomers'] as num).toInt(),
      activeCustomers: (json['activeCustomers'] as num).toInt(),
      byStatus: Map<String, int>.from(json['byStatus'] as Map),
    );

Map<String, dynamic> _$$CustomerStatsImplToJson(_$CustomerStatsImpl instance) =>
    <String, dynamic>{
      'totalCustomers': instance.totalCustomers,
      'activeCustomers': instance.activeCustomers,
      'byStatus': instance.byStatus,
    };

_$CustomerDetailResponseImpl _$$CustomerDetailResponseImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerDetailResponseImpl(
  customer: CustomerDetail.fromJson(json['customer'] as Map<String, dynamic>),
  purchases: (json['purchases'] as List<dynamic>)
      .map((e) => CustomerPurchase.fromJson(e as Map<String, dynamic>))
      .toList(),
  stats: CustomerDetailStats.fromJson(json['stats'] as Map<String, dynamic>),
  chats: (json['chats'] as List<dynamic>)
      .map((e) => CustomerChatItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$CustomerDetailResponseImplToJson(
  _$CustomerDetailResponseImpl instance,
) => <String, dynamic>{
  'customer': instance.customer,
  'purchases': instance.purchases,
  'stats': instance.stats,
  'chats': instance.chats,
};

_$CustomerDetailImpl _$$CustomerDetailImplFromJson(Map<String, dynamic> json) =>
    _$CustomerDetailImpl(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      whatsappId: json['whatsappId'] as String?,
      status: json['status'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      internalNote: json['internalNote'] as String?,
      important: json['important'] as bool,
      assignedProduct: json['assignedProduct'] == null
          ? null
          : LastProduct.fromJson(
              json['assignedProduct'] as Map<String, dynamic>,
            ),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$CustomerDetailImplToJson(
  _$CustomerDetailImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'whatsappId': instance.whatsappId,
  'status': instance.status,
  'email': instance.email,
  'address': instance.address,
  'tags': instance.tags,
  'internalNote': instance.internalNote,
  'important': instance.important,
  'assignedProduct': instance.assignedProduct,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

_$CustomerDetailStatsImpl _$$CustomerDetailStatsImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerDetailStatsImpl(
  totalPurchases: (json['totalPurchases'] as num).toInt(),
  totalSpent: (json['totalSpent'] as num).toDouble(),
  lastPurchaseAt: json['lastPurchaseAt'] as String?,
);

Map<String, dynamic> _$$CustomerDetailStatsImplToJson(
  _$CustomerDetailStatsImpl instance,
) => <String, dynamic>{
  'totalPurchases': instance.totalPurchases,
  'totalSpent': instance.totalSpent,
  'lastPurchaseAt': instance.lastPurchaseAt,
};

_$CustomerPurchaseImpl _$$CustomerPurchaseImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerPurchaseImpl(
  id: json['id'] as String,
  date: json['date'] as String,
  product: json['product'] == null
      ? null
      : PurchaseProduct.fromJson(json['product'] as Map<String, dynamic>),
  quantity: (json['quantity'] as num).toInt(),
  total: (json['total'] as num).toDouble(),
  paymentMethod: json['paymentMethod'] as String?,
);

Map<String, dynamic> _$$CustomerPurchaseImplToJson(
  _$CustomerPurchaseImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date,
  'product': instance.product,
  'quantity': instance.quantity,
  'total': instance.total,
  'paymentMethod': instance.paymentMethod,
};

_$PurchaseProductImpl _$$PurchaseProductImplFromJson(
  Map<String, dynamic> json,
) => _$PurchaseProductImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$$PurchaseProductImplToJson(
  _$PurchaseProductImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
};

_$CustomerChatItemImpl _$$CustomerChatItemImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerChatItemImpl(
  chatId: json['chatId'] as String,
  whatsappId: json['whatsappId'] as String,
  displayName: json['displayName'] as String?,
  lastMessagePreview: json['lastMessagePreview'] as String?,
  lastMessageAt: json['lastMessageAt'] as String?,
  unreadCount: (json['unreadCount'] as num).toInt(),
);

Map<String, dynamic> _$$CustomerChatItemImplToJson(
  _$CustomerChatItemImpl instance,
) => <String, dynamic>{
  'chatId': instance.chatId,
  'whatsappId': instance.whatsappId,
  'displayName': instance.displayName,
  'lastMessagePreview': instance.lastMessagePreview,
  'lastMessageAt': instance.lastMessageAt,
  'unreadCount': instance.unreadCount,
};

_$ProductLookupItemImpl _$$ProductLookupItemImplFromJson(
  Map<String, dynamic> json,
) => _$ProductLookupItemImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$$ProductLookupItemImplToJson(
  _$ProductLookupItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
};
