import 'dart:typed_data';

import 'package:dio/dio.dart';

class SalesApi {
  final Dio _dio;

  SalesApi(this._dio);

  Map<String, dynamic> _ensureOk(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['ok'] == true) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) return data;
        if (data == null) return <String, dynamic>{};
        return <String, dynamic>{'value': data};
      }
      // Backward compat: some endpoints might still return {item/items}
      return raw;
    }
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> listSales({
    int page = 1,
    int pageSize = 20,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    String? from,
    String? to,
  }) async {
    final res = await _dio.get(
      '/sales',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (channel != null && channel.trim().isNotEmpty) 'channel': channel.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (paymentMethod != null && paymentMethod.trim().isNotEmpty) 'payment_method': paymentMethod.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
      },
    );

    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> getSale(String id) async {
    final res = await _dio.get('/sales/$id');
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> payload) async {
    final res = await _dio.post('/sales', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> updateSale(String id, Map<String, dynamic> patch) async {
    final res = await _dio.put('/sales/$id', data: patch);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> deleteSale(String id) async {
    final res = await _dio.delete('/sales/$id');
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> addEvidence(String saleId, Map<String, dynamic> payload) async {
    final res = await _dio.post('/sales/$saleId/evidence', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> uploadEvidenceFile({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    final res = await _dio.post('/uploads/sales', data: form);

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
