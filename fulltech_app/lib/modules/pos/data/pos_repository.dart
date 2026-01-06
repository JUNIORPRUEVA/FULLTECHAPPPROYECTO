import '../../core/storage/local_db.dart';
import '../models/pos_models.dart';
import 'pos_api.dart';

class PosRepository {
  PosRepository({required PosApi api, required LocalDb db})
      : _api = api,
        _db = db;

  final PosApi _api;
  final LocalDb _db;

  Future<List<PosProduct>> listProducts({
    String? search,
    bool lowStock = false,
    String? categoryId,
  }) async {
    final rows = await _api.listProducts(
      search: search,
      lowStock: lowStock,
      categoryId: categoryId,
    );

    return rows.map(PosProduct.fromJson).toList();
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

  Future<PosPurchaseOrder> createPurchase({
    required String supplierName,
    required List<({PosProduct product, double qty, double unitCost})> items,
  }) async {
    final payload = {
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
