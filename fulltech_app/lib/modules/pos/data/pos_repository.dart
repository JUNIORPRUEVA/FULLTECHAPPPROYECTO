import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/services/offline_http_queue.dart';
import '../../../core/storage/local_db_interface.dart';
import '../models/pos_models.dart';
import 'pos_api.dart';

class PosRepository {
  PosRepository({required PosApi api, required LocalDb db})
      : _api = api,
        _db = db;

  final PosApi _api;
  final LocalDb _db;

  static const _syncModule = 'pos';
  static const _opCheckout = 'checkout';

  Future<String> _productStore() async {
    final session = await _db.readSession();
    final empresaId = session?.user.empresaId;
    return empresaId == null || empresaId.trim().isEmpty
        ? 'pos_products'
        : 'pos_products_${empresaId.trim()}';
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

        final created = await _api.createSale(salePayload.cast<String, dynamic>());
        final createdData = (created['data'] as Map).cast<String, dynamic>();
        final saleId = (createdData['id'] ?? '').toString();
        if (saleId.trim().isEmpty) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        await _api.paySale(saleId, payPayload.cast<String, dynamic>());
        await _db.markSyncItemSent(item.id);
      } on DioException catch (e) {
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
      if (supplierId != null && supplierId.trim().isNotEmpty) 'supplier_id': supplierId,
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
    final rows = await _api.listMovements(productId: productId, from: from, to: to);
    return rows.map(PosStockMovement.fromJson).toList();
  }

  Future<void> adjustStock({
    required String productId,
    required double qtyChange,
    String? note,
  }) async {
    await _api.adjustInventory(productId: productId, qtyChange: qtyChange, note: note);
  }

  Future<List<PosCreditAccountRow>> listCredit({String? status, String? search}) async {
    final rows = await _api.listCredit(status: status, search: search);
    return rows.map(PosCreditAccountRow.fromJson).toList();
  }

  Future<({PosSale sale, Map<String, dynamic> credit})> getCreditDetail(String id) async {
    final res = await _api.getCredit(id);
    final data = (res['data'] as Map).cast<String, dynamic>();
    final sale = PosSale.fromJson((data['sale'] as Map).cast<String, dynamic>());
    final credit = (data['credit'] as Map).cast<String, dynamic>();
    return (sale: sale, credit: credit);
  }

  Future<({double total, int count, double avgTicket})> salesSummary({DateTime? from, DateTime? to}) async {
    final res = await _api.salesSummary(from: from, to: to);
    final data = (res['data'] as Map).cast<String, dynamic>();
    return (
      total: (data['total'] as num?)?.toDouble() ?? 0,
      count: (data['count'] as num?)?.toInt() ?? 0,
      avgTicket: (data['avg_ticket'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> topProducts({DateTime? from, DateTime? to}) async {
    return _api.topProducts(from: from, to: to);
  }

  Future<List<Map<String, dynamic>>> lowStock() async {
    return _api.lowStockReport();
  }

  Future<({double total, int count})> purchasesSummary({DateTime? from, DateTime? to}) async {
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
