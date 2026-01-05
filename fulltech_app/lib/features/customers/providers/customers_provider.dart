import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/providers/dio_provider.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';
import 'package:fulltech_app/features/customers/data/models/customer_response.dart';
import 'package:fulltech_app/features/customers/data/repositories/customers_repository.dart';

/// Repository provider
final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomersRepository(dio);
});

/// State for customer list
class CustomersState {
  final List<CustomerItem> customers;
  final CustomerStats? stats;
  final bool isLoading;
  final String? error;

  // Filters
  final String searchQuery;
  final List<String> selectedTags;
  final String? selectedProductId;
  final String? selectedStatus;

  CustomersState({
    this.customers = const [],
    this.stats,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedTags = const [],
    this.selectedProductId,
    this.selectedStatus,
  });

  CustomersState copyWith({
    List<CustomerItem>? customers,
    CustomerStats? stats,
    bool? isLoading,
    String? error,
    String? searchQuery,
    List<String>? selectedTags,
    String? selectedProductId,
    String? selectedStatus,
    bool clearError = false,
    bool clearStats = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      stats: clearStats ? null : (stats ?? this.stats),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

/// Controller
class CustomersController extends StateNotifier<CustomersState> {
  final CustomersRepository _repository;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  CustomersController(this._repository) : super(CustomersState());

  @override
  void dispose() {
    _debouncer.dispose();
    _repository.cancelRequests();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.getCustomers(
        q: state.searchQuery.isEmpty ? null : state.searchQuery,
        tags: state.selectedTags.isEmpty ? null : state.selectedTags,
        productId: state.selectedProductId,
        status: state.selectedStatus,
        limit: 100,
      );

      state = state.copyWith(
        customers: response.items,
        stats: response.stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error cargando clientes: ${e.toString()}',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debouncer.run(() => loadCustomers());
  }

  void setSelectedTags(List<String> tags) {
    state = state.copyWith(selectedTags: tags);
    _debouncer.run(() => loadCustomers());
  }

  void setSelectedStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
    _debouncer.run(() => loadCustomers());
  }

  void setSelectedProduct(String? productId) {
    state = state.copyWith(selectedProductId: productId);
    _debouncer.run(() => loadCustomers());
  }

  void clearFilters() {
    state = CustomersState();
    loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      state = state.copyWith(
        error: 'Error eliminando cliente: ${e.toString()}',
      );
    }
  }
}

/// Provider
final customersControllerProvider =
    StateNotifierProvider<CustomersController, CustomersState>((ref) {
      final repository = ref.watch(customersRepositoryProvider);
      return CustomersController(repository);
    });

/// Customer detail provider
final customerDetailProvider =
    FutureProvider.family<CustomerDetailResponse, String>((ref, id) async {
      final repository = ref.watch(customersRepositoryProvider);
      return await repository.getCustomer(id);
    });

/// Product lookup provider
final productLookupProvider =
    FutureProvider.family<List<ProductLookupItem>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final repository = ref.watch(customersRepositoryProvider);
      return await repository.lookupProducts(query);
    });
