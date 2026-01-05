import '../data/models/crm_chat_stats.dart';

class CrmChatStatsState {
  final bool loading;
  final String? error;
  final CrmChatStats? stats;

  const CrmChatStatsState({
    required this.loading,
    required this.error,
    required this.stats,
  });

  factory CrmChatStatsState.initial() {
    return const CrmChatStatsState(loading: false, error: null, stats: null);
  }

  CrmChatStatsState copyWith({
    bool? loading,
    String? error,
    CrmChatStats? stats,
  }) {
    return CrmChatStatsState(
      loading: loading ?? this.loading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}
