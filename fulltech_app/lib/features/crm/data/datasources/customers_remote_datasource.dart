import 'package:dio/dio.dart';

import '../models/customer_enriched.dart';
import '../models/customer_detail.dart' as detail;

class CustomersRemoteDataSource {
  final Dio _dio;
  CancelToken? _cancelToken;

  CustomersRemoteDataSource(this._dio);

  void cancelRequests() {
    _cancelToken?.cancel('Operation cancelled by user');
    _cancelToken = null;
  }

  Options get _defaultOptions => Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  Future<CustomersEnrichedPage> listCustomers({
    String? search,
    List<String>? tags,
    String? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/customers',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (productId != null && productId.trim().isNotEmpty)
          'productId': productId.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (dateFrom != null && dateFrom.trim().isNotEmpty)
          'dateFrom': dateFrom.trim(),
        if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo.trim(),
        'limit': limit,
        'offset': offset,
      },
      options: _defaultOptions,
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CustomerEnriched.fromJson)
        .toList();

    return CustomersEnrichedPage(
      items: items,
      total: (data['total'] as num? ?? items.length).toInt(),
      limit: (data['limit'] as num? ?? limit).toInt(),
      offset: (data['offset'] as num? ?? offset).toInt(),
    );
  }

  Future<detail.CustomerDetail> getCustomer(String id) async {
    final res = await _dio.get('/customers/$id', options: _defaultOptions);
    return detail.CustomerDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> patchCustomer(String id, Map<String, dynamic> patch) async {
    await _dio.patch('/customers/$id', data: patch, options: _defaultOptions);
  }

  Future<void> addNote(
    String id, {
    required String text,
    String? followUpAt,
    String? priority,
  }) async {
    await _dio.post(
      '/customers/$id/notes',
      data: {
        'text': text,
        if (followUpAt != null) 'followUpAt': followUpAt,
        if (priority != null) 'priority': priority,
      },
      options: _defaultOptions,
    );
  }
}

class CustomersEnrichedPage {
  final List<CustomerEnriched> items;
  final int total;
  final int limit;
  final int offset;

  CustomersEnrichedPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
}
