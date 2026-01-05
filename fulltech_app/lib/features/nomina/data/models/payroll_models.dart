// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_models.freezed.dart';
part 'payroll_models.g.dart';

enum PayrollHalf {
  @JsonValue('FIRST')
  first,
  @JsonValue('SECOND')
  second,
}

enum PayrollRunStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('REVIEW')
  review,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('PAID')
  paid,
  @JsonValue('CLOSED')
  closed,
}

enum PayrollEmployeeStatus {
  @JsonValue('READY')
  ready,
  @JsonValue('NEEDS_REVIEW')
  needsReview,
  @JsonValue('LOCKED')
  locked,
}

enum PayrollLineItemType {
  @JsonValue('EARNING')
  earning,
  @JsonValue('DEDUCTION')
  deduction,
}

@freezed
class PayrollPeriod with _$PayrollPeriod {
  const factory PayrollPeriod({
    required String id,
    @JsonKey(name: 'year') required int year,
    @JsonKey(name: 'month') required int month,
    @JsonKey(name: 'half') required PayrollHalf half,
    @JsonKey(name: 'date_from') required DateTime dateFrom,
    @JsonKey(name: 'date_to') required DateTime dateTo,
    @JsonKey(name: 'status') String? status,
  }) = _PayrollPeriod;

  factory PayrollPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayrollPeriodFromJson(json);
}

@freezed
class PayrollRunTotals with _$PayrollRunTotals {
  const factory PayrollRunTotals({
    required double gross,
    required double deductions,
    required double net,
  }) = _PayrollRunTotals;

  factory PayrollRunTotals.fromJson(Map<String, dynamic> json) =>
      _$PayrollRunTotalsFromJson(json);
}

@freezed
class PayrollRunListItem with _$PayrollRunListItem {
  const factory PayrollRunListItem({
    required String id,
    required PayrollRunStatus status,
    PayrollPeriod? period,
    PayrollRunTotals? totals,
    @JsonKey(name: 'employeesCount') int? employeesCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    String? notes,
  }) = _PayrollRunListItem;

  factory PayrollRunListItem.fromJson(Map<String, dynamic> json) =>
      _$PayrollRunListItemFromJson(json);
}

@freezed
class PayrollEmployee with _$PayrollEmployee {
  const factory PayrollEmployee({
    required String id,
    @JsonKey(name: 'nombre_completo') required String nombreCompleto,
    required String email,
    @JsonKey(name: 'rol') required String rol,
    @JsonKey(name: 'foto_perfil_url') String? fotoPerfilUrl,
    @JsonKey(name: 'salario_mensual') double? salarioMensual,
  }) = _PayrollEmployee;

  factory PayrollEmployee.fromJson(Map<String, dynamic> json) =>
      _$PayrollEmployeeFromJson(json);
}

@freezed
class PayrollLineItem with _$PayrollLineItem {
  const factory PayrollLineItem({
    required String id,
    required PayrollLineItemType type,
    @JsonKey(name: 'concept_code') required String conceptCode,
    @JsonKey(name: 'concept_name') required String conceptName,
    required double amount,
  }) = _PayrollLineItem;

  factory PayrollLineItem.fromJson(Map<String, dynamic> json) =>
      _$PayrollLineItemFromJson(json);
}

@freezed
class PayrollEmployeeSummary with _$PayrollEmployeeSummary {
  const factory PayrollEmployeeSummary({
    required String id,
    @JsonKey(name: 'employee_user_id') required String employeeUserId,
    required PayrollEmployee employee,
    @JsonKey(name: 'base_salary_amount') required double baseSalaryAmount,
    @JsonKey(name: 'commissions_amount') required double commissionsAmount,
    @JsonKey(name: 'other_earnings_amount') required double otherEarningsAmount,
    @JsonKey(name: 'gross_amount') required double grossAmount,
    @JsonKey(name: 'statutory_deductions_amount')
    required double statutoryDeductionsAmount,
    @JsonKey(name: 'other_deductions_amount') required double otherDeductionsAmount,
    @JsonKey(name: 'net_amount') required double netAmount,
    required String currency,
    required PayrollEmployeeStatus status,
    @JsonKey(name: 'line_items') required List<PayrollLineItem> lineItems,
  }) = _PayrollEmployeeSummary;

  factory PayrollEmployeeSummary.fromJson(Map<String, dynamic> json) =>
      _$PayrollEmployeeSummaryFromJson(json);
}

@freezed
class PayrollRunUser with _$PayrollRunUser {
  const factory PayrollRunUser({
    required String id,
    @JsonKey(name: 'nombre_completo') required String nombreCompleto,
    required String email,
  }) = _PayrollRunUser;

  factory PayrollRunUser.fromJson(Map<String, dynamic> json) =>
      _$PayrollRunUserFromJson(json);
}

@freezed
class PayrollRunDetail with _$PayrollRunDetail {
  const factory PayrollRunDetail({
    required String id,
    required PayrollRunStatus status,
    required PayrollPeriod period,
    @JsonKey(name: 'created_by') PayrollRunUser? createdBy,
    @JsonKey(name: 'approved_by') PayrollRunUser? approvedBy,
    @JsonKey(name: 'paid_by') PayrollRunUser? paidBy,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'employee_summaries') required List<PayrollEmployeeSummary> employeeSummaries,
    String? notes,
  }) = _PayrollRunDetail;

  factory PayrollRunDetail.fromJson(Map<String, dynamic> json) =>
      _$PayrollRunDetailFromJson(json);
}

@freezed
class PayrollRunDetailResponse with _$PayrollRunDetailResponse {
  const factory PayrollRunDetailResponse({
    required PayrollRunDetail run,
    required Map<String, dynamic> totals,
  }) = _PayrollRunDetailResponse;

  factory PayrollRunDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PayrollRunDetailResponseFromJson(json);
}

@freezed
class MyPayrollHistoryItem with _$MyPayrollHistoryItem {
  const factory MyPayrollHistoryItem({
    required String runId,
    required PayrollRunStatus status,
    required PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'net_amount') required double netAmount,
    @JsonKey(name: 'gross_amount') required double grossAmount,
    required String currency,
  }) = _MyPayrollHistoryItem;

  factory MyPayrollHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$MyPayrollHistoryItemFromJson(json);
}

@freezed
class MyPayrollHistoryResponse with _$MyPayrollHistoryResponse {
  const factory MyPayrollHistoryResponse({
    required List<MyPayrollHistoryItem> items,
  }) = _MyPayrollHistoryResponse;

  factory MyPayrollHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$MyPayrollHistoryResponseFromJson(json);
}

@freezed
class PayrollPayslip with _$PayrollPayslip {
  const factory PayrollPayslip({
    required String id,
    @JsonKey(name: 'pdf_url') String? pdfUrl,
    required Map<String, dynamic> snapshot,
  }) = _PayrollPayslip;

  factory PayrollPayslip.fromJson(Map<String, dynamic> json) =>
      _$PayrollPayslipFromJson(json);
}

@freezed
class MyPayrollDetailRun with _$MyPayrollDetailRun {
  const factory MyPayrollDetailRun({
    required String id,
    required PayrollRunStatus status,
    required PayrollPeriod period,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
  }) = _MyPayrollDetailRun;

  factory MyPayrollDetailRun.fromJson(Map<String, dynamic> json) =>
      _$MyPayrollDetailRunFromJson(json);
}

@freezed
class MyPayrollDetailResponse with _$MyPayrollDetailResponse {
  const factory MyPayrollDetailResponse({
    required MyPayrollDetailRun run,
    required PayrollPayslip payslip,
  }) = _MyPayrollDetailResponse;

  factory MyPayrollDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MyPayrollDetailResponseFromJson(json);
}

@freezed
class PayrollNotificationItem with _$PayrollNotificationItem {
  const factory PayrollNotificationItem({
    required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? runId,
    String? pdfUrl,
    required String message,
  }) = _PayrollNotificationItem;

  factory PayrollNotificationItem.fromJson(Map<String, dynamic> json) =>
      _$PayrollNotificationItemFromJson(json);
}

@freezed
class PayrollNotificationsResponse with _$PayrollNotificationsResponse {
  const factory PayrollNotificationsResponse({
    required List<PayrollNotificationItem> items,
  }) = _PayrollNotificationsResponse;

  factory PayrollNotificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$PayrollNotificationsResponseFromJson(json);
}
