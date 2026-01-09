import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/purchased_client.dart';

class PurchasedClientsRemoteDatasource {
  final Dio _dio;

  PurchasedClientsRemoteDatasource(this._dio);

  dynamic _normalizeJson(dynamic data) {
    if (data is String) return jsonDecode(data);
    return data;
  }

  /// List purchased clients (CRM chats with status = "compro")
  Future<PurchasedClientsResponse> getPurchasedClients({
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _dio.get(
      '/crm/purchased-clients',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final jsonData = _normalizeJson(response.data);
      return PurchasedClientsResponse.fromJson(
        jsonData as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Failed to load purchased clients: ${response.statusCode}',
      );
    }
  }

  /// Get single purchased client details
  Future<PurchasedClient> getPurchasedClient(String clientId) async {
    final response = await _dio.get('/crm/purchased-clients/$clientId');

    if (response.statusCode == 200) {
      final jsonData = _normalizeJson(response.data) as Map<String, dynamic>;
      return PurchasedClient.fromJson(jsonData['item'] as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw Exception('Purchased client not found or not marked as "compro"');
    } else {
      throw Exception(
        'Failed to load purchased client: ${response.statusCode}',
      );
    }
  }

  /// Update purchased client
  Future<PurchasedClient> updatePurchasedClient(
    String clientId, {
    String? displayName,
    String? phone,
    String? note,
    String? assignedUserId,
    String? productId,
  }) async {
    final requestBody = <String, dynamic>{};

    if (displayName != null) requestBody['displayName'] = displayName;
    if (phone != null) requestBody['phone'] = phone;
    if (note != null) requestBody['note'] = note;
    if (assignedUserId != null) requestBody['assignedUserId'] = assignedUserId;
    if (productId != null) requestBody['productId'] = productId;

    final response = await _dio.patch(
      '/crm/purchased-clients/$clientId',
      data: requestBody,
    );

    if (response.statusCode == 200) {
      final jsonData = _normalizeJson(response.data) as Map<String, dynamic>;
      return PurchasedClient.fromJson(jsonData['item'] as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to update purchased client: ${response.statusCode}',
      );
    }
  }

  /// Delete purchased client (soft delete by default)
  Future<String> deletePurchasedClient(
    String clientId, {
    bool hardDelete = false,
  }) async {
    final queryParams = hardDelete
        ? {'hardDelete': 'true'}
        : <String, String>{};

    final response = await _dio.delete(
      '/crm/purchased-clients/$clientId',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final jsonData = _normalizeJson(response.data) as Map<String, dynamic>;
      return (jsonData['message'] as String?) ?? 'Client deleted successfully';
    } else {
      throw Exception(
        'Failed to delete purchased client: ${response.statusCode}',
      );
    }
  }
}
