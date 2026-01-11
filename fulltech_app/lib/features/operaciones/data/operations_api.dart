import 'package:dio/dio.dart';
import 'dart:typed_data';

class OperationsApi {
  final Dio _dio;

  OperationsApi(this._dio);

  static final _noOfflineQueue = Options(extra: const {'offlineQueue': false});

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
    final res = await _dio.post('/operations/jobs', data: payload, options: _noOfflineQueue);
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

  Future<Map<String, dynamic>> listOperaciones({
    String? tab, // agenda | levantamientos | historial
    String? q,
    String? estado, // PENDIENTE | PROGRAMADO | EN_EJECUCION | FINALIZADO | CERRADO | CANCELADO
    String? tipo, // INSTALACION | MANTENIMIENTO | LEVANTAMIENTO | GARANTIA
    String? tecnicoId,
    String? from,
    String? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/operations',
      queryParameters: {
        if (tab != null && tab.trim().isNotEmpty) 'tab': tab.trim(),
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (estado != null && estado.trim().isNotEmpty) 'estado': estado.trim(),
        if (tipo != null && tipo.trim().isNotEmpty) 'tipo': tipo.trim(),
        if (tecnicoId != null && tecnicoId.trim().isNotEmpty) 'tecnicoId': tecnicoId.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchOperacionEstado(
    String id, {
    required String estado,
    String? note,
  }) async {
    final res = await _dio.patch(
      '/operations/$id/estado',
      data: {
        'estado': estado,
        if (note != null) 'note': note,
      },
      options: _noOfflineQueue,
    );
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> programarOperacion(
    String id, {
    required String scheduledDate,
    String? preferredTime,
    String? assignedTechId,
    String? note,
  }) async {
    final res = await _dio.post(
      '/operations/$id/programar',
      data: {
        'scheduled_date': scheduledDate,
        if (preferredTime != null) 'preferred_time': preferredTime,
        if (assignedTechId != null) 'assigned_tech_id': assignedTechId,
        if (note != null) 'note': note,
      },
      options: _noOfflineQueue,
    );
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> convertirALaAgenda(
    String id, {
    required String tipoDestino,
    required String scheduledDate,
    String? preferredTime,
    String? assignedTechId,
    String? note,
  }) async {
    final res = await _dio.post(
      '/operations/$id/convertir-a-agenda',
      data: {
        'tipo_destino': tipoDestino,
        'scheduled_date': scheduledDate,
        if (preferredTime != null) 'preferred_time': preferredTime,
        if (assignedTechId != null) 'assigned_tech_id': assignedTechId,
        if (note != null) 'note': note,
      },
      options: _noOfflineQueue,
    );
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> getJob(String id) async {
    final res = await _dio.get('/operations/jobs/$id');
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchJob(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/operations/jobs/$id', data: patch, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchJobStatus(String id, Map<String, dynamic> payload) async {
    final res = await _dio.patch(
      '/operations/jobs/$id/status',
      data: payload,
      options: _noOfflineQueue,
    );
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> listJobHistory(String id) async {
    final res = await _dio.get('/operations/jobs/$id/history');
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> submitSurvey(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/surveys', data: payload, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> scheduleJob(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/schedules', data: payload, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> startInstallation(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/installations/start', data: payload, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> completeInstallation(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/installations/complete', data: payload, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> createWarrantyTicket(Map<String, dynamic> payload) async {
    final res = await _dio.post('/operations/warranty-tickets', data: payload, options: _noOfflineQueue);
    return _ensureOk(res.data);
  }

  Future<Map<String, dynamic>> patchWarrantyTicket(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/operations/warranty-tickets/$id', data: patch, options: _noOfflineQueue);
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

    final res = await _dio.post('/uploads/operations', data: form, options: _noOfflineQueue);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
