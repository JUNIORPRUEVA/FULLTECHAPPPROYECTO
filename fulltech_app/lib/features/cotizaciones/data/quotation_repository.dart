import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/features/presupuesto/data/quotation_api.dart';

class QuotationRepository {
  QuotationRepository({required QuotationApi api, required LocalDb db})
    : _api = api,
      _db = db;

  final QuotationApi _api;
  final LocalDb _db;

  static const _syncModule = 'quotations';

  double _asDouble(Object? value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

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

  Future<Map<String, dynamic>> getRemote(String quotationId) async {
    return _api.getQuotation(quotationId);
  }

  Future<void> deleteLocal(String cotizacionId) {
    return _db.deleteCotizacion(id: cotizacionId);
  }

  Future<Map<String, dynamic>> createDraftLocal({
    required String empresaId,
    String? customerId,
    String? customerName,
    String status = 'draft',
    String? notes,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final session = await _db.readSession();
    if (session == null) {
      throw StateError('missing_session');
    }

    final id = _localId();
    final now = DateTime.now().toIso8601String();

    final computed = _computeLocalTotals(items);
    final subtotal = computed.subtotal;
    final itbisEnabled = computed.itbisEnabled;
    final itbisRate = computed.itbisRate;
    final itbisAmount = computed.itbisAmount;
    final total = computed.total;

    await _db.upsertCotizacion(
      row: {
        'id': id,
        'empresa_id': empresaId,
        'numero': 'BORRADOR',
        'status': status,
        'customer_id': customerId,
        'customer_name': (customerName ?? '').toString(),
        'customer_phone': null,
        'customer_email': null,
        'itbis_enabled': itbisEnabled ? 1 : 0,
        'itbis_rate': itbisRate,
        'subtotal': subtotal,
        'itbis_amount': itbisAmount,
        'total': total,
        'notes': notes,
        'created_by_user_id': session.user.id,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      },
    );

    await _db.replaceCotizacionItems(
      quotationId: id,
      items: computed.items
          .map((row) {
            final patched = <String, Object?>{...row};
            patched['quotation_id'] = id;
            return patched;
          })
          .toList(growable: false),
    );

    return (await _db.getCotizacion(id: id))!;
  }

  _LocalTotals _computeLocalTotals(List<Map<String, dynamic>> rawItems) {
    // Accept both legacy keys (name/quantity/price/total) and server keys
    // (nombre/cantidad/unit_price/line_total).
    final itbisEnabled = rawItems.isNotEmpty;
    final itbisRate = 0.18;

    double subtotal = 0;
    final now = DateTime.now().toIso8601String();
    final items = <Map<String, Object?>>[];

    for (final raw in rawItems) {
      final id = (raw['id'] ?? _localId()).toString();
      final productId = raw['product_id'] ?? raw['productId'];

      final nombre = (raw['nombre'] ?? raw['name'] ?? '').toString();

      final cantidadRaw =
          (raw['cantidad'] ?? raw['quantity'] ?? raw['qty'] ?? 1);
      final unitPriceRaw =
          (raw['unit_price'] ?? raw['unitPrice'] ?? raw['price'] ?? 0);
      final unitCostRaw = (raw['unit_cost'] ?? raw['unitCost'] ?? 0);

      final cantidad = cantidadRaw is num
          ? cantidadRaw.toDouble()
          : double.tryParse(cantidadRaw.toString()) ?? 0;
      final unitPrice = unitPriceRaw is num
          ? unitPriceRaw.toDouble()
          : double.tryParse(unitPriceRaw.toString()) ?? 0;
      final unitCost = unitCostRaw is num
          ? unitCostRaw.toDouble()
          : double.tryParse(unitCostRaw.toString()) ?? 0;

      final discountPctRaw = raw['discount_pct'] ?? raw['discountPct'] ?? 0;
      final discountPct = discountPctRaw is num
          ? discountPctRaw.toDouble()
          : double.tryParse(discountPctRaw.toString()) ?? 0;

      final lineSubtotal = round2(cantidad * unitPrice);
      final discountAmount = round2(lineSubtotal * (discountPct / 100));
      final lineTotal = round2(lineSubtotal - discountAmount);

      subtotal = round2(subtotal + lineTotal);

      items.add({
        'id': id,
        // quotation_id is filled by replaceCotizacionItems caller
        'quotation_id': raw['quotation_id']?.toString() ?? '',
        'product_id': productId?.toString(),
        'nombre': nombre.isEmpty ? 'Item' : nombre,
        'cantidad': cantidad,
        'unit_cost': unitCost,
        'unit_price': unitPrice,
        'discount_pct': discountPct,
        'discount_amount': discountAmount,
        'line_subtotal': lineSubtotal,
        'line_total': lineTotal,
        'created_at': (raw['created_at'] ?? raw['createdAt'] ?? now).toString(),
      });
    }

    final itbisAmount = itbisEnabled ? round2(subtotal * itbisRate) : 0.0;
    final total = round2(subtotal + itbisAmount);

    return _LocalTotals(
      items: items,
      subtotal: subtotal,
      itbisEnabled: itbisEnabled,
      itbisRate: itbisRate,
      itbisAmount: itbisAmount,
      total: total,
    );
  }

  double round2(num n) => (n * 100).roundToDouble() / 100;

  /// Pulls from server and upserts into local DB.
  Future<void> refreshFromServer({
    required String empresaId,
    required String userId,
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
        row: _mapServerQuotationToLocal(
          qItem,
          empresaId: empresaId,
          userId: userId,
        ),
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
    required String userId,
  }) async {
    final created = await _api.duplicateQuotation(quotationId);
    await _db.upsertCotizacion(
      row: _mapServerQuotationToLocal(
        created,
        empresaId: empresaId,
        userId: userId,
      ),
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
    // - remove locally so it disappears from lists
    // - try remote delete
    // - if remote fails due to connectivity, enqueue for later
    await _db.deleteCotizacion(id: quotationId);
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

  Future<Map<String, dynamic>> convertToTicket(String quotationId) async {
    return await _api.convertToTicket(quotationId);
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
    final userId = session.user.id;

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
          final itbisEnabled =
              (remote['itbis_enabled'] ?? remote['itbisEnabled']);
          base['itbis_enabled'] = (itbisEnabled == true || itbisEnabled == 1)
              ? 1
              : (base['itbis_enabled'] ?? 1);
          base['itbis_rate'] = _asDouble(
            remote['itbis_rate'] ?? remote['itbisRate'] ?? base['itbis_rate'],
            fallback: 0.18,
          );
          base['subtotal'] = _asDouble(
            remote['subtotal'] ?? base['subtotal'],
            fallback: 0,
          );
          base['itbis_amount'] = _asDouble(
            remote['itbis_amount'] ??
                remote['itbisAmount'] ??
                base['itbis_amount'],
            fallback: 0,
          );
          base['total'] = _asDouble(
            remote['total'] ?? base['total'],
            fallback: 0,
          );
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
          base['created_by_user_id'] = base['created_by_user_id'] ?? userId;
          base['sync_status'] = 'synced';
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
    required String userId,
  }) {
    final itbisEnabled = q['itbis_enabled'] ?? q['itbisEnabled'] ?? true;
    final itbisRate = q['itbis_rate'] ?? q['itbisRate'] ?? 0.18;
    final itbisAmount = q['itbis_amount'] ?? q['itbisAmount'] ?? 0;

    return {
      'id': q['id'],
      'empresa_id': empresaId,
      'numero': q['numero']?.toString() ?? '',
      'status': q['status']?.toString() ?? 'draft',
      'customer_id': q['customerId'] ?? q['customer_id'],
      'customer_name': q['customerName'] ?? q['customer_name'],
      'customer_phone': q['customerPhone'] ?? q['customer_phone'],
      'customer_email': q['customerEmail'] ?? q['customer_email'],
      'itbis_enabled': (itbisEnabled == true || itbisEnabled == 1) ? 1 : 0,
      'itbis_rate': _asDouble(itbisRate, fallback: 0.18),
      'subtotal': _asDouble(q['subtotal'], fallback: 0.0),
      'itbis_amount': _asDouble(itbisAmount, fallback: 0.0),
      'total': _asDouble(q['total'], fallback: 0.0),
      'notes': q['notes'],
      'created_at':
          q['createdAt'] ?? q['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at':
          q['updatedAt'] ?? q['updated_at'] ?? DateTime.now().toIso8601String(),
      'created_by_user_id':
          q['created_by_user_id'] ?? q['createdByUserId'] ?? userId,
      'sync_status': 'synced',
    };
  }

  Map<String, dynamic> _mapServerItemToLocal(
    Map<String, dynamic> it, {
    required String cotizacionId,
  }) {
    final createdAt =
        (it['created_at'] ??
                it['createdAt'] ??
                DateTime.now().toIso8601String())
            .toString();
    return {
      'id': it['id'],
      'quotation_id': cotizacionId,
      'product_id': it['productId'] ?? it['product_id'],
      'nombre': (it['nombre'] ?? it['name'] ?? '').toString(),
      'cantidad': (it['cantidad'] is num)
          ? (it['cantidad'] as num).toDouble()
          : double.tryParse('${it['cantidad'] ?? it['quantity']}') ?? 0.0,
      'unit_cost': (it['unit_cost'] is num)
          ? (it['unit_cost'] as num).toDouble()
          : double.tryParse('${it['unit_cost'] ?? it['unitCost'] ?? 0}') ?? 0.0,
      'unit_price': (it['unit_price'] is num)
          ? (it['unit_price'] as num).toDouble()
          : double.tryParse('${it['unit_price'] ?? it['unitPrice'] ?? 0}') ??
                0.0,
      'discount_pct': (it['discount_pct'] is num)
          ? (it['discount_pct'] as num).toDouble()
          : double.tryParse(
                  '${it['discount_pct'] ?? it['discountPct'] ?? 0}',
                ) ??
                0.0,
      'discount_amount': (it['discount_amount'] is num)
          ? (it['discount_amount'] as num).toDouble()
          : double.tryParse(
                  '${it['discount_amount'] ?? it['discountAmount'] ?? 0}',
                ) ??
                0.0,
      'line_subtotal': (it['line_subtotal'] is num)
          ? (it['line_subtotal'] as num).toDouble()
          : double.tryParse(
                  '${it['line_subtotal'] ?? it['lineSubtotal'] ?? 0}',
                ) ??
                0.0,
      'line_total': (it['line_total'] is num)
          ? (it['line_total'] as num).toDouble()
          : double.tryParse(
                  '${it['line_total'] ?? it['lineTotal'] ?? it['total'] ?? 0}',
                ) ??
                0.0,
      'created_at': createdAt,
    };
  }
}

class _LocalTotals {
  final List<Map<String, Object?>> items;
  final double subtotal;
  final bool itbisEnabled;
  final double itbisRate;
  final double itbisAmount;
  final double total;

  _LocalTotals({
    required this.items,
    required this.subtotal,
    required this.itbisEnabled,
    required this.itbisRate,
    required this.itbisAmount,
    required this.total,
  });
}
