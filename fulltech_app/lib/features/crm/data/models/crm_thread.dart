class CrmThread {
  final String id;
  final String waId;
  final String? phone;
  final String? displayName;
  final String? lastMessagePreview;
  final String? lastMessageType; // text/audio/image/video/document
  final DateTime? lastMessageAt;
  final bool lastMessageFromMe;
  final String? lastMessageStatus; // queued/sent/delivered/read/failed
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final String status;
  final bool important;
  final String? productId;
  final String? internalNote;
  final String? assignedUserId;

  const CrmThread({
    required this.id,
    required this.waId,
    required this.phone,
    required this.displayName,
    required this.lastMessagePreview,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.lastMessageFromMe,
    required this.lastMessageStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
    required this.status,
    required this.important,
    required this.productId,
    required this.internalNote,
    required this.assignedUserId,
  });

  static DateTime? _dtOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static DateTime _dt(dynamic v) {
    final parsed = _dtOrNull(v);
    if (parsed == null) throw Exception('Invalid datetime: $v');
    return parsed;
  }

  factory CrmThread.fromJson(Map<String, dynamic> json) {
    final waId = (json['wa_id'] ?? json['waId'] ?? '') as String;
    final phone =
        (json['phone_e164'] ?? json['phoneE164'] ?? json['phone']) as String?;

    return CrmThread(
      id: (json['id'] ?? '') as String,
      waId: waId,
      phone: phone,
      displayName: (json['display_name'] ?? json['displayName']) as String?,
      lastMessagePreview:
          (json['last_message_preview'] ?? json['lastMessagePreview'])
              as String?,
      lastMessageType:
          (json['last_message_type'] ?? json['lastMessageType']) as String?,
      lastMessageAt: _dtOrNull(
        json['last_message_at'] ?? json['lastMessageAt'],
      ),
      lastMessageFromMe:
          (json['last_message_from_me'] ??
              json['lastMessageFromMe'] as bool?) ??
          false,
      lastMessageStatus:
          (json['last_message_status'] ?? json['lastMessageStatus']) as String?,
      createdAt: _dt(json['created_at'] ?? json['createdAt']),
      updatedAt: _dt(json['updated_at'] ?? json['updatedAt']),
      unreadCount: ((json['unread_count'] ?? json['unreadCount']) as num? ?? 0)
          .toInt(),
      status: (json['status'] ?? 'activo') as String,
      important: (json['important'] as bool?) ?? false,
      productId: (json['product_id'] ?? json['productId']) as String?,
      internalNote: (json['internal_note'] ?? json['internalNote']) as String?,
      assignedUserId:
          (json['assigned_user_id'] ?? json['assignedUserId']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waId': waId,
      'phone': phone,
      'displayName': displayName,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageType': lastMessageType,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessageFromMe': lastMessageFromMe,
      'lastMessageStatus': lastMessageStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'status': status,
      'important': important,
      'productId': productId,
      'internalNote': internalNote,
      'assignedUserId': assignedUserId,
    };
  }
}
