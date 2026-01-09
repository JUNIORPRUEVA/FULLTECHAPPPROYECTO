import 'dart:math';
import 'dart:convert';

import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/features/presupuesto/data/quotation_api.dart';
import 'package:dio/dio.dart';

class QuotationRepository {
  QuotationRepository({required QuotationApi api, required LocalDb db})
    : _api = api,
      _db = db;

  final QuotationApi _api;
  final LocalDb _db;

  static const _syncModule = 'quotations';

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

    await _db.upsertCotizacion(
      row: {
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
      },
    );

    await _db.replaceCotizacionItems(quotationId: id, items: items);

    return (await _db.getCotizacion(id: id))!;
  }

  double _sumItems(List<Map<String, dynamic>> items) {
    double sum = 0;
    for (final it in items) {
      final qty = (it['quantity'] ?? it['qty'] ?? 1);
      final price = (it['price'] ?? it['unit_price'] ?? 0);
      final q = qty is num
          ? qty.toDouble()
          : double.tryParse(qty.toString()) ?? 0;
      final p = price is num
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0;
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

      final serverItems =
          (qItem['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final localItems = serverItems
          .map(
            (e) =>
                _mapServerItemToLocal(e, cotizacionId: qItem['id'] as String),
          )
          .toList();
      await _db.replaceCotizacionItems(
        quotationId: qItem['id'] as String,
        items: localItems,
      );
    }
  }

  Future<Map<String, dynamic>> duplicateRemoteToLocal(
    String quotationId, {
    required String empresaId,
  }) async {
    final created = await _api.duplicateQuotation(quotationId);
    await _db.upsertCotizacion(
      row: _mapServerQuotationToLocal(created, empresaId: empresaId),
    );

    final serverItems =
        (created['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final localItems = serverItems
        .map(
          (e) =>
              _mapServerItemToLocal(e, cotizacionId: created['id'] as String),
        )
        .toList();
    await _db.replaceCotizacionItems(
      quotationId: created['id'] as String,
      items: localItems,
    );

    return created;
  }

  Future<void> deleteRemoteAndLocal(String quotationId) async {
    // Offline-first delete:
    // - mark as deleted locally (so it disappears from lists)
    // - try remote delete
    // - if remote fails due to connectivity, enqueue for later
    final nowIso = DateTime.now().toIso8601String();

    final existing = await _db.getCotizacion(id: quotationId);
    if (existing != null) {
      final patched = <String, Object?>{...existing};
      patched['deleted_at'] = nowIso;
      patched['updated_at'] = nowIso;
      patched['sync_status'] = 'pending';
      patched['last_error'] = null;
      await _db.upsertCotizacion(row: patched);
    }

    try {
      await _api.deleteQuotation(quotationId);
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await _db.enqueueSync(
          module: _syncModule,
          op: 'delete',
          entityId: quotationId,
          payloadJson: jsonEncode(<String, dynamic>{}),
        );
        return;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendRemote(
    String quotationId, {
    required String channel,
    String? to,
    String? message,
  }) {
    return _api.sendQuotation(
      quotationId,
      channel: channel,
      to: to,
      message: message,
    );
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  /// Processes queued sync items for quotations.
  ///
  /// This is used by the global AutoSync wrapper.
  Future<void> syncPending() async {
    // CRITICAL: Verify session exists before attempting any sync
    final session = await _db.readSession();
    if (session == null) return;

    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;

      try {
        if (item.op == 'upsert') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

          Map<String, dynamic> remote;
          try {
            remote = await _api.createQuotation(payload);
          } catch (_) {
            remote = await _api.updateQuotation(item.entityId, payload);
          }

          final remoteId = (remote['id'] ?? item.entityId).toString();
          final empresaId = (remote['empresa_id'] ?? remote['empresaId'] ?? '')
              .toString();

          // Best-effort: update local header.
          final existing = await _db.getCotizacion(id: item.entityId);
          final base = existing == null
              ? <String, Object?>{}
              : <String, Object?>{...existing};
          base['id'] = remoteId;
          if (empresaId.isNotEmpty) base['empresa_id'] = empresaId;
          base['numero'] = (remote['numero'] ?? base['numero'] ?? '')
              .toString();
          base['status'] = (remote['status'] ?? base['status'] ?? 'draft')
              .toString();
          base['customer_id'] =
              (remote['customerId'] ??
              remote['customer_id'] ??
              base['customer_id']);
          base['customer_name'] =
              (remote['customerName'] ??
              remote['customer_name'] ??
              base['customer_name']);
          base['customer_phone'] =
              (remote['customerPhone'] ??
              remote['customer_phone'] ??
              base['customer_phone']);
          base['customer_email'] =
              (remote['customerEmail'] ??
              remote['customer_email'] ??
              base['customer_email']);
          base['itbis_enabled'] =
              ((remote['itbisEnabled'] ?? remote['itbis_enabled']) == true)
              ? 1
              : (base['itbis_enabled'] ?? 0);
          base['itbis_rate'] =
              (remote['itbisRate'] ??
              remote['itbis_rate'] ??
              base['itbis_rate']);
          base['subtotal'] = (remote['subtotal'] ?? base['subtotal']);
          base['itbis_amount'] =
              (remote['itbisAmount'] ??
              remote['itbis_amount'] ??
              base['itbis_amount']);
          base['total'] = (remote['total'] ?? base['total']);
          base['notes'] = (remote['notes'] ?? base['notes']);
          base['created_at'] =
              (remote['createdAt'] ??
                      remote['created_at'] ??
                      base['created_at'] ??
                      DateTime.now().toIso8601String())
                  .toString();
          base['updated_at'] =
              (remote['updatedAt'] ??
                      remote['updated_at'] ??
                      DateTime.now().toIso8601String())
                  .toString();
          base['sync_status'] = 'synced';
          base['last_error'] = null;
          await _db.upsertCotizacion(row: base);

          // Best-effort: replace items if server returns them.
          final remoteItems =
              (remote['items'] as List?)?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];
          if (remoteItems.isNotEmpty) {
            await _db.replaceCotizacionItems(
              quotationId: remoteId,
              items: remoteItems
                  .map(
                    (it) => _mapServerItemToLocal(it, cotizacionId: remoteId),
                  )
                  .toList(growable: false),
            );
          }

          // If server changed the ID, we keep local old row as-is (rare), but mark new row synced.
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'delete') {
          await _api.deleteQuotation(item.entityId);
          await _db.markSyncItemSent(item.id);
          continue;
        }

        // Unknown op
        await _db.markSyncItemSent(item.id);
      } catch (e) {
        // CRITICAL: Stop retry loop on 401
        if (e is DioException && e.response?.statusCode == 401) {
          await _db.markSyncItemSent(item.id);
          return;
        }

        await _db.markSyncItemError(item.id);
        try {
          final existing = await _db.getCotizacion(id: item.entityId);
          if (existing != null) {
            final patched = <String, Object?>{...existing};
            patched['sync_status'] = 'error';
            patched['last_error'] = e.toString();
            patched['updated_at'] = DateTime.now().toIso8601String();
            await _db.upsertCotizacion(row: patched);
          }
        } catch (_) {}
      }
    }
  }

  Map<String, dynamic> _mapServerQuotationToLocal(
    Map<String, dynamic> q, {
    required String empresaId,
  }) {
    return {
      'id': q['id'],
      'empresa_id': empresaId,
      'numero': q['numero']?.toString() ?? '',
      'status': q['status']?.toString() ?? 'draft',
      'customer_id': q['customerId'] ?? q['customer_id'],
      'customer_name': q['customerName'] ?? q['customer_name'],
      'currency': q['currency']?.toString() ?? 'MXN',
      'subtotal': (q['subtotal'] is num)
          ? (q['subtotal'] as num).toDouble()
          : double.tryParse('${q['subtotal']}') ?? 0.0,
      'tax_total': (q['taxTotal'] ?? q['tax_total'] ?? 0.0) is num
          ? (q['taxTotal'] ?? q['tax_total'] ?? 0.0 as num).toDouble()
          : double.tryParse('${q['taxTotal'] ?? q['tax_total'] ?? 0.0}') ?? 0.0,
      'total': (q['total'] is num)
          ? (q['total'] as num).toDouble()
          : double.tryParse('${q['total']}') ?? 0.0,
      'notes': q['notes'],
      'created_at':
          q['createdAt'] ?? q['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at':
          q['updatedAt'] ?? q['updated_at'] ?? DateTime.now().toIso8601String(),
      'synced_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
    };
  }

  Map<String, dynamic> _mapServerItemToLocal(
    Map<String, dynamic> it, {
    required String cotizacionId,
  }) {
    return {
      'id': it['id'],
      'cotizacion_id': cotizacionId,
      'product_id': it['productId'] ?? it['product_id'],
      'name': it['name'],
      'description': it['description'],
      'quantity': (it['quantity'] is num)
          ? (it['quantity'] as num).toDouble()
          : double.tryParse('${it['quantity']}') ?? 0.0,
      'price': (it['price'] is num)
          ? (it['price'] as num).toDouble()
          : double.tryParse('${it['price']}') ?? 0.0,
      'total': (it['total'] is num)
          ? (it['total'] as num).toDouble()
          : double.tryParse('${it['total']}') ?? 0.0,
    };
  }
}
