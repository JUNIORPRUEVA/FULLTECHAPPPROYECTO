import '../models/operations_models.dart';

class OperationsJobsState {
  final bool loading;
  final String? error;

  final List<OperationsJob> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  final String search;
  final String? status;
  final String? assignedTechId;
  final String? serviceId;

  const OperationsJobsState({
    required this.loading,
    required this.error,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.search,
    required this.status,
    required this.assignedTechId,
    required this.serviceId,
  });

  factory OperationsJobsState.initial() {
    return const OperationsJobsState(
      loading: false,
      error: null,
      items: <OperationsJob>[],
      page: 1,
      pageSize: 20,
      hasMore: true,
      search: '',
      status: null,
      assignedTechId: null,
      serviceId: null,
    );
  }

  OperationsJobsState copyWith({
    bool? loading,
    String? error,
    List<OperationsJob>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
    String? search,
    String? status,
    String? assignedTechId,
    String? serviceId,
  }) {
    return OperationsJobsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      status: status ?? this.status,
      assignedTechId: assignedTechId ?? this.assignedTechId,
      serviceId: serviceId ?? this.serviceId,
    );
  }
}
