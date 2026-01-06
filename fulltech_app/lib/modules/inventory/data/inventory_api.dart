import 'package:dio/dio.dart';

import '../models/inventory_movement.dart';
import '../models/inventory_product.dart';
import '../models/inventory_summary.dart';

class InventoryProductsPage {
  final List<InventoryProduct> items;
  final int total;
  final int page;
  final int pageSize;
  final InventorySummary? summary;

  const InventoryProductsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.summary,
  });
}

class InventoryKardexResult {
  final Map<String, dynamic> product;
  final List<InventoryMovement> movements;

  const InventoryKardexResult({
    required this.product,
    required this.movements,
  });
}

class InventoryApi {
  InventoryApi(this._dio);
  final Dio _dio;

  Never _rethrowAsFriendly(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = error.message ?? 'Network error';
      if (data is Map<String, dynamic>) {
        final serverMsg = (data['error'] ?? data['message'])?.toString();
        if (serverMsg != null && serverMsg.trim().isNotEmpty) {
          message = serverMsg.trim();
        }
      }

      final prefix = status != null ? 'HTTP $status' : 'HTTP error';
      throw Exception('$prefix: $message');
    }
    throw error;
  }

  Future<InventoryProductsPage> listProducts({
    String? search,
    String? categoryId,
    String? brand,
    String? supplierId,
    String status = 'all',
    String sort = 'updated',
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final res = await _dio.get(
        '/inventory/products',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (categoryId != null && categoryId.trim().isNotEmpty) 'category_id': categoryId.trim(),
          if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
          if (supplierId != null && supplierId.trim().isNotEmpty) 'supplier_id': supplierId.trim(),
          if (status.trim().isNotEmpty) 'status': status,
          if (sort.trim().isNotEmpty) 'sort': sort,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final root = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? const {};

      final itemsRaw = (data['items'] as List?)?.cast<Map>() ?? const [];
      final items = itemsRaw
          .map((e) => InventoryProduct.fromJson(e.cast<String, dynamic>()))
          .toList();

      final summaryRaw = data['summary'];
      final summary = summaryRaw is Map<String, dynamic>
          ? InventorySummary.fromJson(summaryRaw)
          : null;

      return InventoryProductsPage(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? 0,
        page: (data['page'] as num?)?.toInt() ?? page,
        pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
        summary: summary,
      );
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<InventoryKardexResult> getKardex(
    String productId, {
    DateTime? from,
    DateTime? to,
    String? type,
  }) async {
    try {
      final res = await _dio.get(
        '/inventory/products/$productId/kardex',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        },
      );

      final root = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      final product =
          (data['product'] as Map?)?.cast<String, dynamic>() ?? const {};
      final movementsRaw = (data['movements'] as List?)?.cast<Map>() ?? const [];

      return InventoryKardexResult(
        product: product,
        movements: movementsRaw
            .map((e) => InventoryMovement.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<List<Map<String, dynamic>>> listSuppliers({String? search}) async {
    try {
      final res = await _dio.get(
        'pos/suppliers',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final root = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      final items = (root['data'] as List?)?.cast<Map>() ?? const [];
      return items.map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<void> addStock({
    required String productId,
    required double qty,
    required String refType,
    String? refId,
    String? note,
    String? supplierId,
    double? unitCost,
    bool updatePurchasePrice = false,
  }) async {
    try {
      await _dio.post(
        '/inventory/add-stock',
        data: {
          'product_id': productId,
          'qty': qty,
          'ref_type': refType,
          if (refId != null && refId.trim().isNotEmpty) 'ref_id': refId.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (supplierId != null && supplierId.trim().isNotEmpty)
            'supplier_id': supplierId.trim(),
          if (unitCost != null) 'unit_cost': unitCost,
          if (updatePurchasePrice) 'update_purchase_price': true,
        },
        options: Options(extra: {'offlineQueue': false}),
      );
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<void> adjustStock({
    required String productId,
    required double qtyChange,
    String? note,
    String? refId,
  }) async {
    try {
      await _dio.post(
        '/inventory/adjust-stock',
        data: {
          'product_id': productId,
          'qty_change': qtyChange,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (refId != null && refId.trim().isNotEmpty) 'ref_id': refId.trim(),
        },
        options: Options(extra: {'offlineQueue': false}),
      );
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<void> updateMinMax(
    String productId, {
    required double minStock,
    required double maxStock,
    String? brand,
    String? supplierId,
  }) async {
    try {
      await _dio.put(
        '/inventory/products/$productId/minmax',
        data: {
          'min_stock': minStock,
          'max_stock': maxStock,
          if (brand != null) 'brand': brand,
          if (supplierId != null) 'supplier_id': supplierId,
        },
        options: Options(extra: {'offlineQueue': false}),
      );
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }
}
