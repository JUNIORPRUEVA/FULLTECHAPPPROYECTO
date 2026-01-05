import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/customers_repository.dart';
import 'customer_detail_state.dart';

class CustomerDetailController extends StateNotifier<CustomerDetailState> {
  final CustomersRepository _repo;
  final String _customerId;

  CustomerDetailController({
    required CustomersRepository repo,
    required String customerId,
  })  : _repo = repo,
        _customerId = customerId,
        super(CustomerDetailState.initial());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final detail = await _repo.getCustomer(_customerId);
      state = state.copyWith(
        loading: false,
        detail: detail,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
