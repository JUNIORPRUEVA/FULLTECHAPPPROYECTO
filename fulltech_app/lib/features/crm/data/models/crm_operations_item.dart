enum CrmOperationsItemType {
  agenda,
  levantamiento;

  static CrmOperationsItemType? fromWire(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v == 'AGENDA') return CrmOperationsItemType.agenda;
    if (v == 'LEVANTAMIENTO') return CrmOperationsItemType.levantamiento;
    return null;
  }

  String toWire() {
    switch (this) {
      case CrmOperationsItemType.agenda:
        return 'AGENDA';
      case CrmOperationsItemType.levantamiento:
        return 'LEVANTAMIENTO';
    }
  }
}

class CrmOperationsItem {
  final String id;
  final String chatId;
  final CrmOperationsItemType type;
  final DateTime? scheduledAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrmOperationsItem({
    required this.id,
    required this.chatId,
    required this.type,
    required this.scheduledAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _dtOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static DateTime _dt(dynamic v) => _dtOrNull(v) ?? DateTime.now();

  factory CrmOperationsItem.fromJson(Map<String, dynamic> json) {
    final type = CrmOperationsItemType.fromWire(json['type']?.toString());
    return CrmOperationsItem(
      id: (json['id'] ?? '').toString(),
      chatId: (json['chat_id'] ?? json['chatId'] ?? '').toString(),
      type: type ?? CrmOperationsItemType.agenda,
      scheduledAt: _dtOrNull(json['scheduled_at'] ?? json['scheduledAt']),
      note: (json['nota'] ?? json['note'])?.toString(),
      createdAt: _dt(json['created_at'] ?? json['createdAt']),
      updatedAt: _dt(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class CrmOperationsItemsResponse {
  final List<CrmOperationsItem> agenda;
  final List<CrmOperationsItem> levantamientos;

  const CrmOperationsItemsResponse({
    required this.agenda,
    required this.levantamientos,
  });

  factory CrmOperationsItemsResponse.fromJson(Map<String, dynamic> json) {
    final agenda =
        (json['agenda'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(CrmOperationsItem.fromJson)
            .toList(growable: false);

    final levantamientos =
        (json['levantamientos'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(CrmOperationsItem.fromJson)
            .toList(growable: false);

    return CrmOperationsItemsResponse(
      agenda: agenda,
      levantamientos: levantamientos,
    );
  }
}
