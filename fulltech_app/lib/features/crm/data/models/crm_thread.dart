class CrmThread {
  final String id;
  final String waId;
  final String? phone;
  final String? displayName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final String status;

  const CrmThread({
    required this.id,
    required this.waId,
    required this.phone,
    required this.displayName,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
    required this.status,
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
    return CrmThread(
      id: (json['id'] ?? '') as String,
      waId: (json['wa_id'] ?? '') as String,
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: _dtOrNull(json['last_message_at']),
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
      unreadCount: (json['unread_count'] as num? ?? 0).toInt(),
      status: (json['status'] ?? 'activo') as String,
    );
  }
}
