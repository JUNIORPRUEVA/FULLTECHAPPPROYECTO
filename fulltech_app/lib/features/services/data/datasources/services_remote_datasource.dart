import '../../../../core/services/api_client.dart';
import '../models/service_model.dart';

class ServicesRemoteDatasource {
  final ApiClient _apiClient;

  ServicesRemoteDatasource(this._apiClient);

  Future<List<ServiceModel>> fetchServices({
    String? query,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.dio.get(
      '/services',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final services = data['services'] as List<dynamic>;
    return services
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceModel> fetchServiceById(String id) async {
    final response = await _apiClient.dio.get('/services/$id');

    final data = response.data as Map<String, dynamic>;
    return ServiceModel.fromJson(data['service'] as Map<String, dynamic>);
  }

  Future<ServiceModel> createService({
    required String name,
    String? description,
    double? defaultPrice,
  }) async {
    final body = {
      'name': name,
      if (description != null) 'description': description,
      if (defaultPrice != null) 'default_price': defaultPrice,
    };

    final response = await _apiClient.dio.post('/services', data: body);

    final data = response.data as Map<String, dynamic>;
    return ServiceModel.fromJson(data['service'] as Map<String, dynamic>);
  }

  Future<ServiceModel> updateService({
    required String id,
    String? name,
    String? description,
    double? defaultPrice,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (defaultPrice != null) body['default_price'] = defaultPrice;
    if (isActive != null) body['is_active'] = isActive;

    final response = await _apiClient.dio.put('/services/$id', data: body);

    final data = response.data as Map<String, dynamic>;
    return ServiceModel.fromJson(data['service'] as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _apiClient.dio.delete('/services/$id');
  }
}
