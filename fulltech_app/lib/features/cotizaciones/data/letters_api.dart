import 'package:dio/dio.dart';

class LettersApi {
  final Dio _dio;

  static final Options _noOfflineQueue = Options(
    extra: const {'offlineQueue': false},
  );

  LettersApi(this._dio);

  Future<Map<String, dynamic>> listLettersPaged({
    String? q,
    String? letterType,
    String? status,
    String? from,
    String? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/letters',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (letterType != null && letterType.trim().isNotEmpty)
          'letterType': letterType.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        'limit': limit,
        'offset': offset,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> getLetter(String id) async {
    final res = await _dio.get('/letters/$id');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> createLetter(Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/letters',
      data: payload,
      options: _noOfflineQueue,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> updateLetter(String id, Map<String, dynamic> payload) async {
    final res = await _dio.put(
      '/letters/$id',
      data: payload,
      options: _noOfflineQueue,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<void> deleteLetter(String id) async {
    await _dio.delete(
      '/letters/$id',
      options: _noOfflineQueue,
    );
  }

  Future<Map<String, dynamic>> markSent(String id) async {
    final res = await _dio.post(
      '/letters/$id/mark-sent',
      options: _noOfflineQueue,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> createExport(String id, {String? fileUrl}) async {
    final res = await _dio.post(
      '/letters/$id/exports',
      data: {
        'format': 'PDF',
        if (fileUrl != null) 'fileUrl': fileUrl,
      },
      options: _noOfflineQueue,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
