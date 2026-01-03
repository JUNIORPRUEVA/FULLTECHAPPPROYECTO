import '../data/models/crm_thread.dart';

class CrmThreadsState {
  final bool loading;
  final String? error;
  final List<CrmThread> items;
  final int total;
  final int limit;
  final int offset;

  final String search;
  final String estado;

  const CrmThreadsState({
    required this.loading,
    required this.error,
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.search,
    required this.estado,
  });

  factory CrmThreadsState.initial() {
    return const CrmThreadsState(
      loading: false,
      error: null,
      items: <CrmThread>[],
      total: 0,
      limit: 30,
      offset: 0,
      search: '',
      estado: 'todos',
    );
  }

  CrmThreadsState copyWith({
    bool? loading,
    String? error,
    List<CrmThread>? items,
    int? total,
    int? limit,
    int? offset,
    String? search,
    String? estado,
  }) {
    return CrmThreadsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      search: search ?? this.search,
      estado: estado ?? this.estado,
    );
  }
}
