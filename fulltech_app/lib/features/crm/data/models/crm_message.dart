class CrmMessage {
  final String id;
  final bool fromMe;
  final String type;
  final String? body;
  final String? mediaUrl;
  final String status;
  final DateTime createdAt;

  const CrmMessage({
    required this.id,
    required this.fromMe,
    required this.type,
    required this.body,
    required this.mediaUrl,
    required this.status,
    required this.createdAt,
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

  factory CrmMessage.fromJson(Map<String, dynamic> json) {
    final direction = (json['direction'] ?? 'in') as String;
    final fromMe = direction == 'out';

    final ts = _dtOrNull(json['timestamp']) ?? _dt(json['created_at']);

    return CrmMessage(
      id: (json['id'] ?? '') as String,
      fromMe: fromMe,
      type: (json['message_type'] ?? 'text') as String,
      body: json['text'] as String?,
      mediaUrl: json['media_url'] as String?,
      status: (json['status'] ?? 'received') as String,
      createdAt: ts,
    );
  }
}
