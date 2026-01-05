import '../datasources/customers_remote_datasource.dart';
import '../models/customer_detail.dart';

class CustomersRepository {
  final CustomersRemoteDataSource _remote;

  CustomersRepository(this._remote);

  Future<CustomersEnrichedPage> listCustomers({
    String? search,
    List<String>? tags,
    String? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
    int limit = 30,
    int offset = 0,
  }) {
    return _remote.listCustomers(
      search: search,
      tags: tags,
      productId: productId,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<CustomerDetail> getCustomer(String id) => _remote.getCustomer(id);

  Future<void> patchCustomer(String id, Map<String, dynamic> patch) =>
      _remote.patchCustomer(id, patch);

  Future<void> addNote(String id, {
    required String text,
    String? followUpAt,
    String? priority,
  }) => _remote.addNote(id, text: text, followUpAt: followUpAt, priority: priority);
}
