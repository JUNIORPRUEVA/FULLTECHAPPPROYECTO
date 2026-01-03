import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/customers_repository.dart';
import 'customers_state.dart';

class CustomersController extends StateNotifier<CustomersState> {
  final CustomersRepository _repo;

  CustomersController({required CustomersRepository repo})
      : _repo = repo,
        super(CustomersState.initial());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null, offset: 0);
    try {
      final page = await _repo.listCustomers(
        search: state.search.isEmpty ? null : state.search,
        limit: state.limit,
        offset: 0,
      );
      state = state.copyWith(
        loading: false,
        items: page.items,
        total: page.total,
        offset: page.offset,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading) return;
    final nextOffset = state.offset + state.items.length;
    if (state.items.isNotEmpty && nextOffset >= state.total) return;

    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.listCustomers(
        search: state.search.isEmpty ? null : state.search,
        limit: state.limit,
        offset: nextOffset,
      );
      state = state.copyWith(
        loading: false,
        items: [...state.items, ...page.items],
        total: page.total,
        offset: nextOffset,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }
}
