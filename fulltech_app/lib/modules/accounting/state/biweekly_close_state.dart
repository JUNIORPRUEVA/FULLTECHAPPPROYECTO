import '../data/models/biweekly_close_model.dart';

class BiweeklyCloseState {
  final bool loading;
  final String? error;

  final String search;
  final DateTime? filterFrom;
  final DateTime? filterTo;

  final List<BiweeklyCloseModel> items;

  final double totalIncome;
  final double totalExpenses;
  final double totalPayrollPaid;
  final double totalNetProfit;

  const BiweeklyCloseState({
    required this.loading,
    required this.error,
    required this.search,
    required this.filterFrom,
    required this.filterTo,
    required this.items,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalPayrollPaid,
    required this.totalNetProfit,
  });

  factory BiweeklyCloseState.initial() {
    return const BiweeklyCloseState(
      loading: false,
      error: null,
      search: '',
      filterFrom: null,
      filterTo: null,
      items: [],
      totalIncome: 0,
      totalExpenses: 0,
      totalPayrollPaid: 0,
      totalNetProfit: 0,
    );
  }

  BiweeklyCloseState copyWith({
    bool? loading,
    String? error,
    String? search,
    DateTime? filterFrom,
    DateTime? filterTo,
    List<BiweeklyCloseModel>? items,
    double? totalIncome,
    double? totalExpenses,
    double? totalPayrollPaid,
    double? totalNetProfit,
  }) {
    return BiweeklyCloseState(
      loading: loading ?? this.loading,
      error: error,
      search: search ?? this.search,
      filterFrom: filterFrom ?? this.filterFrom,
      filterTo: filterTo ?? this.filterTo,
      items: items ?? this.items,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalPayrollPaid: totalPayrollPaid ?? this.totalPayrollPaid,
      totalNetProfit: totalNetProfit ?? this.totalNetProfit,
    );
  }
}
