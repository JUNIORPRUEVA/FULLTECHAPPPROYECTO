import 'dart:convert';

class BiweeklyCloseModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expenses;
  final double payrollPaid;
  final double netProfit;
  final String notes;
  final DateTime createdAt;

  const BiweeklyCloseModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expenses,
    required this.payrollPaid,
    required this.netProfit,
    required this.notes,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'income': income,
      'expenses': expenses,
      'payrollPaid': payrollPaid,
      'netProfit': netProfit,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  static BiweeklyCloseModel fromMap(Map<String, Object?> map) {
    double asDouble(Object? v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return BiweeklyCloseModel(
      id: (map['id'] as String?) ?? '',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      income: asDouble(map['income']),
      expenses: asDouble(map['expenses']),
      payrollPaid: asDouble(map['payrollPaid']),
      netProfit: asDouble(map['netProfit']),
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static BiweeklyCloseModel fromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('Invalid biweekly close json');
    }

    return fromMap(decoded.cast<String, Object?>());
  }
}
