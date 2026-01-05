import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_response.freezed.dart';
part 'customer_response.g.dart';

/// Main customer list response with metadata and stats
@freezed
class CustomerListResponse with _$CustomerListResponse {
  const factory CustomerListResponse({
    required List<CustomerItem> items,
    required int total,
    required CustomerStats stats,
    required List<ProductLookupItem> topProducts,
    required List<TopCustomer> topCustomers,
  }) = _CustomerListResponse;

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerListResponseFromJson(json);
}

/// Top customer item
@freezed
class TopCustomer with _$TopCustomer {
  const factory TopCustomer({
    required String id,
    required String fullName,
    required double totalSpent,
    required int totalPurchasesCount,
  }) = _TopCustomer;

  factory TopCustomer.fromJson(Map<String, dynamic> json) =>
      _$TopCustomerFromJson(json);
}

/// Individual customer in the list
@freezed
class CustomerItem with _$CustomerItem {
  const factory CustomerItem({
    required String id,
    required String fullName,
    required String phone,
    String? whatsappId,
    String? avatarUrl,
    required String status,
    required bool isActiveCustomer,
    required int totalPurchasesCount,
    required double totalSpent,
    String? lastPurchaseAt,
    String? lastChatAt,
    String? lastMessagePreview,
    LastProduct? assignedProduct,
    required List<String> tags,
    required bool important,
    String? internalNote,
  }) = _CustomerItem;

  factory CustomerItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerItemFromJson(json);
}

/// Last product info
@freezed
class LastProduct with _$LastProduct {
  const factory LastProduct({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) = _LastProduct;

  factory LastProduct.fromJson(Map<String, dynamic> json) =>
      _$LastProductFromJson(json);
}

/// Stats about customers
@freezed
class CustomerStats with _$CustomerStats {
  const factory CustomerStats({
    required int totalCustomers,
    required int activeCustomers,
    required Map<String, int> byStatus,
  }) = _CustomerStats;

  factory CustomerStats.fromJson(Map<String, dynamic> json) =>
      _$CustomerStatsFromJson(json);
}

/// Full customer detail response
@freezed
class CustomerDetailResponse with _$CustomerDetailResponse {
  const factory CustomerDetailResponse({
    required CustomerDetail customer,
    required List<CustomerPurchase> purchases,
    required CustomerDetailStats stats,
    required List<CustomerChatItem> chats,
  }) = _CustomerDetailResponse;

  factory CustomerDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailResponseFromJson(json);
}

/// Customer detail object
@freezed
class CustomerDetail with _$CustomerDetail {
  const factory CustomerDetail({
    required String id,
    required String fullName,
    required String phone,
    String? whatsappId,
    required String status,
    String? email,
    String? address,
    required List<String> tags,
    String? internalNote,
    required bool important,
    LastProduct? assignedProduct,
    required String createdAt,
    required String updatedAt,
  }) = _CustomerDetail;

  factory CustomerDetail.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailFromJson(json);
}

/// Stats for customer detail
@freezed
class CustomerDetailStats with _$CustomerDetailStats {
  const factory CustomerDetailStats({
    required int totalPurchases,
    required double totalSpent,
    String? lastPurchaseAt,
  }) = _CustomerDetailStats;

  factory CustomerDetailStats.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailStatsFromJson(json);
}

/// Purchase record
@freezed
class CustomerPurchase with _$CustomerPurchase {
  const factory CustomerPurchase({
    required String id,
    required String date,
    PurchaseProduct? product,
    required int quantity,
    required double total,
    String? paymentMethod,
  }) = _CustomerPurchase;

  factory CustomerPurchase.fromJson(Map<String, dynamic> json) =>
      _$CustomerPurchaseFromJson(json);
}

/// Product in a purchase
@freezed
class PurchaseProduct with _$PurchaseProduct {
  const factory PurchaseProduct({
    required String id,
    required String name,
    String? imageUrl,
  }) = _PurchaseProduct;

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) =>
      _$PurchaseProductFromJson(json);
}

/// Chat info
@freezed
class CustomerChatItem with _$CustomerChatItem {
  const factory CustomerChatItem({
    required String chatId,
    required String whatsappId,
    String? displayName,
    String? lastMessagePreview,
    String? lastMessageAt,
    required int unreadCount,
  }) = _CustomerChatItem;

  factory CustomerChatItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerChatItemFromJson(json);
}

/// Product lookup item
@freezed
class ProductLookupItem with _$ProductLookupItem {
  const factory ProductLookupItem({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) = _ProductLookupItem;

  factory ProductLookupItem.fromJson(Map<String, dynamic> json) =>
      _$ProductLookupItemFromJson(json);
}
