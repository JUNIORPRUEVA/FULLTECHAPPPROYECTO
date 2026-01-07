import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db.dart';
import '../../../core/services/offline_http_queue.dart';
import '../data/catalog_api.dart';
import '../models/categoria_producto.dart';
import '../models/producto.dart';
import 'catalog_state.dart';

class CatalogController extends StateNotifier<CatalogState> {
  final CatalogApi _api;
  final LocalDb _db;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  static const _storeCategorias = 'catalog_categories';
  static const _storeProductos = 'catalog_products';

  static const _uuid = Uuid();

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return OfflineHttpQueue.isNetworkError(e);
  }

  CatalogController({
    required CatalogApi api,
    required LocalDb db,
  })  : _api = api,
        _db = db,
        super(CatalogState.initial());

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    // Set initial state.
    final initial = await Connectivity().checkConnectivity();
    final online = initial.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(isOnline: online, error: null);

    _connSub ??= Connectivity().onConnectivityChanged.listen((results) {
      final nextOnline = results.any((r) => r != ConnectivityResult.none);
      if (nextOnline == state.isOnline) return;
      state = state.copyWith(isOnline: nextOnline, error: null);
      if (nextOnline) {
        // Best-effort refresh when connection returns.
        unawaited(loadCategorias());
        unawaited(loadProductos());
      }
    });
  }

  Future<List<CategoriaProducto>> _readCachedCategorias() async {
    final rows = await _db.listEntitiesJson(store: _storeCategorias);
    return rows
        .map((s) => CategoriaProducto.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<List<Producto>> _readCachedProductos() async {
    final rows = await _db.listEntitiesJson(store: _storeProductos);
    return rows.map((s) => Producto.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> _cacheCategorias(List<CategoriaProducto> categorias) async {
    await _db.clearStore(store: _storeCategorias);
    for (final c in categorias) {
      await _db.upsertEntity(store: _storeCategorias, id: c.id, json: jsonEncode(c.toJson()));
    }
  }

  Future<void> _cacheProductos(List<Producto> productos) async {
    await _db.clearStore(store: _storeProductos);
    for (final p in productos) {
      await _db.upsertEntity(store: _storeProductos, id: p.id, json: jsonEncode(p.toJson()));
    }
  }

  List<Producto> _applyProductFilters(List<Producto> all) {
    Iterable<Producto> items = all;

    final q = state.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((p) => p.nombre.toLowerCase().contains(q));
    }

    final categoryId = state.selectedCategoriaId?.trim();
    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((p) => p.categoriaId == categoryId);
    }

    if (!state.includeInactive) {
      items = items.where((p) => p.isActive);
    }

    return items.toList();
  }

  Future<void> bootstrap() async {
    await _initConnectivity();

    // Load cached snapshots first for instant UI (offline-first reads).
    try {
      final cachedCats = await _readCachedCategorias();
      final cachedProds = await _readCachedProductos();
      state = state.copyWith(
        categorias: cachedCats,
        productos: _applyProductFilters(cachedProds),
        error: null,
      );
    } catch (_) {
      // Ignore cache errors; fall back to network.
    }

    await Future.wait([
      loadCategorias(),
      loadProductos(),
    ]);
  }

  Future<void> loadCategorias() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cached = await _readCachedCategorias();
      if (cached.isNotEmpty) {
        state = state.copyWith(categorias: cached, error: null);
      }

      if (!state.isOnline) {
        state = state.copyWith(isLoading: false, error: null);
        return;
      }

      final categorias = await _api.listCategorias(includeInactive: true);
      await _cacheCategorias(categorias);
      state = state.copyWith(isLoading: false, categorias: categorias, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadProductos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cachedAll = await _readCachedProductos();
      if (cachedAll.isNotEmpty) {
        state = state.copyWith(productos: _applyProductFilters(cachedAll), error: null);
      }

      if (!state.isOnline) {
        state = state.copyWith(isLoading: false, error: null);
        return;
      }

      final productos = await _api.listProductos(
        q: state.query,
        categoryId: state.selectedCategoriaId,
        includeInactive: state.includeInactive,
      );
      await _cacheProductos(productos);
      state = state.copyWith(isLoading: false, productos: productos, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value, error: null);
  }

  void setCategoria(String? categoriaId) {
    state = state.copyWith(selectedCategoriaId: categoriaId, error: null);
  }

  void setIncludeInactive(bool value) {
    state = state.copyWith(includeInactive: value, error: null);
  }

  Future<CategoriaProducto?> createCategoria({required String nombre, String? descripcion}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categoria = await _api.createCategoria(nombre: nombre, descripcion: descripcion);
      final updated = [...state.categorias, categoria]..sort((a, b) => a.nombre.compareTo(b.nombre));
      await _cacheCategorias(updated);
      state = state.copyWith(isLoading: false, categorias: updated, error: null);
      return categoria;
    } catch (e) {
      if (!_isNetworkError(e) || state.isOnline) {
        state = state.copyWith(isLoading: false, error: e.toString());
        return null;
      }

      // Offline-first: create locally + queue the request.
      final localId = _uuid.v4();
      final local = CategoriaProducto(
        id: localId,
        nombre: nombre,
        descripcion: (descripcion?.trim().isEmpty ?? true) ? null : descripcion!.trim(),
        isActive: true,
      );

      final updated = [...state.categorias, local]..sort((a, b) => a.nombre.compareTo(b.nombre));
      await _cacheCategorias(updated);

      await OfflineHttpQueue.enqueue(
        _db,
        method: 'POST',
        path: '/catalog/categories',
        data: {
          'id': localId,
          'nombre': local.nombre,
          if (local.descripcion != null) 'descripcion': local.descripcion,
        },
      );

      state = state.copyWith(isLoading: false, categorias: updated, error: null);
      return local;
    }
  }

  Future<Producto?> createProducto({
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required String imagenUrl,
    required String categoriaId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final producto = await _api.createProducto(
        nombre: nombre,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        imagenUrl: imagenUrl,
        categoriaId: categoriaId,
      );
      state = state.copyWith(isLoading: false, error: null);
      await loadProductos();
      return producto;
    } catch (e) {
      if (!_isNetworkError(e) || state.isOnline) {
        state = state.copyWith(isLoading: false, error: e.toString());
        return null;
      }

      final localId = _uuid.v4();
      final local = Producto(
        id: localId,
        nombre: nombre,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        imagenUrl: imagenUrl,
        categoriaId: categoriaId,
        categoria: state.categorias.firstWhere(
          (c) => c.id == categoriaId,
          orElse: () => CategoriaProducto(id: categoriaId, nombre: '', descripcion: null, isActive: true),
        ),
        searchCount: 0,
        isActive: true,
      );

      final cachedAll = await _readCachedProductos();
      final nextAll = [...cachedAll, local];
      await _cacheProductos(nextAll);

      await OfflineHttpQueue.enqueue(
        _db,
        method: 'POST',
        path: '/catalog/products',
        data: {
          'id': localId,
          'nombre': local.nombre,
          'product_type': 'simple',
          'precio_compra': local.precioCompra,
          'precio_venta': local.precioVenta,
          'imagen_url': local.imagenUrl,
          'categoria_id': local.categoriaId,
        },
      );

      state = state.copyWith(
        isLoading: false,
        productos: _applyProductFilters(nextAll),
        error: null,
      );
      return local;
    }
  }

  Future<Producto?> updateProducto({
    required String id,
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required String imagenUrl,
    required String categoriaId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final cachedAllBefore = await _readCachedProductos();
    final previousImageUrl = cachedAllBefore
        .where((p) => p.id == id)
        .map((p) => p.imagenUrl)
        .cast<String?>()
        .firstWhere(
          (v) => v != null,
          orElse: () => null,
        );
    try {
      final producto = await _api.updateProducto(
        id: id,
        nombre: nombre,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        imagenUrl: imagenUrl,
        categoriaId: categoriaId,
      );

      // Best-effort cleanup: if image changed, delete the previous uploaded product image.
      if (previousImageUrl != null && previousImageUrl.trim().isNotEmpty) {
        final prev = previousImageUrl.trim();
        final next = imagenUrl.trim();
        if (prev != next) {
          try {
            await _api.deleteUploadedProductImageByUrl(prev);
          } catch (_) {}
        }
      }

      state = state.copyWith(isLoading: false, error: null);
      await loadProductos();
      return producto;
    } catch (e) {
      if (!_isNetworkError(e) || state.isOnline) {
        state = state.copyWith(isLoading: false, error: e.toString());
        return null;
      }

      final cachedAll = await _readCachedProductos();
      final nextAll = cachedAll
          .map((p) => p.id == id
              ? Producto(
                  id: id,
                  nombre: nombre,
                  precioCompra: precioCompra,
                  precioVenta: precioVenta,
                  imagenUrl: imagenUrl,
                  categoriaId: categoriaId,
                  categoria: state.categorias.firstWhere(
                    (c) => c.id == categoriaId,
                    orElse: () => CategoriaProducto(id: categoriaId, nombre: '', descripcion: null, isActive: true),
                  ),
                  searchCount: p.searchCount,
                  isActive: p.isActive,
                )
              : p)
          .toList();

      await _cacheProductos(nextAll);
      await OfflineHttpQueue.enqueue(
        _db,
        method: 'PUT',
        path: '/catalog/products/$id',
        data: {
          'nombre': nombre,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'imagen_url': imagenUrl,
          'categoria_id': categoriaId,
        },
      );

      state = state.copyWith(isLoading: false, productos: _applyProductFilters(nextAll), error: null);
      return nextAll.firstWhere((p) => p.id == id, orElse: () => localFromInputs(id));
    }
  }

  Producto localFromInputs(String id) {
    return Producto(
      id: id,
      nombre: '',
      precioCompra: 0,
      precioVenta: 0,
      imagenUrl: '',
      categoriaId: '',
      categoria: null,
      searchCount: 0,
      isActive: true,
    );
  }

  Future<bool> deleteProducto(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Best-effort cleanup: delete uploaded image before removing the record.
      try {
        final cachedAll = await _readCachedProductos();
        final imageUrl = cachedAll
            .where((p) => p.id == id)
            .map((p) => p.imagenUrl)
            .cast<String?>()
            .firstWhere((v) => v != null, orElse: () => null);
        if (imageUrl != null && imageUrl.trim().isNotEmpty) {
          await _api.deleteUploadedProductImageByUrl(imageUrl);
        }
      } catch (_) {}

      await _api.deleteProducto(id);
      state = state.copyWith(isLoading: false, error: null);
      await loadProductos();
      return true;
    } catch (e) {
      if (!_isNetworkError(e) || state.isOnline) {
        state = state.copyWith(isLoading: false, error: e.toString());
        return false;
      }

      final cachedAll = await _readCachedProductos();
      final nextAll = cachedAll.where((p) => p.id != id).toList();
      await _cacheProductos(nextAll);

      await OfflineHttpQueue.enqueue(
        _db,
        method: 'DELETE',
        path: '/catalog/products/$id',
      );

      state = state.copyWith(isLoading: false, productos: _applyProductFilters(nextAll), error: null);
      return true;
    }
  }

  Future<void> incrementSearch(String id) async {
    try {
      await _api.incrementSearch(id);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<String?> uploadProductImage(String filePath) async {
    state = state.copyWith(error: null);
    try {
      final url = await _api.uploadProductImage(filePath: filePath);
      return url;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}
