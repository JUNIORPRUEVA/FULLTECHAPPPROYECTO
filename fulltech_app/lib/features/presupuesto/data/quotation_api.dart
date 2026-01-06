import 'package:dio/dio.dart';

class QuotationApi {
  final Dio _dio;

  static final Options _noOfflineQueue = Options(
    extra: const {'offlineQueue': false},
  );

  QuotationApi(this._dio);

  Future<Map<String, dynamic>> listQuotationsPaged({
    String? q,
    String? status,
    String? from,
    String? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/quotations',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Backwards-compatible helper that returns only the list of items.
  Future<List<Map<String, dynamic>>> listQuotations({
    String? q,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await listQuotationsPaged(
      q: q,
      limit: limit,
      offset: offset,
    );
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items;
  }

  Future<Map<String, dynamic>> getQuotation(String id) async {
    final res = await _dio.get('/quotations/$id');
    return (res.data['item'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createQuotation(
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.post(
      '/quotations',
      data: payload,
      options: _noOfflineQueue,
    );
    return (res.data['item'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateQuotation(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.put(
      '/quotations/$id',
      data: payload,
      options: _noOfflineQueue,
    );
    return (res.data['item'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> duplicateQuotation(String id) async {
    final res = await _dio.post(
      '/quotations/$id/duplicate',
      options: _noOfflineQueue,
    );
    return (res.data['item'] as Map).cast<String, dynamic>();
  }

  Future<void> deleteQuotation(String id) async {
    await _dio.delete(
      '/quotations/$id',
      options: _noOfflineQueue,
    );
  }

  Future<Map<String, dynamic>> sendQuotation(
    String id, {
    required String channel,
    String? to,
    String? message,
  }) async {
    final res = await _dio.post(
      '/quotations/$id/send',
      data: {
        'channel': channel,
        if (to != null) 'to': to,
        if (message != null) 'message': message,
      },
      options: _noOfflineQueue,
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
