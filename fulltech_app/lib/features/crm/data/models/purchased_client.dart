class PurchasedClient {
  final String id;
  final String waId;
  final String? displayName;
  final String? phoneE164;
  final String? note;
  final String? assignedToUserId;
  final String? productId;
  final String status;
  final bool isImportant;
  final bool followUp;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? assignedUserName;
  final String? productName;

  PurchasedClient({
    required this.id,
    required this.waId,
    this.displayName,
    this.phoneE164,
    this.note,
    this.assignedToUserId,
    this.productId,
    required this.status,
    this.isImportant = false,
    this.followUp = false,
    this.lastMessageText,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    this.assignedUserName,
    this.productName,
  });

  // Computed properties
  String get displayNameOrPhone => displayName?.isNotEmpty == true
      ? displayName!
      : (phoneE164?.isNotEmpty == true ? phoneE164! : waId);

  String get initials {
    final name = displayNameOrPhone;
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  factory PurchasedClient.fromJson(Map<String, dynamic> json) {
    return PurchasedClient(
      id: json['id'] ?? '',
      waId: json['waId'] ?? json['whatsappId'] ?? '',
      displayName: json['displayName'],
      phoneE164: json['phoneE164'] ?? json['phone'],
      note: json['note'],
      assignedToUserId: json['assignedToUserId'] ?? json['assignedUserId'],
      productId: json['productId'],
      status: json['status'] ?? 'compro',
      isImportant: json['isImportant'] ?? false,
      followUp: json['followUp'] ?? false,
      lastMessageText: json['lastMessageText'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      assignedUserName: json['assignedUserName'],
      productName: json['productName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waId': waId,
      'displayName': displayName,
      'phoneE164': phoneE164,
      'note': note,
      'assignedToUserId': assignedToUserId,
      'productId': productId,
      'status': status,
      'isImportant': isImportant,
      'followUp': followUp,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedUserName': assignedUserName,
      'productName': productName,
    };
  }

  PurchasedClient copyWith({
    String? id,
    String? waId,
    String? displayName,
    String? phoneE164,
    String? note,
    String? assignedToUserId,
    String? productId,
    String? status,
    bool? isImportant,
    bool? followUp,
    String? lastMessageText,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedUserName,
    String? productName,
  }) {
    return PurchasedClient(
      id: id ?? this.id,
      waId: waId ?? this.waId,
      displayName: displayName ?? this.displayName,
      phoneE164: phoneE164 ?? this.phoneE164,
      note: note ?? this.note,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      isImportant: isImportant ?? this.isImportant,
      followUp: followUp ?? this.followUp,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedUserName: assignedUserName ?? this.assignedUserName,
      productName: productName ?? this.productName,
    );
  }
}

class PurchasedClientsResponse {
  final List<PurchasedClient> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PurchasedClientsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PurchasedClientsResponse.fromJson(Map<String, dynamic> json) {
    return PurchasedClientsResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => PurchasedClient.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 30,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }
}