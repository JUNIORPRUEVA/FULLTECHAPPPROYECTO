import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/crm_repository.dart';
import 'crm_chat_stats_state.dart';

class CrmChatStatsController extends StateNotifier<CrmChatStatsState> {
  final CrmRepository _repo;
  Timer? _timer;
  bool _started = false;

  CrmChatStatsController({required CrmRepository repo})
      : _repo = repo,
        super(CrmChatStatsState.initial());

  /// Must be called AFTER auth is confirmed to start periodic refresh
  void start() {
    if (_started) return;
    _started = true;
    Future.microtask(refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    if (kDebugMode) {
      debugPrint('[CRM][STATE] stats controller started');
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    if (kDebugMode) {
      debugPrint('[CRM][STATE] stats controller stopped');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final stats = await _repo.getChatStats();
      state = state.copyWith(loading: false, stats: stats, error: null);
      if (kDebugMode) {
        debugPrint('[CRM][STATE] stats total=${stats.total} unread=${stats.unreadTotal} important=${stats.importantCount}');
      }
    } catch (e) {
      // Stop timer on 401 to prevent infinite loop
      if (e is DioException && e.response?.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('[CRM][STATE] stats 401 - stopping timer');
        }
        stop();
      }
      
      state = state.copyWith(loading: false, error: e.toString());
      if (kDebugMode) {
        debugPrint('[CRM][STATE] stats error=$e');
      }
    }
  }
}
