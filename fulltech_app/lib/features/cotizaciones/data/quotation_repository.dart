import 'dart:math';

import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/features/presupuesto/data/quotation_api.dart';

class QuotationRepository {
  QuotationRepository({
    required QuotationApi api,
    required LocalDb db,
  })  : _api = api,
        _db = db;

  final QuotationApi _api;
  final LocalDb _db;

  String _localId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 20);
    return 'local_$millis$rand';
  }

  Future<List<Map<String, dynamic>>> listLocal({
    required String empresaId,
    String? q,
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    return _db.listCotizaciones(
      empresaId: empresaId,
      q: q,
      status: status,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getLocal(String cotizacionId) {
    return _db.getCotizacion(id: cotizacionId);
  }

  Future<List<Map<String, dynamic>>> listLocalItems(String cotizacionId) {
    return _db.listCotizacionItems(quotationId: cotizacionId);
  }

  Future<void> deleteLocal(String cotizacionId) {
    return _db.deleteCotizacion(id: cotizacionId);
  }

  Future<Map<String, dynamic>> createDraftLocal({
    required String empresaId,
    String? customerId,
    String? customerName,
    String status = 'draft',
    String currency = 'MXN',
    String? notes,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final id = _localId();
    final now = DateTime.now().toIso8601String();

    final subtotal = _sumItems(items);
    final total = subtotal;

    await _db.upsertCotizacion(row: {
      'id': id,
      'empresa_id': empresaId,
      'numero': 'BORRADOR',
      'status': status,
      'customer_id': customerId,
      'customer_name': customerName,
      'currency': currency,
      'subtotal': subtotal,
      'tax_total': 0.0,
      'total': total,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
      'synced_at': null,
      'deleted_at': null,
    });

    await _db.replaceCotizacionItems(quotationId: id, items: items);

    return (await _db.getCotizacion(id: id))!;
  }

  double _sumItems(List<Map<String, dynamic>> items) {
    double sum = 0;
    for (final it in items) {
      final qty = (it['quantity'] ?? it['qty'] ?? 1);
      final price = (it['price'] ?? it['unit_price'] ?? 0);
      final q = qty is num ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0;
      final p = price is num ? price.toDouble() : double.tryParse(price.toString()) ?? 0;
      sum += q * p;
    }
    return sum;
  }

  /// Pulls from server and upserts into local DB.
  Future<void> refreshFromServer({
    required String empresaId,
    String? q,
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.listQuotationsPaged(
      q: q,
      status: status,
      from: from?.toIso8601String(),
      to: to?.toIso8601String(),
      limit: limit,
      offset: offset,
    );

    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    for (final qItem in items) {
      await _db.upsertCotizacion(
        row: _mapServerQuotationToLocal(qItem, empresaId: empresaId),
      );

      final serverItems = (qItem['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final localItems = serverItems.map((e) => _mapServerItemToLocal(e, cotizacionId: qItem['id'] as String)).toList();
      await _db.replaceCotizacionItems(
        quotationId: qItem['id'] as String,
        items: localItems,
      );
    }
  }

  Future<Map<String, dynamic>> duplicateRemoteToLocal(String quotationId, {required String empresaId}) async {
    final created = await _api.duplicateQuotation(quotationId);
    await _db.upsertCotizacion(
      row: _mapServerQuotationToLocal(created, empresaId: empresaId),
    );

    final serverItems = (created['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final localItems = serverItems.map((e) => _mapServerItemToLocal(e, cotizacionId: created['id'] as String)).toList();
    await _db.replaceCotizacionItems(
      quotationId: created['id'] as String,
      items: localItems,
    );

    return created;
  }

  Future<void> deleteRemoteAndLocal(String quotationId) async {
    await _api.deleteQuotation(quotationId);
    await _db.deleteCotizacion(id: quotationId);
  }

  Future<Map<String, dynamic>> sendRemote(String quotationId, {required String channel, String? to, String? message}) {
    return _api.sendQuotation(quotationId, channel: channel, to: to, message: message);
  }

  Map<String, dynamic> _mapServerQuotationToLocal(Map<String, dynamic> q, {required String empresaId}) {
    return {
      'id': q['id'],
      'empresa_id': empresaId,
      'numero': q['numero']?.toString() ?? '',
      'status': q['status']?.toString() ?? 'draft',
      'customer_id': q['customerId'] ?? q['customer_id'],
      'customer_name': q['customerName'] ?? q['customer_name'],
      'currency': q['currency']?.toString() ?? 'MXN',
      'subtotal': (q['subtotal'] is num) ? (q['subtotal'] as num).toDouble() : double.tryParse('${q['subtotal']}') ?? 0.0,
      'tax_total': (q['taxTotal'] ?? q['tax_total'] ?? 0.0) is num
          ? (q['taxTotal'] ?? q['tax_total'] ?? 0.0 as num).toDouble()
          : double.tryParse('${q['taxTotal'] ?? q['tax_total'] ?? 0.0}') ?? 0.0,
      'total': (q['total'] is num) ? (q['total'] as num).toDouble() : double.tryParse('${q['total']}') ?? 0.0,
      'notes': q['notes'],
      'created_at': q['createdAt'] ?? q['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': q['updatedAt'] ?? q['updated_at'] ?? DateTime.now().toIso8601String(),
      'synced_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
    };
  }

  Map<String, dynamic> _mapServerItemToLocal(Map<String, dynamic> it, {required String cotizacionId}) {
    return {
      'id': it['id'],
      'cotizacion_id': cotizacionId,
      'product_id': it['productId'] ?? it['product_id'],
      'name': it['name'],
      'description': it['description'],
      'quantity': (it['quantity'] is num) ? (it['quantity'] as num).toDouble() : double.tryParse('${it['quantity']}') ?? 0.0,
      'price': (it['price'] is num) ? (it['price'] as num).toDouble() : double.tryParse('${it['price']}') ?? 0.0,
      'total': (it['total'] is num) ? (it['total'] as num).toDouble() : double.tryParse('${it['total']}') ?? 0.0,
    };
  }
}
