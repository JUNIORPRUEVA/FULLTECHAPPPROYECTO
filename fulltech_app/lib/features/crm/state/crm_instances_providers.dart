import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/state/auth_providers.dart';
import '../data/crm_instances_repository.dart';
import '../models/crm_instance.dart';

// ======================================
// Repository Provider
// ======================================

final crmInstancesRepositoryProvider = Provider<CrmInstancesRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return CrmInstancesRepository(dio);
});

// ======================================
// Instances List Provider
// ======================================

final crmInstancesListProvider = FutureProvider.autoDispose<List<CrmInstance>>((
  ref,
) async {
  final repo = ref.watch(crmInstancesRepositoryProvider);
  return await repo.listInstances();
});

// ======================================
// Active Instance Provider
// ======================================

final crmActiveInstanceProvider = FutureProvider.autoDispose<CrmInstance?>((
  ref,
) async {
  final repo = ref.watch(crmInstancesRepositoryProvider);
  return await repo.getActiveInstance();
});

// ======================================
// Transfer Users Provider
// ======================================

final crmTransferUsersProvider =
    FutureProvider.autoDispose<List<CrmTransferUser>>((ref) async {
      final repo = ref.watch(crmInstancesRepositoryProvider);
      return await repo.listUsersForTransfer();
    });

// ======================================
// Create Instance Action
// ======================================

final createCrmInstanceProvider =
    Provider.autoDispose<
      Future<CrmInstance> Function({
        required String nombreInstancia,
        required String evolutionBaseUrl,
        required String evolutionApiKey,
      })
    >((ref) {
      return ({
        required String nombreInstancia,
        required String evolutionBaseUrl,
        required String evolutionApiKey,
      }) async {
        final repo = ref.read(crmInstancesRepositoryProvider);
        return await repo.createInstance(
          nombreInstancia: nombreInstancia,
          evolutionBaseUrl: evolutionBaseUrl,
          evolutionApiKey: evolutionApiKey,
        );
      };
    });

// ======================================
// Update Instance Action
// ======================================

final updateCrmInstanceProvider =
    Provider.autoDispose<
      Future<CrmInstance> Function(
        String id, {
        String? nombreInstancia,
        String? evolutionBaseUrl,
        String? evolutionApiKey,
        bool? isActive,
      })
    >((ref) {
      return (
        String id, {
        String? nombreInstancia,
        String? evolutionBaseUrl,
        String? evolutionApiKey,
        bool? isActive,
      }) async {
        final repo = ref.read(crmInstancesRepositoryProvider);
        return await repo.updateInstance(
          id,
          nombreInstancia: nombreInstancia,
          evolutionBaseUrl: evolutionBaseUrl,
          evolutionApiKey: evolutionApiKey,
          isActive: isActive,
        );
      };
    });

// ======================================
// Test Connection Action
// ======================================

final testCrmConnectionProvider =
    Provider.autoDispose<
      Future<Map<String, dynamic>> Function({
        required String nombreInstancia,
        required String evolutionBaseUrl,
        required String evolutionApiKey,
      })
    >((ref) {
      return ({
        required String nombreInstancia,
        required String evolutionBaseUrl,
        required String evolutionApiKey,
      }) async {
        final repo = ref.read(crmInstancesRepositoryProvider);
        return await repo.testConnection(
          nombreInstancia: nombreInstancia,
          evolutionBaseUrl: evolutionBaseUrl,
          evolutionApiKey: evolutionApiKey,
        );
      };
    });

// ======================================
// Transfer Chat Action
// ======================================

final transferChatProvider =
    Provider.autoDispose<
      Future<void> Function({
        required String chatId,
        required String toUserId,
        String? toInstanceId,
        String? notes,
      })
    >((ref) {
      return ({
        required String chatId,
        required String toUserId,
        String? toInstanceId,
        String? notes,
      }) async {
        final repo = ref.read(crmInstancesRepositoryProvider);
        await repo.transferChat(
          chatId: chatId,
          toUserId: toUserId,
          toInstanceId: toInstanceId,
          notes: notes,
        );
      };
    });
