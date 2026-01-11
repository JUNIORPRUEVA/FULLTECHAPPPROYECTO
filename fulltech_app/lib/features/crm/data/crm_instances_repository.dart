import 'package:dio/dio.dart';
import '../models/crm_instance.dart';

class CrmInstancesRepository {
  final Dio _dio;

  CrmInstancesRepository(this._dio);

  // ======================================
  // Instance CRUD
  // ======================================

  Future<List<CrmInstance>> listInstances() async {
    final response = await _dio.get('/crm/instances');
    final items = response.data['items'] as List;
    return items.map((json) => CrmInstance.fromJson(json)).toList();
  }

  Future<CrmInstance?> getActiveInstance() async {
    final response = await _dio.get('/crm/instances/active');
    final item = response.data['item'];
    return item != null ? CrmInstance.fromJson(item) : null;
  }

  Future<CrmInstance> getInstance(String id) async {
    final response = await _dio.get('/crm/instances/$id');
    return CrmInstance.fromJson(response.data['item']);
  }

  Future<CrmInstance> createInstance({
    required String nombreInstancia,
    required String evolutionBaseUrl,
    required String evolutionApiKey,
  }) async {
    final response = await _dio.post(
      '/crm/instances',
      data: {
        'nombre_instancia': nombreInstancia,
        'evolution_base_url': evolutionBaseUrl,
        'evolution_api_key': evolutionApiKey,
      },
    );
    return CrmInstance.fromJson(response.data['item']);
  }

  Future<CrmInstance> updateInstance(
    String id, {
    String? nombreInstancia,
    String? evolutionBaseUrl,
    String? evolutionApiKey,
    bool? isActive,
  }) async {
    final response = await _dio.patch(
      '/crm/instances/$id',
      data: {
        if (nombreInstancia != null) 'nombre_instancia': nombreInstancia,
        if (evolutionBaseUrl != null) 'evolution_base_url': evolutionBaseUrl,
        if (evolutionApiKey != null) 'evolution_api_key': evolutionApiKey,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return CrmInstance.fromJson(response.data['item']);
  }

  Future<void> deleteInstance(String id) async {
    await _dio.delete('/crm/instances/$id');
  }

  Future<Map<String, dynamic>> testConnection({
    required String nombreInstancia,
    required String evolutionBaseUrl,
    required String evolutionApiKey,
  }) async {
    final response = await _dio.post(
      '/crm/instances/test-connection',
      data: {
        'nombre_instancia': nombreInstancia,
        'evolution_base_url': evolutionBaseUrl,
        'evolution_api_key': evolutionApiKey,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ======================================
  // Chat Transfer
  // ======================================

  Future<List<CrmTransferUser>> listUsersForTransfer() async {
    final response = await _dio.get('/crm/users/transfer-list');
    final items = response.data['items'] as List;
    return items.map((json) => CrmTransferUser.fromJson(json)).toList();
  }

  Future<void> transferChat({
    required String chatId,
    required String toUserId,
    String? toInstanceId,
    String? notes,
  }) async {
    await _dio.post(
      '/crm/chats/$chatId/transfer',
      data: {
        'toUserId': toUserId,
        if (toInstanceId != null) 'toInstanceId': toInstanceId,
        if (notes != null) 'notes': notes,
      },
    );
  }
}
