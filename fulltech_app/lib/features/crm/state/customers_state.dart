import '../data/models/customer.dart';

class CustomersState {
  final bool loading;
  final String? error;
  final List<Customer> items;
  final int total;
  final int limit;
  final int offset;
  final String search;

  const CustomersState({
    required this.loading,
    required this.error,
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.search,
  });

  factory CustomersState.initial() {
    return const CustomersState(
      loading: false,
      error: null,
      items: <Customer>[],
      total: 0,
      limit: 30,
      offset: 0,
      search: '',
    );
  }

  CustomersState copyWith({
    bool? loading,
    String? error,
    List<Customer>? items,
    int? total,
    int? limit,
    int? offset,
    String? search,
  }) {
    return CustomersState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      search: search ?? this.search,
    );
  }
}
