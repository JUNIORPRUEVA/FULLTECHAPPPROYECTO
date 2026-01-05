import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounting_repository.dart';
import '../data/models/biweekly_close_model.dart';
import 'biweekly_close_state.dart';

class BiweeklyCloseController extends StateNotifier<BiweeklyCloseState> {
  final AccountingRepository _repo;

  BiweeklyCloseController({required AccountingRepository repo})
    : _repo = repo,
      super(BiweeklyCloseState.initial());

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      final items = await _repo.listBiweeklyCloses(
        filters: BiweeklyCloseListFilters(
          query: state.search,
          from: state.filterFrom,
          to: state.filterTo,
        ),
      );

      state = _withTotals(
        state.copyWith(loading: false, error: null, items: items),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String v) {
    state = state.copyWith(search: v);
    refresh(showLoading: false);
  }

  void setFilterFrom(DateTime? v) {
    state = state.copyWith(filterFrom: v);
    refresh(showLoading: false);
  }

  void setFilterTo(DateTime? v) {
    state = state.copyWith(filterTo: v);
    refresh(showLoading: false);
  }

  void clearFilters() {
    state = state.copyWith(search: '', filterFrom: null, filterTo: null);
    refresh(showLoading: false);
  }

  Future<void> create(BiweeklyCloseUpsertData data) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.createBiweeklyClose(data);
      await refresh(showLoading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> update(String id, BiweeklyCloseUpsertData data) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.updateBiweeklyClose(id, data);
      await refresh(showLoading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.deleteBiweeklyClose(id);
      await refresh(showLoading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  BiweeklyCloseState _withTotals(BiweeklyCloseState st) {
    double sum(double Function(BiweeklyCloseModel) f) {
      double total = 0;
      for (final it in st.items) {
        total += f(it);
      }
      return total;
    }

    return st.copyWith(
      totalIncome: sum((it) => it.income),
      totalExpenses: sum((it) => it.expenses),
      totalPayrollPaid: sum((it) => it.payrollPaid),
      totalNetProfit: sum((it) => it.netProfit),
    );
  }
}
