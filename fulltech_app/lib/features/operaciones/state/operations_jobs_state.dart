import '../models/operations_models.dart';

class OperationsJobsState {
  final bool loading;
  final String? error;

  final List<OperationsJob> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  final String search;
  final String tab; // agenda | levantamientos | historial
  final String? estado;
  final String? tipoTrabajo;
  final String? assignedTechId;
  final DateTime? from;
  final DateTime? to;

  const OperationsJobsState({
    required this.loading,
    required this.error,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.search,
    required this.tab,
    required this.estado,
    required this.tipoTrabajo,
    required this.assignedTechId,
    required this.from,
    required this.to,
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
      tab: 'agenda',
      estado: null,
      tipoTrabajo: null,
      assignedTechId: null,
      from: null,
      to: null,
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
    String? tab,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    DateTime? from,
    DateTime? to,
  }) {
    return OperationsJobsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      tab: tab ?? this.tab,
      estado: estado ?? this.estado,
      tipoTrabajo: tipoTrabajo ?? this.tipoTrabajo,
      assignedTechId: assignedTechId ?? this.assignedTechId,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}
