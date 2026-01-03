import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/app_config.dart';
import '../data/datasources/crm_remote_datasource.dart';
import '../data/datasources/customers_remote_datasource.dart';
import '../data/repositories/crm_repository.dart';
import '../data/repositories/customers_repository.dart';
import 'crm_messages_controller.dart';
import 'crm_messages_state.dart';
import 'crm_threads_controller.dart';
import 'crm_threads_state.dart';
import 'customer_detail_controller.dart';
import 'customer_detail_state.dart';
import 'customers_controller.dart';
import 'customers_state.dart';

final crmApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.forBaseUrl(ref.watch(localDbProvider), AppConfig.crmApiBaseUrl);
});

final crmRemoteDataSourceProvider = Provider<CrmRemoteDataSource>((ref) {
  return CrmRemoteDataSource(ref.watch(crmApiClientProvider).dio);
});

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository(ref.watch(crmRemoteDataSourceProvider));
});

final crmThreadsControllerProvider =
    StateNotifierProvider<CrmThreadsController, CrmThreadsState>((ref) {
  return CrmThreadsController(repo: ref.watch(crmRepositoryProvider));
});

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);

final crmMessagesControllerProvider = StateNotifierProvider.family<
    CrmMessagesController,
    CrmMessagesState,
    String>((ref, threadId) {
  return CrmMessagesController(
    repo: ref.watch(crmRepositoryProvider),
    threadId: threadId,
  );
});

final customersRemoteDataSourceProvider = Provider<CustomersRemoteDataSource>((ref) {
  return CustomersRemoteDataSource(ref.watch(crmApiClientProvider).dio);
});

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(customersRemoteDataSourceProvider));
});

final customersControllerProvider =
    StateNotifierProvider<CustomersController, CustomersState>((ref) {
  return CustomersController(repo: ref.watch(customersRepositoryProvider));
});

final customerDetailControllerProvider = StateNotifierProvider.family<
    CustomerDetailController,
    CustomerDetailState,
    String>((ref, customerId) {
  return CustomerDetailController(
    repo: ref.watch(customersRepositoryProvider),
    customerId: customerId,
  );
});
