import '../data/models/user_model.dart';

class UsersState {
  final bool isLoading;
  final String? error;

  final String query;
  final String? rol;
  final String? estado;

  final int page;
  final int pageSize;
  final int total;
  final List<UserSummary> items;

  const UsersState({
    required this.isLoading,
    required this.error,
    required this.query,
    required this.rol,
    required this.estado,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory UsersState.initial() {
    return const UsersState(
      isLoading: false,
      error: null,
      query: '',
      rol: null,
      estado: null,
      page: 1,
      pageSize: 20,
      total: 0,
      items: [],
    );
  }

  bool get hasMore => items.length < total;

  UsersState copyWith({
    bool? isLoading,
    String? error,
    String? query,
    String? rol,
    String? estado,
    int? page,
    int? pageSize,
    int? total,
    List<UserSummary>? items,
    bool clearError = false,
  }) {
    return UsersState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }
}
