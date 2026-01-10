import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';

import '../data/repositories/customers_repository.dart';
import '../constants/crm_statuses.dart';
import 'customers_state.dart';

class CustomersController extends StateNotifier<CustomersState> {
  final CustomersRepository _repo;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  CustomersController({required CustomersRepository repo})
    : _repo = repo,
      super(CustomersState.initial());

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null, offset: 0);
    try {
      final status = state.status == CrmStatuses.agendado
          ? CrmStatuses.servicioReservado
          : state.status;
      final page = await _repo.listCustomers(
        search: state.search.isEmpty ? null : state.search,
        productId: state.productId,
        status: status,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
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
      final status = state.status == CrmStatuses.agendado
          ? CrmStatuses.servicioReservado
          : state.status;
      final page = await _repo.listCustomers(
        search: state.search.isEmpty ? null : state.search,
        productId: state.productId,
        status: status,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
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
    _debouncer.run(() => refresh());
  }

  void setProductId(String? value) {
    state = state.copyWith(productId: value);
    _debouncer.run(() => refresh());
  }

  void setStatus(String? value) {
    state = state.copyWith(status: value);
    _debouncer.run(() => refresh());
  }

  void setDateRange(String? from, String? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    _debouncer.run(() => refresh());
  }

  void clearFilters() {
    state = state.clearFilters();
  }

  Future<void> selectCustomer(String? customerId) async {
    if (customerId == null) {
      state = state.copyWith(selectedCustomerId: null, selectedDetail: null);
      return;
    }

    state = state.copyWith(selectedCustomerId: customerId, loadingDetail: true);

    try {
      final detail = await _repo.getCustomer(customerId);
      state = state.copyWith(selectedDetail: detail, loadingDetail: false);
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo cargar el detalle: $e',
        loadingDetail: false,
      );
    }
  }

  Future<void> addNote({
    required String text,
    String? followUpAt,
    String? priority,
  }) async {
    final customerId = state.selectedCustomerId;
    if (customerId == null) return;

    try {
      await _repo.addNote(
        customerId,
        text: text,
        followUpAt: followUpAt,
        priority: priority,
      );
      await selectCustomer(customerId);
    } catch (e) {
      state = state.copyWith(error: 'No se pudo guardar la nota: $e');
    }
  }

  Future<void> updateCustomer(Map<String, dynamic> patch) async {
    final customerId = state.selectedCustomerId;
    if (customerId == null) return;

    try {
      await _repo.patchCustomer(customerId, patch);
      await selectCustomer(customerId);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'No se pudo actualizar: $e');
    }
  }
}
