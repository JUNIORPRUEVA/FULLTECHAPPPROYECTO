import 'package:dio/dio.dart';
import 'dart:typed_data';

class OperationsApi {
  final Dio _dio;

  OperationsApi(this._dio);

  Map<String, dynamic> _ensureOk(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['ok'] == true) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) return data;
        if (data == null) return <String, dynamic>{};
        return <String, dynamic>{'value': data};
      }
      return raw;
    }
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/jobs', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> listJobs({
    String? q,
    String? status,
    String? assignedTechId,
    String? from,
    String? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/operations/jobs',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (assignedTechId != null && assignedTechId.trim().isNotEmpty)
          'assigned_tech_id': assignedTechId.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        'limit': limit,
        'offset': offset,
      },
    );

    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> getJob(String id) async {
    final res = await _dio.get('/operations/jobs/$id');
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchJob(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/operations/jobs/$id', data: patch);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> submitSurvey(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/surveys', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> scheduleJob(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/schedules', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> startInstallation(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/installations/start', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> completeInstallation(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/installations/complete', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> createWarrantyTicket(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/warranty-tickets', data: payload);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchWarrantyTicket(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/operations/warranty-tickets/$id', data: patch);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> uploadOperationsMedia({
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    final res = await _dio.post('/uploads/operations', data: form);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
