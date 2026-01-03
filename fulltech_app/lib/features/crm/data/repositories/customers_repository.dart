import '../datasources/customers_remote_datasource.dart';

class CustomersRepository {
  final CustomersRemoteDataSource _remote;

  CustomersRepository(this._remote);

  Future<CustomersPage> listCustomers({
    String? search,
    List<String>? tags,
    int limit = 30,
    int offset = 0,
  }) {
    return _remote.listCustomers(
      search: search,
      tags: tags,
      limit: limit,
      offset: offset,
    );
  }

  Future<CustomerDetail> getCustomer(String id) => _remote.getCustomer(id);
}
