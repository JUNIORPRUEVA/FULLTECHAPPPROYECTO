import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';

import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../data/operations_repository.dart';
import 'operations_jobs_state.dart';

class OperationsJobsController extends StateNotifier<OperationsJobsState> {
  OperationsJobsController({
    required OperationsRepository repo,
    required this.read,
  }) : _repo = repo,
       super(OperationsJobsState.initial());

  final OperationsRepository _repo;

  /// Riverpod v2-compatible `ref.read` function.
  final T Function<T>(ProviderListenable<T> provider) read;

  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  String? _empresaIdOrNull() {
    final auth = read(authControllerProvider);
    if (auth is! AuthAuthenticated) return null;
    return auth.user.empresaId;
  }

  Future<void> refresh({bool forceServer = true}) async {
    final empresaId = _empresaIdOrNull();
    if (empresaId == null) return;

    state = state.copyWith(
      loading: true,
      error: null,
      page: 1,
      hasMore: true,
      items: const [],
    );

    try {
      if (forceServer) {
        await _repo.refreshJobsFromServer(
          empresaId: empresaId,
          q: state.search.isEmpty ? null : state.search,
          status: state.status,
          assignedTechId: state.assignedTechId,
          page: 1,
          pageSize: state.pageSize,
        );
      }

      final local = await _repo.listLocalJobs(
        empresaId: empresaId,
        q: state.search.isEmpty ? null : state.search,
        status: state.status,
        assignedTechId: state.assignedTechId,
        page: 1,
        pageSize: state.pageSize,
      );

      final filtered = state.serviceId == null
          ? local
          : local
                .where((j) => (j.serviceId ?? '').trim() == state.serviceId)
                .toList(growable: false);

      state = state.copyWith(
        loading: false,
        items: filtered,
        page: 1,
        hasMore: local.length >= state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;

    final empresaId = _empresaIdOrNull();
    if (empresaId == null) return;

    state = state.copyWith(loading: true, error: null);

    final nextPage = state.page + 1;
    try {
      // Best-effort server refresh for that page.
      try {
        await _repo.refreshJobsFromServer(
          empresaId: empresaId,
          q: state.search.isEmpty ? null : state.search,
          status: state.status,
          assignedTechId: state.assignedTechId,
          page: nextPage,
          pageSize: state.pageSize,
        );
      } catch (_) {}

      final local = await _repo.listLocalJobs(
        empresaId: empresaId,
        q: state.search.isEmpty ? null : state.search,
        status: state.status,
        assignedTechId: state.assignedTechId,
        page: nextPage,
        pageSize: state.pageSize,
      );

      final filtered = state.serviceId == null
          ? local
          : local
                .where((j) => (j.serviceId ?? '').trim() == state.serviceId)
                .toList(growable: false);

      state = state.copyWith(
        loading: false,
        items: [...state.items, ...filtered],
        page: nextPage,
        hasMore: local.length >= state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setStatus(String? value) {
    state = state.copyWith(status: value);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setAssignedTechId(String? value) {
    final v = (value ?? '').trim();
    state = state.copyWith(assignedTechId: v.isEmpty ? null : v);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setServiceId(String? value) {
    final v = (value ?? '').trim();
    state = state.copyWith(serviceId: v.isEmpty ? null : v);
    _debouncer.run(() => refresh(forceServer: true));
  }
}
