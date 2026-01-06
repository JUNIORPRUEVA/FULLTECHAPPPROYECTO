import 'package:dio/dio.dart';

class PosApi {
  PosApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listProducts({
    String? search,
    bool lowStock = false,
    String? categoryId,
  }) async {
    final res = await _dio.get(
      '/pos/products',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (lowStock) 'lowStock': 'true',
        if (categoryId != null && categoryId.trim().isNotEmpty) 'categoryId': categoryId,
      },
      options: Options(extra: {'offlineCache': true}),
    );

    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/pos/sales',
      data: payload,
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> paySale(String saleId, Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/pos/sales/$saleId/pay',
      data: payload,
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> cancelSale(String saleId) async {
    final res = await _dio.post(
      '/pos/sales/$saleId/cancel',
      data: {},
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> nextNcf(String docType) async {
    final res = await _dio.post(
      '/pos/fiscal/next-ncf',
      data: {'doc_type': docType},
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> listPurchases({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get(
      '/pos/purchases',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/pos/purchases',
      data: payload,
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> receivePurchase(String purchaseId) async {
    final res = await _dio.post(
      '/pos/purchases/$purchaseId/receive',
      data: {},
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> listMovements({
    String? productId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get(
      '/pos/inventory/movements',
      queryParameters: {
        if (productId != null && productId.trim().isNotEmpty) 'product_id': productId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> adjustInventory({
    required String productId,
    required double qtyChange,
    String? note,
  }) async {
    final res = await _dio.post(
      '/pos/inventory/adjust',
      data: {
        'product_id': productId,
        'qty_change': qtyChange,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      options: Options(extra: {'offlineQueue': false}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> listCredit({
    String? status,
    String? search,
  }) async {
    final res = await _dio.get(
      '/pos/credit',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getCredit(String id) async {
    final res = await _dio.get(
      '/pos/credit/$id',
      options: Options(extra: {'offlineCache': true}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> salesSummary({DateTime? from, DateTime? to}) async {
    final res = await _dio.get(
      '/pos/reports/sales-summary',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> topProducts({DateTime? from, DateTime? to}) async {
    final res = await _dio.get(
      '/pos/reports/top-products',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> lowStockReport() async {
    final res = await _dio.get(
      '/pos/reports/inventory-low-stock',
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> purchasesSummary({DateTime? from, DateTime? to}) async {
    final res = await _dio.get(
      '/pos/reports/purchases-summary',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      options: Options(extra: {'offlineCache': true}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> creditAging() async {
    final res = await _dio.get(
      '/pos/reports/credit-aging',
      options: Options(extra: {'offlineCache': true}),
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['data'] as List?)?.cast<Map>() ?? const [];
    return items.map((e) => e.cast<String, dynamic>()).toList();
  }
}
