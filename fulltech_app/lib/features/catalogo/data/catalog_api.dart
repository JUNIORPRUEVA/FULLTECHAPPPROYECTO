import 'package:dio/dio.dart';

import '../models/categoria_producto.dart';
import '../models/producto.dart';

class CatalogApi {
  final Dio _dio;

  CatalogApi(this._dio);

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

        final details = data['details'];
        if (details is Map<String, dynamic>) {
          // Common Zod shape: { fieldErrors: { field: [msg] } }
          final fieldErrors = details['fieldErrors'];
          if (fieldErrors is Map<String, dynamic>) {
            final firstKey = fieldErrors.keys.cast<String?>().firstWhere(
                  (k) => k != null,
                  orElse: () => null,
                );
            if (firstKey != null) {
              final v = fieldErrors[firstKey];
              if (v is List && v.isNotEmpty) {
                message = '${message} (${firstKey}: ${v.first})';
              }
            }
          }
        }
      }

      final prefix = status != null ? 'HTTP $status' : 'HTTP error';
      throw Exception('$prefix: $message');
    }

    throw error;
  }

  Future<List<CategoriaProducto>> listCategorias({bool includeInactive = false}) async {
    try {
      final res = await _dio.get(
        '/catalog/categories',
        queryParameters: {
          if (includeInactive) 'include_inactive': 'true',
        },
      );

      final items = (res.data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      return items.map(CategoriaProducto.fromJson).toList();
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<CategoriaProducto> createCategoria({required String nombre, String? descripcion}) async {
    try {
      final res = await _dio.post(
        '/catalog/categories',
        data: {
          'nombre': nombre,
          if (descripcion != null && descripcion.trim().isNotEmpty) 'descripcion': descripcion.trim(),
        },
      );

      return CategoriaProducto.fromJson(res.data['item'] as Map<String, dynamic>);
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<List<Producto>> listProductos({
    String? q,
    String? categoryId,
    int? page,
    int? limit,
    String? order,
    double? minPrice,
    double? maxPrice,
    String? productType,
    bool includeInactive = false,
  }) async {
    try {
      final res = await _dio.get(
        '/catalog/products',
        queryParameters: {
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (categoryId != null && categoryId.trim().isNotEmpty) 'category_id': categoryId.trim(),
          if (page != null && page > 0) 'page': page,
          if (limit != null && limit > 0) 'limit': limit,
          if (order != null && order.trim().isNotEmpty) 'order': order.trim(),
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (productType != null && productType.trim().isNotEmpty) 'product_type': productType.trim(),
          if (includeInactive) 'include_inactive': 'true',
        },
      );

      final items = (res.data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      return items.map(Producto.fromJson).toList();
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<Producto> createProducto({
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required String imagenUrl,
    required String categoriaId,
  }) async {
    try {
      final res = await _dio.post(
        '/catalog/products',
        data: {
          'nombre': nombre,
          'product_type': 'simple',
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'imagen_url': imagenUrl,
          'categoria_id': categoriaId,
        },
      );

      return Producto.fromJson(res.data['item'] as Map<String, dynamic>);
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<Producto> updateProducto({
    required String id,
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required String imagenUrl,
    required String categoriaId,
  }) async {
    try {
      final res = await _dio.put(
        '/catalog/products/$id',
        data: {
          'nombre': nombre,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'imagen_url': imagenUrl,
          'categoria_id': categoriaId,
        },
      );

      return Producto.fromJson(res.data['item'] as Map<String, dynamic>);
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<void> deleteProducto(String id) async {
    try {
      await _dio.delete('/catalog/products/$id');
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<void> incrementSearch(String id) async {
    try {
      await _dio.post('/catalog/products/$id/increment-search');
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }

  Future<String> uploadProductImage({required String filePath}) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final res = await _dio.post(
        '/uploads/products',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return res.data['url'] as String;
    } catch (e) {
      _rethrowAsFriendly(e);
    }
  }
}
