import '../data/models/crm_message.dart';

class CrmMessagesState {
  final bool loading;
  final bool loadingMore;
  final bool sending;
  final String? error;
  final List<CrmMessage> items;
  final DateTime? nextBefore;

  const CrmMessagesState({
    required this.loading,
    required this.loadingMore,
    required this.sending,
    required this.error,
    required this.items,
    required this.nextBefore,
  });

  factory CrmMessagesState.initial() {
    return const CrmMessagesState(
      loading: false,
      loadingMore: false,
      sending: false,
      error: null,
      items: <CrmMessage>[],
      nextBefore: null,
    );
  }

  CrmMessagesState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? sending,
    String? error,
    List<CrmMessage>? items,
    DateTime? nextBefore,
  }) {
    return CrmMessagesState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      sending: sending ?? this.sending,
      error: error,
      items: items ?? this.items,
      nextBefore: nextBefore,
    );
  }
}
