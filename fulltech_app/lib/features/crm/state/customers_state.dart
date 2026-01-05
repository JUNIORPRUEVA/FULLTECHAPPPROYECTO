import '../data/models/customer_enriched.dart';
import '../data/models/customer_detail.dart';

class CustomersState {
  final bool loading;
  final String? error;
  final List<CustomerEnriched> items;
  final int total;
  final int limit;
  final int offset;
  
  // Filters
  final String search;
  final String? productId;
  final String? status;
  final String? dateFrom;
  final String? dateTo;
  
  // Selected customer detail
  final String? selectedCustomerId;
  final CustomerDetail? selectedDetail;
  final bool loadingDetail;

  const CustomersState({
    required this.loading,
    required this.error,
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.search,
    this.productId,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.selectedCustomerId,
    this.selectedDetail,
    required this.loadingDetail,
  });

  factory CustomersState.initial() {
    return const CustomersState(
      loading: false,
      error: null,
      items: <CustomerEnriched>[],
      total: 0,
      limit: 30,
      offset: 0,
      search: '',
      productId: null,
      status: null,
      dateFrom: null,
      dateTo: null,
      selectedCustomerId: null,
      selectedDetail: null,
      loadingDetail: false,
    );
  }

  CustomersState copyWith({
    bool? loading,
    String? error,
    List<CustomerEnriched>? items,
    int? total,
    int? limit,
    int? offset,
    String? search,
    String? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? selectedCustomerId,
    CustomerDetail? selectedDetail,
    bool? loadingDetail,
  }) {
    return CustomersState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      search: search ?? this.search,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      selectedDetail: selectedDetail ?? this.selectedDetail,
      loadingDetail: loadingDetail ?? this.loadingDetail,
    );
  }

  CustomersState clearFilters() {
    return CustomersState(
      loading: loading,
      error: error,
      items: items,
      total: total,
      limit: limit,
      offset: offset,
      search: '',
      productId: null,
      status: null,
      dateFrom: null,
      dateTo: null,
      selectedCustomerId: selectedCustomerId,
      selectedDetail: selectedDetail,
      loadingDetail: loadingDetail,
    );
  }
}
