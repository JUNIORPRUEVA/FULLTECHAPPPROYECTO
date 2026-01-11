import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';

import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../constants/operations_tab_mapping.dart';
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
          tab: state.tab,
          q: state.search.isEmpty ? null : state.search,
          estado: state.estado,
          tipoTrabajo: state.tipoTrabajo,
          assignedTechId: state.assignedTechId,
          from: state.from,
          to: state.to,
          page: 1,
          pageSize: state.pageSize,
        );
      }

      final local = await _repo.listLocalJobs(
        empresaId: empresaId,
        q: state.search.isEmpty ? null : state.search,
        estado: state.estado,
        tipoTrabajo: state.tipoTrabajo,
        assignedTechId: state.assignedTechId,
        from: state.from,
        to: state.to,
        page: 1,
        pageSize: state.pageSize,
      );

      state = state.copyWith(
        loading: false,
        items: local,
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
          tab: state.tab,
          q: state.search.isEmpty ? null : state.search,
          estado: state.estado,
          tipoTrabajo: state.tipoTrabajo,
          assignedTechId: state.assignedTechId,
          from: state.from,
          to: state.to,
          page: nextPage,
          pageSize: state.pageSize,
        );
      } catch (_) {}

      final local = await _repo.listLocalJobs(
        empresaId: empresaId,
        q: state.search.isEmpty ? null : state.search,
        estado: state.estado,
        tipoTrabajo: state.tipoTrabajo,
        assignedTechId: state.assignedTechId,
        from: state.from,
        to: state.to,
        page: nextPage,
        pageSize: state.pageSize,
      );

      state = state.copyWith(
        loading: false,
        items: [...state.items, ...local],
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

  void setTab(String tab) {
    final t = tab.trim();
    if (t.isEmpty) return;
    state = state.copyWith(tab: t);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void applyTabPreset(OperationsTab tab) {
    String nextTab = state.tab;
    String? nextEstado;
    String? nextTipoTrabajo;

    switch (tab) {
      case OperationsTab.agenda:
        nextTab = 'agenda';
        nextEstado = null;
        nextTipoTrabajo = null;
        break;
      case OperationsTab.levantamientos:
        nextTab = 'levantamientos';
        nextEstado = null;
        nextTipoTrabajo = null;
        break;
      case OperationsTab.instalacionEnCurso:
        nextTab = 'agenda';
        nextEstado = 'EN_EJECUCION';
        nextTipoTrabajo = 'INSTALACION';
        break;
      case OperationsTab.enGarantia:
        nextTab = 'agenda';
        nextEstado = null;
        nextTipoTrabajo = 'GARANTIA';
        break;
      case OperationsTab.instalacionFinalizada:
        nextTab = 'historial';
        nextEstado = 'FINALIZADO';
        nextTipoTrabajo = 'INSTALACION';
        break;
      case OperationsTab.solucionGarantia:
        nextTab = 'historial';
        nextEstado = 'CERRADO';
        nextTipoTrabajo = 'GARANTIA';
        break;
      case OperationsTab.historial:
        nextTab = 'historial';
        nextEstado = null;
        nextTipoTrabajo = null;
        break;
    }

    state = state.copyWith(
      tab: nextTab,
      estado: nextEstado,
      tipoTrabajo: nextTipoTrabajo,
    );
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setEstado(String? value) {
    final v = (value ?? '').trim();
    state = state.copyWith(estado: v.isEmpty ? null : v);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setTipoTrabajo(String? value) {
    final v = (value ?? '').trim();
    state = state.copyWith(tipoTrabajo: v.isEmpty ? null : v);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setAssignedTechId(String? value) {
    final v = (value ?? '').trim();
    state = state.copyWith(assignedTechId: v.isEmpty ? null : v);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    state = state.copyWith(from: from, to: to);
    _debouncer.run(() => refresh(forceServer: true));
  }

  void quickToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    setDateRange(from: start, to: end);
  }

  void quickThisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday; // Mon=1
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    final end = start
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
    setDateRange(from: start, to: end);
  }

  void clearDateRange() {
    setDateRange(from: null, to: null);
  }
}
