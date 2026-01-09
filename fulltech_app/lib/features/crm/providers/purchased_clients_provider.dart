import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/purchased_clients_remote_datasource.dart';
import '../data/models/purchased_client.dart';
import '../state/crm_providers.dart';

// Datasource provider
final purchasedClientsDataSourceProvider =
    Provider<PurchasedClientsRemoteDatasource>((ref) {
      final dio = ref.watch(crmApiClientProvider).dio;
      return PurchasedClientsRemoteDatasource(dio);
    });

// State classes
class PurchasedClientsState {
  final List<PurchasedClient> clients;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int totalClients;
  final int currentPage;
  final bool hasMorePages;

  const PurchasedClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.totalClients = 0,
    this.currentPage = 1,
    this.hasMorePages = false,
  });

  PurchasedClientsState copyWith({
    List<PurchasedClient>? clients,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? totalClients,
    int? currentPage,
    bool? hasMorePages,
  }) {
    return PurchasedClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      totalClients: totalClients ?? this.totalClients,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

// Controller class
class PurchasedClientsController extends StateNotifier<PurchasedClientsState> {
  final PurchasedClientsRemoteDatasource _dataSource;

  PurchasedClientsController(this._dataSource)
    : super(const PurchasedClientsState());

  Future<void> loadClients({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        clients: [],
      );
    } else if (state.isLoading) {
      return; // Already loading
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _dataSource.getPurchasedClients(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: refresh ? 1 : state.currentPage,
        limit: 30,
      );

      final newClients = refresh
          ? response.items
          : [...state.clients, ...response.items];

      state = state.copyWith(
        clients: newClients,
        isLoading: false,
        totalClients: response.total,
        currentPage: refresh ? 1 : state.currentPage,
        hasMorePages: response.hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMorePages || state.isLoading) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadClients();
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadClients(refresh: true);
  }

  Future<void> refresh() async {
    await loadClients(refresh: true);
  }

  Future<void> updateClient(
    String clientId, {
    String? displayName,
    String? phone,
    String? note,
    String? assignedUserId,
    String? productId,
  }) async {
    try {
      await _dataSource.updatePurchasedClient(
        clientId,
        displayName: displayName,
        phone: phone,
        note: note,
        assignedUserId: assignedUserId,
        productId: productId,
      );

      // Refresh the list to get updated data
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> deleteClient(
    String clientId, {
    bool hardDelete = false,
  }) async {
    try {
      final message = await _dataSource.deletePurchasedClient(
        clientId,
        hardDelete: hardDelete,
      );

      // Remove from local state
      final updatedClients = state.clients
          .where((c) => c.id != clientId)
          .toList();
      state = state.copyWith(
        clients: updatedClients,
        totalClients: state.totalClients - 1,
      );

      return message;
    } catch (e) {
      rethrow;
    }
  }
}

// Controller provider
final purchasedClientsControllerProvider =
    StateNotifierProvider<PurchasedClientsController, PurchasedClientsState>((
      ref,
    ) {
      final dataSource = ref.read(purchasedClientsDataSourceProvider);
      return PurchasedClientsController(dataSource);
    });

// Individual client detail provider
final purchasedClientDetailProvider =
    FutureProvider.family<PurchasedClient, String>((ref, clientId) async {
      final dataSource = ref.read(purchasedClientsDataSourceProvider);
      return dataSource.getPurchasedClient(clientId);
    });
