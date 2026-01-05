import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payroll_models.dart';
import '../data/repositories/payroll_repository.dart';

class PayrollRunsState {
  final bool loading;
  final String? error;
  final List<PayrollRunListItem> items;

  const PayrollRunsState({
    required this.loading,
    required this.items,
    this.error,
  });

  factory PayrollRunsState.initial() => const PayrollRunsState(
        loading: false,
        items: [],
      );

  PayrollRunsState copyWith({
    bool? loading,
    String? error,
    List<PayrollRunListItem>? items,
  }) {
    return PayrollRunsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
    );
  }
}

class PayrollRunsController extends StateNotifier<PayrollRunsState> {
  final PayrollRepository _repo;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  PayrollRunsController({required PayrollRepository repo})
      : _repo = repo,
        super(PayrollRunsState.initial()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Load cache first
    try {
      final cached = await _repo.readCachedAdminRuns();
      if (cached.isNotEmpty) {
        state = state.copyWith(items: cached, loading: false);
      }
    } catch (_) {
      // ignore cache errors
    }

    await refresh(showLoading: state.items.isEmpty);

    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      // Background refresh when back online
      refresh(showLoading: false);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> refresh({required bool showLoading}) async {
    if (showLoading) state = state.copyWith(loading: true, error: null);
    try {
      final items = await _repo.fetchAdminRuns();
      state = state.copyWith(loading: false, items: items, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<String?> createRun({
    required int year,
    required int month,
    required PayrollHalf half,
    String? notes,
  }) async {
    try {
      await _repo.ensureCurrentPeriods(year: year, month: month);
      final runId = await _repo.createRun(year: year, month: month, half: half, notes: notes);
      await refresh(showLoading: false);
      return runId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}
