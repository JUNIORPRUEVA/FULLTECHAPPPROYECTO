import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/services/offline_http_queue.dart';
import '../../../core/storage/local_db_interface.dart';
import '../models/pos_models.dart';
import '../models/pos_ticket.dart';
import 'pos_api.dart';

class PosRepository {
  PosRepository({required PosApi api, required LocalDb db})
    : _api = api,
      _db = db;

  final PosApi _api;
  final LocalDb _db;

  static const _syncModule = 'pos';
  static const _opCheckout = 'checkout';

  static const _tpvStore = 'pos_tpv';
  static const _tpvStateId = 'tpv_state';

  Future<String> _productStore() async {
    final session = await _db.readSession();
    final empresaId = session?.user.empresaId;
    return empresaId == null || empresaId.trim().isEmpty
        ? 'pos_products'
        : 'pos_products_${empresaId.trim()}';
  }

  Future<String> _tpvTicketsStore() async {
    final session = await _db.readSession();
    final empresaId = session?.user.empresaId;
    return empresaId == null || empresaId.trim().isEmpty
        ? _tpvStore
        : '${_tpvStore}_${empresaId.trim()}';
  }

  Future<void> saveTpvTickets(List<PosTicket> tickets, String activeTicketId) async {
    final store = await _tpvTicketsStore();
    final payload = {
      'active_ticket_id': activeTicketId,
      'tickets': tickets.map((t) => t.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _db.upsertEntity(store: store, id: _tpvStateId, json: jsonEncode(payload));
  }

  Future<({List<PosTicket> tickets, String activeTicketId})?> loadTpvTickets() async {
    final store = await _tpvTicketsStore();
    final raw = await _db.getEntityJson(store: store, id: _tpvStateId);
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final m = decoded.cast<String, dynamic>();

    final ticketsJson = (m['tickets'] as List?)?.cast<Map>() ?? const [];
    final tickets = ticketsJson
        .map((e) => PosTicket.fromJson(e.cast<String, dynamic>()))
        .where((t) => t.id.trim().isNotEmpty)
        .toList();

    final active = (m['active_ticket_id'] ?? '').toString();
    if (tickets.isEmpty) return null;
    return (tickets: tickets, activeTicketId: active);
  }

  Future<List<PosProduct>> _readCachedProducts() async {
    final store = await _productStore();
    final rows = await _db.listEntitiesJson(store: store);
    return rows
        .map((j) => jsonDecode(j))
        .whereType<Map>()
        .map((m) => PosProduct.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> _cacheProducts(List<PosProduct> items) async {
    final store = await _productStore();
    for (final p in items) {
      await _db.upsertEntity(
        store: store,
        id: p.id,
        json: jsonEncode(p.toJson()),
      );
    }
  }

  Future<List<PosProduct>> listProducts({
    String? search,
    bool lowStock = false,
    String? categoryId,
  }) async {
    try {
      final rows = await _api.listProducts(
        search: search,
        lowStock: lowStock,
        categoryId: categoryId,
      );

      final items = rows.map(PosProduct.fromJson).toList();
      await _cacheProducts(items);
      return items;
    } catch (e) {
      // Fallback to local cached snapshot.
      return _readCachedProducts();
    }
  }

  /// Loads all POS products from the cloud (catalog table) using pagination.
  ///
  /// This is used by TPV to populate the GridView with all products.
  Future<List<PosProduct>> listAllProducts({
    String? search,
    bool lowStock = false,
    String? categoryId,
  }) async {
    const take = 500;
    const hardCap = 10000; // safety cap

    final all = <PosProduct>[];
    var skip = 0;

    try {
      while (true) {
        final rows = await _api.listProducts(
          search: search,
          lowStock: lowStock,
          categoryId: categoryId,
          take: take,
          skip: skip,
        );
        final page = rows.map(PosProduct.fromJson).toList();
        if (page.isNotEmpty) {
          all.addAll(page);
          await _cacheProducts(page);
        }

        if (page.length < take) break;
        skip += take;
        if (skip >= hardCap) break;
      }

      return all;
    } catch (e) {
      // If the network fails, return the cached snapshot.
      return _readCachedProducts();
    }
  }

  Future<void> queueOfflineCheckout({
    required String invoiceType,
    String? customerId,
    String? customerName,
    String? customerRnc,
    required List<PosSaleItemDraft> items,
    required String paymentMethod,
    required double paidAmount,
    double? receivedAmount,
    String? dueDateIso,
    double initialPayment = 0,
    double discountTotal = 0,
    String? note,
    String? docType,
  }) async {
    final entityId = 'checkout_${DateTime.now().microsecondsSinceEpoch}';

    final payload = {
      'sale': {
        'invoice_type': invoiceType,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_rnc': customerRnc,
        'discount_total': discountTotal,
        'note': note,
        'items': items
            .map(
              (it) => {
                'product_id': it.product.id,
                'qty': it.qty,
                'unit_price': it.unitPrice,
                'discount_amount': it.discountAmount,
              },
            )
            .toList(),
      },
      'payment': {
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        if (receivedAmount != null) 'received_amount': receivedAmount,
        if (dueDateIso != null) 'due_date': dueDateIso,
        'initial_payment': initialPayment,
        if (note != null) 'note': note,
        if (docType != null) 'doc_type': docType,
        if (customerRnc != null) 'customer_rnc': customerRnc,
      },
    };

    await _db.enqueueSync(
      module: _syncModule,
      op: _opCheckout,
      entityId: entityId,
      payloadJson: jsonEncode(payload),
    );
  }

  /// Flushes pending POS outbox items.
  ///
  /// Used by global AutoSync to upload offline checkouts once online.
  Future<void> syncPending() async {
    // CRITICAL: Verify session exists before attempting any sync
    final session = await _db.readSession();
    if (session == null) return;

    final items = await _db.getPendingSyncItems();

    for (final item in items) {
      if (item.module != _syncModule || item.op != _opCheckout) continue;

      try {
        final decoded = jsonDecode(item.payloadJson);
        if (decoded is! Map<String, dynamic>) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        final salePayload = decoded['sale'];
        final payPayload = decoded['payment'];
        if (salePayload is! Map || payPayload is! Map) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        final created = await _api.createSale(
          salePayload.cast<String, dynamic>(),
        );
        final createdData = (created['data'] as Map).cast<String, dynamic>();
        final saleId = (createdData['id'] ?? '').toString();
        if (saleId.trim().isEmpty) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        await _api.paySale(saleId, payPayload.cast<String, dynamic>());
        await _db.markSyncItemSent(item.id);
      } on DioException catch (e) {
        // CRITICAL: Stop retry loop on 401
        if (e.response?.statusCode == 401) {
          await _db.markSyncItemSent(item.id);
          return;
        }
        await _db.markSyncItemError(item.id);
        if (OfflineHttpQueue.isNetworkError(e)) return;
      } catch (e) {
        await _db.markSyncItemError(item.id);
        if (OfflineHttpQueue.isNetworkError(e)) return;
      }
    }
  }

  Future<PosSale> createSale({
    required String invoiceType,
    String? customerId,
    String? customerName,
    String? customerRnc,
    required List<PosSaleItemDraft> items,
    double discountTotal = 0,
    String? note,
  }) async {
    final payload = {
      'invoice_type': invoiceType,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_rnc': customerRnc,
      'discount_total': discountTotal,
      'note': note,
      'items': items
          .map(
            (it) => {
              'product_id': it.product.id,
              'qty': it.qty,
              'unit_price': it.unitPrice,
              'discount_amount': it.discountAmount,
            },
          )
          .toList(),
    };

    final res = await _api.createSale(payload);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosSale.fromJson(data);
  }

  Future<PosSale> paySale({
    required String saleId,
    required String paymentMethod,
    required double paidAmount,
    double? receivedAmount,
    String? dueDateIso,
    double initialPayment = 0,
    String? note,
    String? docType,
    String? customerRnc,
  }) async {
    final payload = {
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      if (receivedAmount != null) 'received_amount': receivedAmount,
      if (dueDateIso != null) 'due_date': dueDateIso,
      'initial_payment': initialPayment,
      'note': note,
      if (docType != null) 'doc_type': docType,
      if (customerRnc != null) 'customer_rnc': customerRnc,
    };

    final res = await _api.paySale(saleId, payload);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosSale.fromJson(data);
  }

  // === Clientes (customers) ===

  Future<Map<String, dynamic>?> findCustomerByPhone(String phone) async {
    final q = phone.trim();
    if (q.isEmpty) return null;

    final res = await _api.listCustomers(q: q, limit: 50);
    final items = (res['items'] as List?)?.cast<Map>() ?? const [];
    Map<String, dynamic>? exact;
    for (final it in items) {
      final m = it.cast<String, dynamic>();
      final t = (m['telefono'] ?? '').toString().trim();
      if (t == q) {
        exact = m;
        break;
      }
    }
    return exact;
  }

  Future<Map<String, dynamic>> createCustomer({
    required String nombre,
    required String telefono,
    String? direccion,
    String? nota,
    List<String>? tags,
  }) async {
    final payload = {
      'nombre': nombre.trim(),
      'telefono': telefono.trim(),
      if (direccion != null && direccion.trim().isNotEmpty) 'direccion': direccion.trim(),
      if (nota != null && nota.trim().isNotEmpty) 'notas': nota.trim(),
      if (tags != null) 'tags': tags,
      'origen': 'tpv',
    };
    return _api.createCustomer(payload);
  }

  Future<Map<String, dynamic>> patchCustomer(String id, Map<String, dynamic> patch) async {
    return _api.patchCustomer(id, patch);
  }

  Future<Map<String, dynamic>> getCustomer(String id) async {
    return _api.getCustomer(id);
  }

  Future<void> markCustomerAsBought(String customerId) async {
    final current = await getCustomer(customerId);
    final tags = ((current['tags'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((s) => s.trim().isNotEmpty)
        .toSet();

    tags.add('compro');
    tags.remove('en_espera');

    await patchCustomer(customerId, {'tags': tags.toList()});
  }

  // === NCF / Comprobantes fiscales ===

  Future<List<Map<String, dynamic>>> listNcfSequences() async {
    final res = await _api.listNcfSequences();
    final items = (res['items'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> createNcfSequence(Map<String, dynamic> payload) async {
    return _api.createNcfSequence(payload);
  }

  Future<Map<String, dynamic>> updateNcfSequence(String id, Map<String, dynamic> payload) async {
    return _api.updateNcfSequence(id, payload);
  }

  Future<void> deleteNcfSequence(String id) async {
    await _api.deleteNcfSequence(id);
  }

  Future<List<PosPurchaseOrder>> listPurchases({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _api.listPurchases(status: status, from: from, to: to);
    return rows.map(PosPurchaseOrder.fromJson).toList();
  }

  Future<List<PosSupplier>> listSuppliers({String? search}) async {
    final rows = await _api.listSuppliers(search: search);
    return rows.map(PosSupplier.fromJson).toList();
  }

  Future<PosSupplier> createSupplier({
    required String name,
    String? phone,
    String? rnc,
    String? email,
    String? address,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
      'rnc': rnc,
      'email': email,
      'address': address,
    };

    final res = await _api.createSupplier(payload);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosSupplier.fromJson(data);
  }

  Future<PosSupplier> updateSupplier(
    String id, {
    String? name,
    String? phone,
    String? rnc,
    String? email,
    String? address,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (rnc != null) 'rnc': rnc,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
    };

    final res = await _api.updateSupplier(id, payload);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosSupplier.fromJson(data);
  }

  Future<void> deleteSupplier(String id) async {
    await _api.deleteSupplier(id);
  }

  Future<PosPurchaseOrder> createPurchase({
    String? supplierId,
    required String supplierName,
    required List<({PosProduct product, double qty, double unitCost})> items,
  }) async {
    final payload = {
      if (supplierId != null && supplierId.trim().isNotEmpty)
        'supplier_id': supplierId,
      'supplier_name': supplierName,
      'status': 'DRAFT',
      'items': items
          .map(
            (it) => {
              'product_id': it.product.id,
              'qty': it.qty,
              'unit_cost': it.unitCost,
            },
          )
          .toList(),
    };

    final res = await _api.createPurchase(payload);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosPurchaseOrder.fromJson(data);
  }

  Future<PosPurchaseOrder> receivePurchase(String id) async {
    final res = await _api.receivePurchase(id);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosPurchaseOrder.fromJson(data);
  }

  Future<PosPurchaseOrder> getPurchase(String id) async {
    final res = await _api.getPurchase(id);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return PosPurchaseOrder.fromJson(data);
  }

  Future<List<PosStockMovement>> listMovements({
    String? productId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _api.listMovements(
      productId: productId,
      from: from,
      to: to,
    );
    return rows.map(PosStockMovement.fromJson).toList();
  }

  Future<void> adjustStock({
    required String productId,
    required double qtyChange,
    String? note,
  }) async {
    await _api.adjustInventory(
      productId: productId,
      qtyChange: qtyChange,
      note: note,
    );
  }

  Future<List<PosCreditAccountRow>> listCredit({
    String? status,
    String? search,
  }) async {
    final rows = await _api.listCredit(status: status, search: search);
    return rows.map(PosCreditAccountRow.fromJson).toList();
  }

  Future<({PosSale sale, Map<String, dynamic> credit})> getCreditDetail(
    String id,
  ) async {
    final res = await _api.getCredit(id);
    final data = (res['data'] as Map).cast<String, dynamic>();
    final sale = PosSale.fromJson(
      (data['sale'] as Map).cast<String, dynamic>(),
    );
    final credit = (data['credit'] as Map).cast<String, dynamic>();
    return (sale: sale, credit: credit);
  }

  Future<({double total, int count, double avgTicket})> salesSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _api.salesSummary(from: from, to: to);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return (
      total: (data['total'] as num?)?.toDouble() ?? 0,
      count: (data['count'] as num?)?.toInt() ?? 0,
      avgTicket: (data['avg_ticket'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> topProducts({
    DateTime? from,
    DateTime? to,
  }) async {
    return _api.topProducts(from: from, to: to);
  }

  Future<List<Map<String, dynamic>>> lowStock() async {
    return _api.lowStockReport();
  }

  Future<({double total, int count})> purchasesSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _api.purchasesSummary(from: from, to: to);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return (
      total: (data['total'] as num?)?.toDouble() ?? 0,
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> creditAging() async {
    return _api.creditAging();
  }

  Future<String?> currentEmpresaId() async {
    final session = await _db.readSession();
    return session?.user.empresaId;
  }
}
