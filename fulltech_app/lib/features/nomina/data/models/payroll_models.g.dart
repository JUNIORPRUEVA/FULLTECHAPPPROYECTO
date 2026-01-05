// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PayrollPeriodImpl _$$PayrollPeriodImplFromJson(Map<String, dynamic> json) =>
    _$PayrollPeriodImpl(
      id: json['id'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      half: $enumDecode(_$PayrollHalfEnumMap, json['half']),
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$$PayrollPeriodImplToJson(_$PayrollPeriodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'year': instance.year,
      'month': instance.month,
      'half': _$PayrollHalfEnumMap[instance.half]!,
      'date_from': instance.dateFrom.toIso8601String(),
      'date_to': instance.dateTo.toIso8601String(),
      'status': instance.status,
    };

const _$PayrollHalfEnumMap = {
  PayrollHalf.first: 'FIRST',
  PayrollHalf.second: 'SECOND',
};

_$PayrollRunTotalsImpl _$$PayrollRunTotalsImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollRunTotalsImpl(
  gross: (json['gross'] as num).toDouble(),
  deductions: (json['deductions'] as num).toDouble(),
  net: (json['net'] as num).toDouble(),
);

Map<String, dynamic> _$$PayrollRunTotalsImplToJson(
  _$PayrollRunTotalsImpl instance,
) => <String, dynamic>{
  'gross': instance.gross,
  'deductions': instance.deductions,
  'net': instance.net,
};

_$PayrollRunListItemImpl _$$PayrollRunListItemImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollRunListItemImpl(
  id: json['id'] as String,
  status: $enumDecode(_$PayrollRunStatusEnumMap, json['status']),
  period: json['period'] == null
      ? null
      : PayrollPeriod.fromJson(json['period'] as Map<String, dynamic>),
  totals: json['totals'] == null
      ? null
      : PayrollRunTotals.fromJson(json['totals'] as Map<String, dynamic>),
  employeesCount: (json['employeesCount'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$PayrollRunListItemImplToJson(
  _$PayrollRunListItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': _$PayrollRunStatusEnumMap[instance.status]!,
  'period': instance.period,
  'totals': instance.totals,
  'employeesCount': instance.employeesCount,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'paid_at': instance.paidAt?.toIso8601String(),
  'notes': instance.notes,
};

const _$PayrollRunStatusEnumMap = {
  PayrollRunStatus.draft: 'DRAFT',
  PayrollRunStatus.review: 'REVIEW',
  PayrollRunStatus.approved: 'APPROVED',
  PayrollRunStatus.paid: 'PAID',
  PayrollRunStatus.closed: 'CLOSED',
};

_$PayrollEmployeeImpl _$$PayrollEmployeeImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollEmployeeImpl(
  id: json['id'] as String,
  nombreCompleto: json['nombre_completo'] as String,
  email: json['email'] as String,
  rol: json['rol'] as String,
  fotoPerfilUrl: json['foto_perfil_url'] as String?,
  salarioMensual: (json['salario_mensual'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$PayrollEmployeeImplToJson(
  _$PayrollEmployeeImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre_completo': instance.nombreCompleto,
  'email': instance.email,
  'rol': instance.rol,
  'foto_perfil_url': instance.fotoPerfilUrl,
  'salario_mensual': instance.salarioMensual,
};

_$PayrollLineItemImpl _$$PayrollLineItemImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollLineItemImpl(
  id: json['id'] as String,
  type: $enumDecode(_$PayrollLineItemTypeEnumMap, json['type']),
  conceptCode: json['concept_code'] as String,
  conceptName: json['concept_name'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$$PayrollLineItemImplToJson(
  _$PayrollLineItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$PayrollLineItemTypeEnumMap[instance.type]!,
  'concept_code': instance.conceptCode,
  'concept_name': instance.conceptName,
  'amount': instance.amount,
};

const _$PayrollLineItemTypeEnumMap = {
  PayrollLineItemType.earning: 'EARNING',
  PayrollLineItemType.deduction: 'DEDUCTION',
};

_$PayrollEmployeeSummaryImpl _$$PayrollEmployeeSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollEmployeeSummaryImpl(
  id: json['id'] as String,
  employeeUserId: json['employee_user_id'] as String,
  employee: PayrollEmployee.fromJson(json['employee'] as Map<String, dynamic>),
  baseSalaryAmount: (json['base_salary_amount'] as num).toDouble(),
  commissionsAmount: (json['commissions_amount'] as num).toDouble(),
  otherEarningsAmount: (json['other_earnings_amount'] as num).toDouble(),
  grossAmount: (json['gross_amount'] as num).toDouble(),
  statutoryDeductionsAmount: (json['statutory_deductions_amount'] as num)
      .toDouble(),
  otherDeductionsAmount: (json['other_deductions_amount'] as num).toDouble(),
  netAmount: (json['net_amount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: $enumDecode(_$PayrollEmployeeStatusEnumMap, json['status']),
  lineItems: (json['line_items'] as List<dynamic>)
      .map((e) => PayrollLineItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PayrollEmployeeSummaryImplToJson(
  _$PayrollEmployeeSummaryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'employee_user_id': instance.employeeUserId,
  'employee': instance.employee,
  'base_salary_amount': instance.baseSalaryAmount,
  'commissions_amount': instance.commissionsAmount,
  'other_earnings_amount': instance.otherEarningsAmount,
  'gross_amount': instance.grossAmount,
  'statutory_deductions_amount': instance.statutoryDeductionsAmount,
  'other_deductions_amount': instance.otherDeductionsAmount,
  'net_amount': instance.netAmount,
  'currency': instance.currency,
  'status': _$PayrollEmployeeStatusEnumMap[instance.status]!,
  'line_items': instance.lineItems,
};

const _$PayrollEmployeeStatusEnumMap = {
  PayrollEmployeeStatus.ready: 'READY',
  PayrollEmployeeStatus.needsReview: 'NEEDS_REVIEW',
  PayrollEmployeeStatus.locked: 'LOCKED',
};

_$PayrollRunUserImpl _$$PayrollRunUserImplFromJson(Map<String, dynamic> json) =>
    _$PayrollRunUserImpl(
      id: json['id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$$PayrollRunUserImplToJson(
  _$PayrollRunUserImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre_completo': instance.nombreCompleto,
  'email': instance.email,
};

_$PayrollRunDetailImpl _$$PayrollRunDetailImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollRunDetailImpl(
  id: json['id'] as String,
  status: $enumDecode(_$PayrollRunStatusEnumMap, json['status']),
  period: PayrollPeriod.fromJson(json['period'] as Map<String, dynamic>),
  createdBy: json['created_by'] == null
      ? null
      : PayrollRunUser.fromJson(json['created_by'] as Map<String, dynamic>),
  approvedBy: json['approved_by'] == null
      ? null
      : PayrollRunUser.fromJson(json['approved_by'] as Map<String, dynamic>),
  paidBy: json['paid_by'] == null
      ? null
      : PayrollRunUser.fromJson(json['paid_by'] as Map<String, dynamic>),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  employeeSummaries: (json['employee_summaries'] as List<dynamic>)
      .map((e) => PayrollEmployeeSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$PayrollRunDetailImplToJson(
  _$PayrollRunDetailImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': _$PayrollRunStatusEnumMap[instance.status]!,
  'period': instance.period,
  'created_by': instance.createdBy,
  'approved_by': instance.approvedBy,
  'paid_by': instance.paidBy,
  'paid_at': instance.paidAt?.toIso8601String(),
  'employee_summaries': instance.employeeSummaries,
  'notes': instance.notes,
};

_$PayrollRunDetailResponseImpl _$$PayrollRunDetailResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollRunDetailResponseImpl(
  run: PayrollRunDetail.fromJson(json['run'] as Map<String, dynamic>),
  totals: json['totals'] as Map<String, dynamic>,
);

Map<String, dynamic> _$$PayrollRunDetailResponseImplToJson(
  _$PayrollRunDetailResponseImpl instance,
) => <String, dynamic>{'run': instance.run, 'totals': instance.totals};

_$MyPayrollHistoryItemImpl _$$MyPayrollHistoryItemImplFromJson(
  Map<String, dynamic> json,
) => _$MyPayrollHistoryItemImpl(
  runId: json['runId'] as String,
  status: $enumDecode(_$PayrollRunStatusEnumMap, json['status']),
  period: PayrollPeriod.fromJson(json['period'] as Map<String, dynamic>),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  netAmount: (json['net_amount'] as num).toDouble(),
  grossAmount: (json['gross_amount'] as num).toDouble(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$$MyPayrollHistoryItemImplToJson(
  _$MyPayrollHistoryItemImpl instance,
) => <String, dynamic>{
  'runId': instance.runId,
  'status': _$PayrollRunStatusEnumMap[instance.status]!,
  'period': instance.period,
  'paid_at': instance.paidAt?.toIso8601String(),
  'net_amount': instance.netAmount,
  'gross_amount': instance.grossAmount,
  'currency': instance.currency,
};

_$MyPayrollHistoryResponseImpl _$$MyPayrollHistoryResponseImplFromJson(
  Map<String, dynamic> json,
) => _$MyPayrollHistoryResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => MyPayrollHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$MyPayrollHistoryResponseImplToJson(
  _$MyPayrollHistoryResponseImpl instance,
) => <String, dynamic>{'items': instance.items};

_$PayrollPayslipImpl _$$PayrollPayslipImplFromJson(Map<String, dynamic> json) =>
    _$PayrollPayslipImpl(
      id: json['id'] as String,
      pdfUrl: json['pdf_url'] as String?,
      snapshot: json['snapshot'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$PayrollPayslipImplToJson(
  _$PayrollPayslipImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'pdf_url': instance.pdfUrl,
  'snapshot': instance.snapshot,
};

_$MyPayrollDetailRunImpl _$$MyPayrollDetailRunImplFromJson(
  Map<String, dynamic> json,
) => _$MyPayrollDetailRunImpl(
  id: json['id'] as String,
  status: $enumDecode(_$PayrollRunStatusEnumMap, json['status']),
  period: PayrollPeriod.fromJson(json['period'] as Map<String, dynamic>),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
);

Map<String, dynamic> _$$MyPayrollDetailRunImplToJson(
  _$MyPayrollDetailRunImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': _$PayrollRunStatusEnumMap[instance.status]!,
  'period': instance.period,
  'paid_at': instance.paidAt?.toIso8601String(),
};

_$MyPayrollDetailResponseImpl _$$MyPayrollDetailResponseImplFromJson(
  Map<String, dynamic> json,
) => _$MyPayrollDetailResponseImpl(
  run: MyPayrollDetailRun.fromJson(json['run'] as Map<String, dynamic>),
  payslip: PayrollPayslip.fromJson(json['payslip'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$MyPayrollDetailResponseImplToJson(
  _$MyPayrollDetailResponseImpl instance,
) => <String, dynamic>{'run': instance.run, 'payslip': instance.payslip};

_$PayrollNotificationItemImpl _$$PayrollNotificationItemImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollNotificationItemImpl(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  runId: json['runId'] as String?,
  pdfUrl: json['pdfUrl'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$$PayrollNotificationItemImplToJson(
  _$PayrollNotificationItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'runId': instance.runId,
  'pdfUrl': instance.pdfUrl,
  'message': instance.message,
};

_$PayrollNotificationsResponseImpl _$$PayrollNotificationsResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollNotificationsResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => PayrollNotificationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PayrollNotificationsResponseImplToJson(
  _$PayrollNotificationsResponseImpl instance,
) => <String, dynamic>{'items': instance.items};
