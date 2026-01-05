import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payroll_models.dart';
import '../data/repositories/payroll_repository.dart';

class MyPayrollState {
  final bool loading;
  final String? error;
  final List<MyPayrollHistoryItem> history;
  final List<PayrollNotificationItem> notifications;

  const MyPayrollState({
    required this.loading,
    required this.history,
    required this.notifications,
    this.error,
  });

  factory MyPayrollState.initial() =>
      const MyPayrollState(loading: false, history: [], notifications: []);

  MyPayrollState copyWith({
    bool? loading,
    String? error,
    List<MyPayrollHistoryItem>? history,
    List<PayrollNotificationItem>? notifications,
  }) {
    return MyPayrollState(
      loading: loading ?? this.loading,
      error: error,
      history: history ?? this.history,
      notifications: notifications ?? this.notifications,
    );
  }
}

class MyPayrollController extends StateNotifier<MyPayrollState> {
  final PayrollRepository _repo;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  MyPayrollController({required PayrollRepository repo})
    : _repo = repo,
      super(MyPayrollState.initial()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final cachedHistory = await _repo.readCachedMyHistory();
      final cachedNotifications = await _repo.readCachedMyNotifications();

      state = state.copyWith(
        history: cachedHistory?.items ?? state.history,
        notifications: cachedNotifications?.items ?? state.notifications,
      );
    } catch (_) {
      // ignore
    }

    await refresh(showLoading: state.history.isEmpty);

    _connSub = Connectivity().onConnectivityChanged.listen((_) {
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
      final history = await _repo.fetchMyHistory();
      final notifications = await _repo.fetchMyNotifications();
      state = state.copyWith(
        loading: false,
        history: history.items,
        notifications: notifications.items,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<MyPayrollDetailResponse?> getDetail(String runId) async {
    final cached = await _repo.readCachedMyDetail(runId);
    if (cached != null) {
      // background refresh
      _repo.fetchMyDetail(runId);
      return cached;
    }
    try {
      return await _repo.fetchMyDetail(runId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}
