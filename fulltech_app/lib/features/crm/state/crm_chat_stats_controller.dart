import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/crm_repository.dart';
import 'crm_chat_stats_state.dart';

class CrmChatStatsController extends StateNotifier<CrmChatStatsState> {
  final CrmRepository _repo;
  Timer? _timer;

  CrmChatStatsController({required CrmRepository repo})
      : _repo = repo,
        super(CrmChatStatsState.initial()) {
    // Start periodic refresh.
    Future.microtask(refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
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
      state = state.copyWith(loading: false, error: e.toString());
      if (kDebugMode) {
        debugPrint('[CRM][STATE] stats error=$e');
      }
    }
  }
}
