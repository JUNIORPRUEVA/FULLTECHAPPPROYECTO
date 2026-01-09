import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/utils/debouncer.dart';
import '../../catalogo/models/producto.dart';
import '../../catalogo/state/catalog_providers.dart';
import '../../auth/state/auth_providers.dart';
import '../data/datasources/maintenance_remote_datasource.dart';
import '../data/repositories/maintenance_repository.dart';
import '../data/models/maintenance_models.dart';

String _friendlyError(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 404) return 'Servicio no disponible.';
    if (code == 401 || code == 403) {
      return 'Sesión no válida. Vuelve a iniciar.';
    }
    return 'No se pudo conectar al servidor.';
  }
  return 'Ocurrió un error.';
}

final maintenanceProductsProvider = FutureProvider<List<Producto>>((ref) async {
  return ref.watch(catalogApiProvider).listProductos();
});

// DataSource
final maintenanceRemoteDataSourceProvider =
    Provider<MaintenanceRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);
      return MaintenanceRemoteDataSource(dio);
    });

// Repository
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final remoteDataSource = ref.watch(maintenanceRemoteDataSourceProvider);
  final db = ref.watch(localDbProvider);
  return MaintenanceRepository(remoteDataSource, db);
});

// === MAINTENANCE STATE ===

class MaintenanceState {
  final List<MaintenanceRecord> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  MaintenanceState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  MaintenanceState copyWith({
    List<MaintenanceRecord>? items,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return MaintenanceState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class MaintenanceController extends StateNotifier<MaintenanceState> {
  final MaintenanceRepository repository;
  final Debouncer _debouncer = Debouncer(delay: Duration(milliseconds: 400));
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _connectivityInitialized = false;

  // Filters
  String? searchQuery;
  ProductHealthStatus? statusFilter;
  String? productoIdFilter;
  String? fromDate;
  String? toDate;

  MaintenanceController(this.repository) : super(MaintenanceState());

  @override
  void dispose() {
    _debouncer.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivityIfNeeded() async {
    if (_connectivityInitialized) return;
    _connectivityInitialized = true;

    final initial = await Connectivity().checkConnectivity();
    final online = initial.any((r) => r != ConnectivityResult.none);
    if (online) {
      // Best-effort: try to push pending local maintenance items.
      // ignore: unawaited_futures
      repository.syncPending();
    }

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nextOnline = results.any((r) => r != ConnectivityResult.none);
      if (!nextOnline) return;

      // When connection returns: push queue, then refresh list.
      // ignore: unawaited_futures
      repository.syncPending().whenComplete(() {
        // ignore: unawaited_futures
        loadMaintenance(reset: true);
      });
    });
  }

  Future<void> loadMaintenance({bool reset = false}) async {
    await _initConnectivityIfNeeded();
    if (reset) {
      state = MaintenanceState(isLoading: true, currentPage: 1);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = reset ? 1 : state.currentPage;
      final response = await repository.listMaintenance(
        search: searchQuery,
        status: statusFilter,
        productoId: productoIdFilter,
        from: fromDate,
        to: toDate,
        page: page,
        limit: 50,
      );

      // Always include local pending items (offline-first create)
      final localPending = await repository.listLocalPendingMaintenance(
        search: searchQuery,
        status: statusFilter,
        productoId: productoIdFilter,
        from: fromDate,
        to: toDate,
      );

      final merged = <MaintenanceRecord>[];
      final seen = <String>{};
      for (final r in localPending) {
        if (seen.add(r.id)) merged.add(r);
      }
      for (final r in response.items) {
        if (seen.add(r.id)) merged.add(r);
      }

      final newItems = reset ? merged : [...state.items, ...merged];

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: page < response.totalPages,
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> createMaintenance(CreateMaintenanceDto dto) async {
    try {
      await repository.createMaintenance(dto);
      await loadMaintenance(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  Future<void> updateMaintenance(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await repository.updateMaintenance(id, updates);
      await loadMaintenance(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  Future<void> deleteMaintenance(String id) async {
    try {
      await repository.deleteMaintenance(id);
      await loadMaintenance(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  void setSearch(String? query) {
    searchQuery = query;
    _debouncer.run(() => loadMaintenance(reset: true));
  }

  void setStatusFilter(ProductHealthStatus? status) {
    statusFilter = status;
    loadMaintenance(reset: true);
  }

  void setProductoFilter(String? productoId) {
    productoIdFilter = productoId;
    loadMaintenance(reset: true);
  }

  void setDateRange(String? from, String? to) {
    fromDate = from;
    toDate = to;
    loadMaintenance(reset: true);
  }

  void clearFilters() {
    searchQuery = null;
    statusFilter = null;
    productoIdFilter = null;
    fromDate = null;
    toDate = null;
    loadMaintenance(reset: true);
  }

  void loadMore() {
    if (!state.isLoading && state.hasMore) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadMaintenance();
    }
  }
}

final maintenanceControllerProvider =
    StateNotifierProvider<MaintenanceController, MaintenanceState>((ref) {
      final repository = ref.watch(maintenanceRepositoryProvider);
      return MaintenanceController(repository);
    });

// === WARRANTY STATE ===

class WarrantyState {
  final List<WarrantyCase> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  WarrantyState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  WarrantyState copyWith({
    List<WarrantyCase>? items,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return WarrantyState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class WarrantyController extends StateNotifier<WarrantyState> {
  final MaintenanceRepository repository;
  final Debouncer _debouncer = Debouncer(delay: Duration(milliseconds: 400));

  String? searchQuery;
  WarrantyStatus? statusFilter;
  String? productoIdFilter;
  String? fromDate;
  String? toDate;

  WarrantyController(this.repository) : super(WarrantyState());

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> loadWarranty({bool reset = false}) async {
    if (reset) {
      state = WarrantyState(isLoading: true, currentPage: 1);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = reset ? 1 : state.currentPage;
      final response = await repository.listWarranty(
        search: searchQuery,
        status: statusFilter,
        productoId: productoIdFilter,
        from: fromDate,
        to: toDate,
        page: page,
        limit: 50,
      );

      final newItems = reset
          ? response.items
          : [...state.items, ...response.items];

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: page < response.totalPages,
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> createWarranty(CreateWarrantyDto dto) async {
    try {
      await repository.createWarranty(dto);
      await loadWarranty(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  Future<void> updateWarranty(String id, Map<String, dynamic> updates) async {
    try {
      await repository.updateWarranty(id, updates);
      await loadWarranty(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  Future<void> deleteWarranty(String id) async {
    try {
      await repository.deleteWarranty(id);
      await loadWarranty(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  void setSearch(String? query) {
    searchQuery = query;
    _debouncer.run(() => loadWarranty(reset: true));
  }

  void setStatusFilter(WarrantyStatus? status) {
    statusFilter = status;
    loadWarranty(reset: true);
  }

  void setProductoFilter(String? productoId) {
    productoIdFilter = productoId;
    loadWarranty(reset: true);
  }

  void setDateRange(String? from, String? to) {
    fromDate = from;
    toDate = to;
    loadWarranty(reset: true);
  }

  void clearFilters() {
    searchQuery = null;
    statusFilter = null;
    productoIdFilter = null;
    fromDate = null;
    toDate = null;
    loadWarranty(reset: true);
  }

  void loadMore() {
    if (!state.isLoading && state.hasMore) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadWarranty();
    }
  }
}

final warrantyControllerProvider =
    StateNotifierProvider<WarrantyController, WarrantyState>((ref) {
      final repository = ref.watch(maintenanceRepositoryProvider);
      return WarrantyController(repository);
    });

// === AUDITS STATE ===

class AuditsState {
  final List<InventoryAudit> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  AuditsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  AuditsState copyWith({
    List<InventoryAudit>? items,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return AuditsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class AuditsController extends StateNotifier<AuditsState> {
  final MaintenanceRepository repository;

  String? fromDate;
  String? toDate;
  AuditStatus? statusFilter;

  AuditsController(this.repository) : super(AuditsState());

  Future<void> loadAudits({bool reset = false}) async {
    if (reset) {
      state = AuditsState(isLoading: true, currentPage: 1);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = reset ? 1 : state.currentPage;
      final response = await repository.listAudits(
        from: fromDate,
        to: toDate,
        status: statusFilter,
        page: page,
        limit: 50,
      );

      final newItems = reset
          ? response.items
          : [...state.items, ...response.items];

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: page < response.totalPages,
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> createAudit(CreateAuditDto dto) async {
    try {
      await repository.createAudit(dto);
      await loadAudits(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  Future<void> updateAudit(String id, Map<String, dynamic> updates) async {
    try {
      await repository.updateAudit(id, updates);
      await loadAudits(reset: true);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  void setStatusFilter(AuditStatus? status) {
    statusFilter = status;
    loadAudits(reset: true);
  }

  void setDateRange(String? from, String? to) {
    fromDate = from;
    toDate = to;
    loadAudits(reset: true);
  }

  void clearFilters() {
    fromDate = null;
    toDate = null;
    statusFilter = null;
    loadAudits(reset: true);
  }

  void loadMore() {
    if (!state.isLoading && state.hasMore) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadAudits();
    }
  }
}

final auditsControllerProvider =
    StateNotifierProvider<AuditsController, AuditsState>((ref) {
      final repository = ref.watch(maintenanceRepositoryProvider);
      return AuditsController(repository);
    });

// === SUMMARY PROVIDER ===

final maintenanceSummaryProvider = FutureProvider<MaintenanceSummary>((
  ref,
) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getSummary();
});
