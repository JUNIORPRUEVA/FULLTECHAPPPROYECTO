import 'package:dio/dio.dart';
import 'package:fulltech_app/features/customers/data/models/customer_response.dart';

class CustomersRepository {
  final Dio _dio;
  CancelToken? _cancelToken;

  CustomersRepository(this._dio);

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
    await _dio.delete(
      '/customers/$id',
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> patchCustomer(String id, Map<String, dynamic> patch) async {
    await _dio.patch(
      '/customers/$id',
      data: patch,
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
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
