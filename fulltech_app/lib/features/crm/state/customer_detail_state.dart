import '../data/models/customer_detail.dart';

class CustomerDetailState {
  final bool loading;
  final String? error;
  final CustomerDetail? detail;

  const CustomerDetailState({
    required this.loading,
    required this.error,
    required this.detail,
  });

  factory CustomerDetailState.initial() {
    return const CustomerDetailState(
      loading: false,
      error: null,
      detail: null,
    );
  }

  CustomerDetailState copyWith({
    bool? loading,
    String? error,
    CustomerDetail? detail,
  }) {
    return CustomerDetailState(
      loading: loading ?? this.loading,
      error: error,
      detail: detail ?? this.detail,
    );
  }
}
