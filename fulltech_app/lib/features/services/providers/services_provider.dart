import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/network_info.dart';
import '../../auth/state/auth_providers.dart';
import '../data/datasources/services_local_datasource.dart';
import '../data/datasources/services_remote_datasource.dart';
import '../data/models/service_model.dart';
import '../data/repositories/services_repository.dart';

// Datasources
final servicesLocalDatasourceProvider = Provider<ServicesLocalDatasource>((
  ref,
) {
  final localDb = ref.watch(localDbProvider);
  return ServicesLocalDatasource(localDb);
});

final servicesRemoteDatasourceProvider = Provider<ServicesRemoteDatasource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ServicesRemoteDatasource(apiClient);
});

// Network Info
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

// Repository
final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(
    localDatasource: ref.watch(servicesLocalDatasourceProvider),
    remoteDatasource: ref.watch(servicesRemoteDatasourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    localDb: ref.watch(localDbProvider),
  );
});

// Services list provider
final servicesListProvider = FutureProvider.autoDispose<List<ServiceModel>>((
  ref,
) async {
  final repository = ref.watch(servicesRepositoryProvider);
  return await repository.getServices();
});

// Active services only
final activeServicesProvider = FutureProvider.autoDispose<List<ServiceModel>>((
  ref,
) async {
  final repository = ref.watch(servicesRepositoryProvider);
  return await repository.getServices(isActive: true);
});

// Services list state provider (for manual refresh)
final servicesListStateProvider =
    StateNotifierProvider<ServicesListNotifier, AsyncValue<List<ServiceModel>>>(
      (ref) {
        return ServicesListNotifier(ref);
      },
    );

class ServicesListNotifier
    extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final Ref _ref;

  ServicesListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadServices();
  }

  Future<void> loadServices({bool forceRemote = false}) async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(servicesRepositoryProvider);
      final services = await repository.getServices(forceRemote: forceRemote);
      state = AsyncValue.data(services);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadServices(forceRemote: true);
  }
}

// Service detail provider
final serviceDetailProvider = FutureProvider.autoDispose
    .family<ServiceModel?, String>((ref, id) async {
      final repository = ref.watch(servicesRepositoryProvider);
      return await repository.getServiceById(id);
    });

// Search services
final servicesSearchProvider = FutureProvider.autoDispose
    .family<List<ServiceModel>, String>((ref, query) async {
      if (query.isEmpty) {
        final repository = ref.watch(servicesRepositoryProvider);
        return await repository.getServices();
      }
      final repository = ref.watch(servicesRepositoryProvider);
      return await repository.searchServices(query);
    });
