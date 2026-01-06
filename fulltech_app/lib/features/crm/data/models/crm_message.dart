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
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;

      // Some APIs send unix timestamps as strings.
      final asNum = num.tryParse(s);
      if (asNum != null) {
        final ms = _toEpochMs(asNum);
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
      return null;
    }

    if (v is num) {
      final ms = _toEpochMs(v);
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    return null;
  }

  static int _toEpochMs(num v) {
    // Heuristic: seconds are ~1e9..1e10, milliseconds are ~1e12..1e13.
    final abs = v.abs();
    if (abs >= 100000000000) {
      return v.toInt();
    }
    return (v * 1000).round();
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromMe': fromMe,
      'type': type,
      'body': body,
      'mediaUrl': mediaUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
