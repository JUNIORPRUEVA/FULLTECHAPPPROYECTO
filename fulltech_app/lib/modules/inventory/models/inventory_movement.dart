double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final v = value.trim();
    if (v.isEmpty) return 0;
    return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

class InventoryMovement {
  final String id;
  final String refType;
  final String? refId;
  final double qtyChange;
  final double unitCost;
  final String? note;
  final DateTime createdAt;
  final String? createdByUserId;
  final String? userName;

  const InventoryMovement({
    required this.id,
    required this.refType,
    required this.refId,
    required this.qtyChange,
    required this.unitCost,
    required this.note,
    required this.createdAt,
    required this.createdByUserId,
    required this.userName,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: _toString(json['id']),
      refType: _toString(json['ref_type']),
      refId: (json['ref_id'] as String?)?.trim().isEmpty == true
          ? null
          : (json['ref_id'] as String?),
      qtyChange: _toDouble(json['qty_change']),
      unitCost: _toDouble(json['unit_cost']),
      note: (json['note'] as String?)?.trim().isEmpty == true
          ? null
          : (json['note'] as String?),
      createdAt: DateTime.tryParse(_toString(json['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdByUserId: (json['created_by_user_id'] as String?)?.trim().isEmpty ==
              true
          ? null
          : (json['created_by_user_id'] as String?),
      userName: (json['user_name'] as String?)?.trim().isEmpty == true
          ? null
          : (json['user_name'] as String?),
    );
  }
}
