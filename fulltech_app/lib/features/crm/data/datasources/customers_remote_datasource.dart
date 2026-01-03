import 'package:dio/dio.dart';

import '../models/crm_thread.dart';
import '../models/customer.dart';

class CustomersRemoteDataSource {
  final Dio _dio;

  CustomersRemoteDataSource(this._dio);

  Future<CustomersPage> listCustomers({
    String? search,
    List<String>? tags,
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/customers',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        'limit': limit,
        'offset': offset,
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Customer.fromJson)
        .toList();

    return CustomersPage(
      items: items,
      total: (data['total'] as num? ?? items.length).toInt(),
      limit: (data['limit'] as num? ?? limit).toInt(),
      offset: (data['offset'] as num? ?? offset).toInt(),
    );
  }

  Future<CustomerDetail> getCustomer(String id) async {
    final res = await _dio.get('/customers/$id');
    final data = res.data as Map<String, dynamic>;

    final customer = Customer.fromJson(data['item'] as Map<String, dynamic>);
    final threads = (data['threads'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(CrmThread.fromJson)
        .toList();

    final resumen = data['resumen'] as Map<String, dynamic>?;

    return CustomerDetail(customer: customer, threads: threads, resumen: resumen);
  }
}

class CustomersPage {
  final List<Customer> items;
  final int total;
  final int limit;
  final int offset;

  CustomersPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

class CustomerDetail {
  final Customer customer;
  final List<CrmThread> threads;
  final Map<String, dynamic>? resumen;

  CustomerDetail({
    required this.customer,
    required this.threads,
    required this.resumen,
  });
}
