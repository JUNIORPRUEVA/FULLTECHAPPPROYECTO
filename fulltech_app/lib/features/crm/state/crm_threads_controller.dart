import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';

import '../data/repositories/crm_repository.dart';
import 'crm_threads_state.dart';

class CrmThreadsController extends StateNotifier<CrmThreadsState> {
  final CrmRepository _repo;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  CrmThreadsController({required CrmRepository repo})
    : _repo = repo,
      super(CrmThreadsState.initial());

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null, offset: 0);
    try {
      final page = await _repo.listThreads(
        search: state.search.isEmpty ? null : state.search,
        estado: state.estado == 'todos' ? null : state.estado,
        productId: state.productId,
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
      final page = await _repo.listThreads(
        search: state.search.isEmpty ? null : state.search,
        estado: state.estado == 'todos' ? null : state.estado,
        productId: state.productId,
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

  void setEstado(String value) {
    state = state.copyWith(estado: value);
  }

  void setProductId(String? value) {
    state = state.copyWith(productId: value);
  }
}
