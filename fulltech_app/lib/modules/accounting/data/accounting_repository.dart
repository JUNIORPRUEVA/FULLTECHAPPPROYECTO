import 'models/biweekly_close_model.dart';

class BiweeklyCloseListFilters {
  final String? query;
  final DateTime? from;
  final DateTime? to;

  const BiweeklyCloseListFilters({this.query, this.from, this.to});
}

class BiweeklyCloseUpsertData {
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expenses;
  final double payrollPaid;
  final String notes;

  const BiweeklyCloseUpsertData({
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expenses,
    required this.payrollPaid,
    required this.notes,
  });
}

abstract class AccountingRepository {
  Future<List<BiweeklyCloseModel>> listBiweeklyCloses({
    BiweeklyCloseListFilters? filters,
  });

  Future<BiweeklyCloseModel> createBiweeklyClose(BiweeklyCloseUpsertData data);

  Future<BiweeklyCloseModel> updateBiweeklyClose(
    String id,
    BiweeklyCloseUpsertData data,
  );

  Future<void> deleteBiweeklyClose(String id);
}
