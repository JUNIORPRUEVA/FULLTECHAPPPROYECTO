import '../data/models/crm_thread.dart';
import '../data/models/customer.dart';

class CustomerDetailState {
  final bool loading;
  final String? error;
  final Customer? customer;
  final List<CrmThread> threads;
  final Map<String, dynamic>? resumen;

  const CustomerDetailState({
    required this.loading,
    required this.error,
    required this.customer,
    required this.threads,
    required this.resumen,
  });

  factory CustomerDetailState.initial() {
    return const CustomerDetailState(
      loading: false,
      error: null,
      customer: null,
      threads: <CrmThread>[],
      resumen: null,
    );
  }

  CustomerDetailState copyWith({
    bool? loading,
    String? error,
    Customer? customer,
    List<CrmThread>? threads,
    Map<String, dynamic>? resumen,
  }) {
    return CustomerDetailState(
      loading: loading ?? this.loading,
      error: error,
      customer: customer ?? this.customer,
      threads: threads ?? this.threads,
      resumen: resumen ?? this.resumen,
    );
  }
}
