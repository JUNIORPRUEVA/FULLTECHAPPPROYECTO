import 'package:dio/dio.dart';

class CompanySettingsApi {
  final Dio _dio;

  CompanySettingsApi(this._dio);

  Future<Map<String, dynamic>> getCompanySettings() async {
    final res = await _dio.get('/company-settings');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
