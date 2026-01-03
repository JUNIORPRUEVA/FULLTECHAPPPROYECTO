import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/users_repository.dart';
import 'users_state.dart';

class UsersController extends StateNotifier<UsersState> {
  final UsersRepository _repo;

  UsersController({required UsersRepository repo})
      : _repo = repo,
        super(UsersState.initial());

  Future<void> load({bool reset = false}) async {
    final nextPage = reset ? 1 : state.page;
    state = state.copyWith(isLoading: true, clearError: true, page: nextPage);
    try {
      final page = await _repo.listUsers(
        page: nextPage,
        pageSize: state.pageSize,
        q: state.query,
        rol: state.rol,
        estado: state.estado,
      );
      state = state.copyWith(
        isLoading: false,
        total: page.total,
        page: page.page,
        pageSize: page.pageSize,
        items: reset ? page.items : [...state.items, ...page.items],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String v) {
    state = state.copyWith(query: v, clearError: true);
  }

  void setRol(String? v) {
    state = state.copyWith(rol: v, clearError: true);
  }

  void setEstado(String? v) {
    state = state.copyWith(estado: v, clearError: true);
  }

  Future<void> search() async {
    state = state.copyWith(items: const [], total: 0, page: 1);
    await load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(page: state.page + 1);
    await load(reset: false);
  }
}
