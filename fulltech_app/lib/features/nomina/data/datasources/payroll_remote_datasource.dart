import 'package:dio/dio.dart';

import '../models/payroll_models.dart';

class PayrollRemoteDataSource {
  final Dio _dio;

  PayrollRemoteDataSource(this._dio);

  Future<void> ensureCurrentPeriods({int? year, int? month}) async {
    await _dio.post(
      '/payroll/periods/ensure-current',
      data: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
  }

  Future<String> createRun({
    required int year,
    required int month,
    required PayrollHalf half,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/payroll/runs',
      data: {
        'year': year,
        'month': month,
        'half': half == PayrollHalf.first ? 'FIRST' : 'SECOND',
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    final data = res.data;
    if (data is Map && data['runId'] is String) return data['runId'] as String;
    throw Exception('Respuesta inválida al crear corrida');
  }

  Future<List<PayrollRunListItem>> listRuns() async {
    final res = await _dio.get('/payroll/runs');
    final data = res.data;
    if (data is! Map) throw Exception('Respuesta inválida');

    final items = data['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((m) => PayrollRunListItem.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<PayrollRunDetailResponse> getRun(String runId) async {
    final res = await _dio.get('/payroll/runs/$runId');
    final data = res.data;
    if (data is! Map) throw Exception('Respuesta inválida');
    return PayrollRunDetailResponse.fromJson(data.cast<String, dynamic>());
  }

  Future<void> importMovements(String runId) async {
    await _dio.post('/payroll/runs/$runId/import-movements');
  }

  Future<void> recalculate(String runId) async {
    await _dio.post('/payroll/runs/$runId/recalculate');
  }

  Future<void> approve(String runId) async {
    await _dio.post('/payroll/runs/$runId/approve');
  }

  Future<void> markPaid(String runId) async {
    await _dio.post('/payroll/runs/$runId/mark-paid');
  }

  Future<MyPayrollHistoryResponse> myHistory() async {
    final res = await _dio.get('/my/payroll');
    final data = res.data;
    if (data is! Map) throw Exception('Respuesta inválida');
    return MyPayrollHistoryResponse.fromJson(data.cast<String, dynamic>());
  }

  Future<MyPayrollDetailResponse> myDetail(String runId) async {
    final res = await _dio.get('/my/payroll/$runId');
    final data = res.data;
    if (data is! Map) throw Exception('Respuesta inválida');
    return MyPayrollDetailResponse.fromJson(data.cast<String, dynamic>());
  }

  Future<PayrollNotificationsResponse> myNotifications() async {
    final res = await _dio.get('/my/payroll/notifications');
    final data = res.data;
    if (data is! Map) throw Exception('Respuesta inválida');
    return PayrollNotificationsResponse.fromJson(data.cast<String, dynamic>());
  }
}
