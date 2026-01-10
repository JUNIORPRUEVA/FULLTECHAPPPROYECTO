import '../models/inventory_product.dart';
import 'inventory_api.dart';

class InventoryRepository {
  final InventoryApi api;
  const InventoryRepository({required this.api});

  Future<InventoryProductsPage> listProducts({
    String? search,
    String? categoryId,
    String? brand,
    String? supplierId,
    String status = 'all',
    String sort = 'updated',
    int page = 1,
    int pageSize = 25,
  }) {
    return api.listProducts(
      search: search,
      categoryId: categoryId,
      brand: brand,
      supplierId: supplierId,
      status: status,
      sort: sort,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<InventoryProduct>> searchProducts(String q) async {
    final page = await api.listProducts(search: q, page: 1, pageSize: 25);
    return page.items;
  }

  Future<List<Map<String, dynamic>>> listSuppliers({String? search}) {
    return api.listSuppliers(search: search);
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
  }) {
    return api.addStock(
      productId: productId,
      qty: qty,
      refType: refType,
      refId: refId,
      note: note,
      supplierId: supplierId,
      unitCost: unitCost,
      updatePurchasePrice: updatePurchasePrice,
    );
  }

  Future<void> adjustStock({
    required String productId,
    required double qtyChange,
    String? note,
    String? refId,
  }) {
    return api.adjustStock(
      productId: productId,
      qtyChange: qtyChange,
      note: note,
      refId: refId,
    );
  }

  Future<void> updateMinMax(
    String productId, {
    required double minStock,
    required double maxStock,
    String? brand,
    bool includeBrand = false,
    String? supplierId,
    bool includeSupplier = false,
  }) {
    return api.updateMinMax(
      productId,
      minStock: minStock,
      maxStock: maxStock,
      brand: brand,
      includeBrand: includeBrand,
      supplierId: supplierId,
      includeSupplier: includeSupplier,
    );
  }

  Future<InventoryKardexResult> kardex(
    String productId, {
    DateTime? from,
    DateTime? to,
    String? type,
  }) {
    return api.getKardex(productId, from: from, to: to, type: type);
  }
}
