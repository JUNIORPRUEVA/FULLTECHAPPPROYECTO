import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/app_config.dart';
import '../../../../core/storage/local_db.dart';
import '../datasources/payroll_remote_datasource.dart';
import '../models/payroll_models.dart';

class PayrollRepository {
  final PayrollRemoteDataSource _remote;
  final LocalDb _db;
  final Dio _dio;

  PayrollRepository(this._remote, this._db, this._dio);

  static const _storeAdminRuns = 'payroll_admin_runs_v1';
  static const _storeAdminRunDetail = 'payroll_admin_run_detail_v1';
  static const _storeMyHistory = 'payroll_my_history_v1';
  static const _storeMyDetail = 'payroll_my_detail_v1';
  static const _storeMyNotifications = 'payroll_my_notifications_v1';

  // --- Admin runs
  Future<List<PayrollRunListItem>> readCachedAdminRuns() async {
    final list = await _db.listEntitiesJson(store: _storeAdminRuns);
    return list
        .map((j) => PayrollRunListItem.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  Future<List<PayrollRunListItem>> fetchAdminRuns() async {
    final items = await _remote.listRuns();
    for (final it in items) {
      await _db.upsertEntity(
        store: _storeAdminRuns,
        id: it.id,
        json: jsonEncode(it.toJson()),
      );
    }
    return items;
  }

  Future<PayrollRunDetailResponse?> readCachedRunDetail(String runId) async {
    final list = await _db.listEntitiesJson(store: _storeAdminRunDetail);
    for (final j in list) {
      final map = jsonDecode(j) as Map<String, dynamic>;
      if (map['run'] is Map && (map['run'] as Map)['id'] == runId) {
        return PayrollRunDetailResponse.fromJson(map);
      }
    }
    return null;
  }

  Future<PayrollRunDetailResponse> fetchRunDetail(String runId) async {
    final detail = await _remote.getRun(runId);
    await _db.upsertEntity(
      store: _storeAdminRunDetail,
      id: runId,
      json: jsonEncode(detail.toJson()),
    );
    return detail;
  }

  Future<void> ensureCurrentPeriods({int? year, int? month}) =>
      _remote.ensureCurrentPeriods(year: year, month: month);

  Future<String> createRun({
    required int year,
    required int month,
    required PayrollHalf half,
    String? notes,
  }) => _remote.createRun(year: year, month: month, half: half, notes: notes);

  Future<void> importMovements(String runId) => _remote.importMovements(runId);
  Future<void> recalculate(String runId) => _remote.recalculate(runId);
  Future<void> approve(String runId) => _remote.approve(runId);
  Future<void> markPaid(String runId) => _remote.markPaid(runId);

  // --- Employee
  Future<MyPayrollHistoryResponse?> readCachedMyHistory() async {
    final list = await _db.listEntitiesJson(store: _storeMyHistory);
    if (list.isEmpty) return null;

    // Store as single synthetic doc
    final map = jsonDecode(list.first) as Map<String, dynamic>;
    return MyPayrollHistoryResponse.fromJson(map);
  }

  Future<MyPayrollHistoryResponse> fetchMyHistory() async {
    final res = await _remote.myHistory();
    await _db.clearStore(store: _storeMyHistory);
    await _db.upsertEntity(
      store: _storeMyHistory,
      id: 'history',
      json: jsonEncode(res.toJson()),
    );
    return res;
  }

  Future<MyPayrollDetailResponse?> readCachedMyDetail(String runId) async {
    final list = await _db.listEntitiesJson(store: _storeMyDetail);
    for (final j in list) {
      final map = jsonDecode(j) as Map<String, dynamic>;
      if (map['run'] is Map && (map['run'] as Map)['id'] == runId) {
        return MyPayrollDetailResponse.fromJson(map);
      }
    }
    return null;
  }

  Future<MyPayrollDetailResponse> fetchMyDetail(String runId) async {
    final res = await _remote.myDetail(runId);
    await _db.upsertEntity(
      store: _storeMyDetail,
      id: runId,
      json: jsonEncode(res.toJson()),
    );
    return res;
  }

  Future<PayrollNotificationsResponse?> readCachedMyNotifications() async {
    final list = await _db.listEntitiesJson(store: _storeMyNotifications);
    if (list.isEmpty) return null;
    final map = jsonDecode(list.first) as Map<String, dynamic>;
    return PayrollNotificationsResponse.fromJson(map);
  }

  Future<PayrollNotificationsResponse> fetchMyNotifications() async {
    final res = await _remote.myNotifications();
    await _db.clearStore(store: _storeMyNotifications);
    await _db.upsertEntity(
      store: _storeMyNotifications,
      id: 'notifications',
      json: jsonEncode(res.toJson()),
    );
    return res;
  }

  // --- PDF
  static String _publicBase() {
    final base = AppConfig.apiBaseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String resolvePublicUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '${_publicBase()}$trimmed';
    return '${_publicBase()}/$trimmed';
  }

  Future<String> downloadPayslipPdfToTempFile({
    required String url,
    required String fileName,
  }) async {
    final fullUrl = resolvePublicUrl(url);

    final res = await _dio.get<List<int>>(
      fullUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = res.data;
    if (bytes == null) throw Exception('No PDF bytes returned');

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'fulltech_cache', 'payroll_pdfs'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
    final file = File(p.join(folder.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
