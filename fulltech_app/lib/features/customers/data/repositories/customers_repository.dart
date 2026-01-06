import 'package:dio/dio.dart';
import 'package:fulltech_app/features/customers/data/models/customer_response.dart';

import '../../../../core/services/offline_http_queue.dart';
import '../../../../core/storage/local_db.dart';

class CustomersRepository {
  final Dio _dio;
  final LocalDb? _db;
  CancelToken? _cancelToken;

  static const _noOfflineQueueExtra = {'offlineQueue': false};

  CustomersRepository(this._dio, {LocalDb? db}) : _db = db;

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return OfflineHttpQueue.isNetworkError(e);
  }

  void cancelRequests() {
    _cancelToken?.cancel('Operation cancelled by user');
    _cancelToken = null;
  }

  Future<CustomerListResponse> getCustomers({
    String? q,
    List<String>? tags,
    String? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
    int? limit,
    int? offset,
  }) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final queryParams = <String, dynamic>{};
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
    if (productId != null) queryParams['productId'] = productId;
    if (status != null) queryParams['status'] = status;
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _dio.get(
      '/customers',
      queryParameters: queryParams,
      cancelToken: _cancelToken,
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    return CustomerListResponse.fromJson(response.data);
  }

  Future<CustomerDetailResponse> getCustomer(String id) async {
    final response = await _dio.get(
      '/customers/$id',
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    return CustomerDetailResponse.fromJson(response.data);
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete(
        '/customers/$id',
        options: Options(
          extra: _noOfflineQueueExtra,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'DELETE',
          path: '/customers/$id',
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> patchCustomer(String id, Map<String, dynamic> patch) async {
    try {
      await _dio.patch(
        '/customers/$id',
        data: patch,
        options: Options(
          extra: _noOfflineQueueExtra,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'PATCH',
          path: '/customers/$id',
          data: patch,
        );
        return;
      }
      rethrow;
    }
  }

  Future<List<CustomerChatItem>> getCustomerChats(String id) async {
    final response = await _dio.get('/customers/$id/chats');
    final data = response.data as Map<String, dynamic>;
    final chats = data['chats'] as List;
    return chats.map((e) => CustomerChatItem.fromJson(e)).toList();
  }

  Future<List<ProductLookupItem>> lookupProducts(String query) async {
    final response = await _dio.get(
      '/crm/products/lookup',
      queryParameters: {'q': query},
    );
    final data = response.data as Map<String, dynamic>;
    final products = data['products'] as List;
    return products.map((e) => ProductLookupItem.fromJson(e)).toList();
  }
}
