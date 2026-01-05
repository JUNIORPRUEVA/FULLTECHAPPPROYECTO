import '../../../core/routing/app_routes.dart';

class AccountingRoutes {
  AccountingRoutes._();

  static const root = AppRoutes.contabilidad;

  static const payrollEntry = '${AppRoutes.contabilidad}/payroll';
  static const biweeklyClose = '${AppRoutes.contabilidad}/biweekly-close';
  static const expenses = '${AppRoutes.contabilidad}/expenses';
  static const incomePayments = '${AppRoutes.contabilidad}/income-payments';
  static const reports = '${AppRoutes.contabilidad}/reports';
  static const categories = '${AppRoutes.contabilidad}/categories';
}
