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
    final fromMeRaw = json['fromMe'] ?? json['from_me'];
    final directionRaw = json['direction'];

    final direction = (directionRaw is String && directionRaw.trim().isNotEmpty)
        ? directionRaw
        : null;
    final fromMe = fromMeRaw is bool
        ? fromMeRaw
        : (direction ?? 'in').toLowerCase() == 'out';

    final ts =
        _dtOrNull(json['createdAt']) ??
        _dtOrNull(json['created_at']) ??
        _dtOrNull(json['timestamp']) ??
        _dt(json['created_at']);

    final type =
        (json['type'] ?? json['message_type'] ?? json['messageType'] ?? 'text')
            .toString();

    return CrmMessage(
      id: (json['id'] ?? '') as String,
      fromMe: fromMe,
      type: type,
      body: (json['text'] ?? json['body'] ?? json['caption']) as String?,
      mediaUrl: (json['mediaUrl'] ?? json['media_url']) as String?,
      status: (json['status'] ?? 'received') as String,
      createdAt: ts,
    );
  }
}
