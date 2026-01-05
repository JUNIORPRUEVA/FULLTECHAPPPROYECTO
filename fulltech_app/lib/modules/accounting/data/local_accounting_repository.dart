import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db.dart';
import 'accounting_repository.dart';
import 'models/biweekly_close_model.dart';

class LocalAccountingRepository implements AccountingRepository {
  static const _storeBiweeklyCloses = 'accounting_biweekly_closes';

  final LocalDb _db;
  final Uuid _uuid;

  LocalAccountingRepository({required LocalDb db, Uuid? uuid})
    : _db = db,
      _uuid = uuid ?? const Uuid();

  @override
  Future<List<BiweeklyCloseModel>> listBiweeklyCloses({
    BiweeklyCloseListFilters? filters,
  }) async {
    final jsonList = await _db.listEntitiesJson(store: _storeBiweeklyCloses);

    final items = <BiweeklyCloseModel>[];
    for (final json in jsonList) {
      try {
        items.add(BiweeklyCloseModel.fromJson(json));
      } catch (_) {
        // ignore malformed entries
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final q = (filters?.query ?? '').trim().toLowerCase();
    final from = filters?.from;
    final to = filters?.to;

    bool matchesQuery(BiweeklyCloseModel it) {
      if (q.isEmpty) return true;
      final period =
          '${it.startDate.toIso8601String().split('T').first} - ${it.endDate.toIso8601String().split('T').first}'
              .toLowerCase();
      return it.notes.toLowerCase().contains(q) || period.contains(q);
    }

    bool matchesRange(BiweeklyCloseModel it) {
      if (from != null && it.startDate.isBefore(_dateOnly(from))) return false;
      if (to != null && it.endDate.isAfter(_dateOnly(to))) return false;
      return true;
    }

    return items.where((it) => matchesQuery(it) && matchesRange(it)).toList();
  }

  @override
  Future<BiweeklyCloseModel> createBiweeklyClose(
    BiweeklyCloseUpsertData data,
  ) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now();
    final netProfit = _computeNetProfit(
      income: data.income,
      expenses: data.expenses,
      payrollPaid: data.payrollPaid,
    );

    final model = BiweeklyCloseModel(
      id: id,
      startDate: _dateOnly(data.startDate),
      endDate: _dateOnly(data.endDate),
      income: data.income,
      expenses: data.expenses,
      payrollPaid: data.payrollPaid,
      netProfit: netProfit,
      notes: data.notes,
      createdAt: createdAt,
    );

    await _db.upsertEntity(
      store: _storeBiweeklyCloses,
      id: id,
      json: model.toJson(),
    );
    return model;
  }

  @override
  Future<BiweeklyCloseModel> updateBiweeklyClose(
    String id,
    BiweeklyCloseUpsertData data,
  ) async {
    final existingJsonList = await _db.listEntitiesJson(
      store: _storeBiweeklyCloses,
    );
    BiweeklyCloseModel? existing;

    for (final json in existingJsonList) {
      try {
        final parsed = BiweeklyCloseModel.fromJson(json);
        if (parsed.id == id) {
          existing = parsed;
          break;
        }
      } catch (_) {
        // ignore
      }
    }

    final createdAt = existing?.createdAt ?? DateTime.now();
    final netProfit = _computeNetProfit(
      income: data.income,
      expenses: data.expenses,
      payrollPaid: data.payrollPaid,
    );

    final model = BiweeklyCloseModel(
      id: id,
      startDate: _dateOnly(data.startDate),
      endDate: _dateOnly(data.endDate),
      income: data.income,
      expenses: data.expenses,
      payrollPaid: data.payrollPaid,
      netProfit: netProfit,
      notes: data.notes,
      createdAt: createdAt,
    );

    await _db.upsertEntity(
      store: _storeBiweeklyCloses,
      id: id,
      json: model.toJson(),
    );
    return model;
  }

  @override
  Future<void> deleteBiweeklyClose(String id) async {
    await _db.deleteEntity(store: _storeBiweeklyCloses, id: id);
  }

  static double _computeNetProfit({
    required double income,
    required double expenses,
    required double payrollPaid,
  }) {
    return income - (expenses + payrollPaid);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
