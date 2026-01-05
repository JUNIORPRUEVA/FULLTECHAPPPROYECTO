import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../data/datasources/payroll_remote_datasource.dart';
import '../data/repositories/payroll_repository.dart';
import 'payroll_runs_controller.dart';
import 'my_payroll_controller.dart';

final payrollRemoteDataSourceProvider = Provider<PayrollRemoteDataSource>((ref) {
  return PayrollRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(
    ref.watch(payrollRemoteDataSourceProvider),
    ref.watch(localDbProvider),
    ref.watch(apiClientProvider).dio,
  );
});

final payrollRunsControllerProvider = StateNotifierProvider<PayrollRunsController, PayrollRunsState>((ref) {
  return PayrollRunsController(repo: ref.watch(payrollRepositoryProvider));
});

final myPayrollControllerProvider = StateNotifierProvider<MyPayrollController, MyPayrollState>((ref) {
  return MyPayrollController(repo: ref.watch(payrollRepositoryProvider));
});
