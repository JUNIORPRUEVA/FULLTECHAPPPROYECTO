import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulltech_app/core/services/http_offline_cache.dart';
import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/core/storage/auth_session.dart';
import 'package:fulltech_app/core/storage/sync_queue_item.dart';

class _FakeDb implements LocalDb {
  final Map<String, Map<String, String>> _stores = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(AuthSession session) async {}

  @override
  Future<AuthSession?> readSession() async => null;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> enqueueSync({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  }) async {}

  @override
  Future<void> updateQueuedSyncPayload({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  }) async {}

  @override
  Future<void> cancelQueuedSync({
    required String module,
    required String entityId,
  }) async {}

  @override
  Future<void> retryErroredSyncItems({
    String? module,
    Duration minAge = const Duration(seconds: 30),
  }) async {}

  @override
  Future<List<SyncQueueItem>> getPendingSyncItems() async => const [];

  @override
  Future<void> markSyncItemSent(String id) async {}

  @override
  Future<void> markSyncItemError(String id) async {}

  @override
  Future<void> upsertEntity({
    required String store,
    required String id,
    required String json,
  }) async {
    final s = _stores.putIfAbsent(store, () => {});
    s[id] = json;
  }

  @override
  Future<void> upsertEntityDirect({
    required String store,
    required String id,
    required String json,
  }) async {
    await upsertEntity(store: store, id: id, json: json);
  }

  @override
  Future<List<String>> listEntitiesJson({required String store}) async {
    final s = _stores[store];
    if (s == null) return const [];
    return s.values.toList();
  }

  @override
  Future<String?> getEntityJson({
    required String store,
    required String id,
  }) async {
    return _stores[store]?[id];
  }

  @override
  Future<void> deleteEntity({required String store, required String id}) async {
    _stores[store]?.remove(id);
  }

  @override
  Future<void> clearStore({required String store}) async {
    _stores.remove(store);
  }

  @override
  Future<void> clearStoreDirect({required String store}) async {
    await clearStore(store: store);
  }

  // The remaining APIs are not used by this test.
  @override
  Future<void> upsertCotizacion({required Map<String, Object?> row}) async =>
      throw UnimplementedError();

  @override
  Future<void> replaceCotizacionItems({
    required String quotationId,
    required List<Map<String, Object?>> items,
  }) async => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listCotizaciones({
    required String empresaId,
    String? q,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getCotizacion({required String id}) async =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listCotizacionItems({
    required String quotationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteCotizacion({required String id}) async =>
      throw UnimplementedError();

  @override
  Future<void> savePresupuestoDraft({
    required String draftKey,
    required String draftJson,
  }) async => throw UnimplementedError();

  @override
  Future<String?> loadPresupuestoDraftJson({required String draftKey}) async =>
      throw UnimplementedError();

  @override
  Future<void> clearPresupuestoDraft({required String draftKey}) async =>
      throw UnimplementedError();

  @override
  Future<void> upsertCarta({required Map<String, Object?> row}) async =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listCartas({
    required String empresaId,
    String? q,
    String? letterType,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getCarta({required String id}) async =>
      throw UnimplementedError();

  @override
  Future<void> markCartaDeleted({
    required String id,
    required String deletedAtIso,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertSalesRecord({required Map<String, Object?> row}) async =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listSalesRecords({
    required String empresaId,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getSalesRecord({required String id}) async =>
      throw UnimplementedError();

  @override
  Future<void> markSalesRecordDeleted({
    required String id,
    required String deletedAtIso,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertSalesEvidence({required Map<String, Object?> row}) async =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listSalesEvidence({
    required String saleId,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertOperationsJob({required Map<String, Object?> row}) async =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listOperationsJobs({
    required String empresaId,
    String? q,
    String? status,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getOperationsJob({required String id}) async =>
      throw UnimplementedError();

  @override
  Future<void> markOperationsJobDeleted({
    required String id,
    required String deletedAtIso,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertOperationsSurvey({
    required Map<String, Object?> row,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getOperationsSurveyByJob({
    required String jobId,
  }) async => throw UnimplementedError();

  @override
  Future<void> replaceOperationsSurveyMedia({
    required String surveyId,
    required List<Map<String, Object?>> items,
  }) async => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listOperationsSurveyMedia({
    required String surveyId,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertOperationsSchedule({
    required Map<String, Object?> row,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, Object?>?> getOperationsScheduleByJob({
    required String jobId,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertOperationsInstallationReport({
    required Map<String, Object?> row,
  }) async => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listOperationsInstallationReports({
    required String jobId,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertOperationsWarrantyTicket({
    required Map<String, Object?> row,
  }) async => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> listOperationsWarrantyTickets({
    required String jobId,
  }) async => throw UnimplementedError();
}

void main() {
  test('HttpOfflineCache stores and retrieves GET JSON responses', () async {
    final db = _FakeDb();

    final options = RequestOptions(
      baseUrl: 'https://example.com/api',
      path: '/items',
      method: 'GET',
      queryParameters: {'q': 'abc', 'limit': 10},
      responseType: ResponseType.json,
    );

    final data = {
      'items': [
        {'id': '1', 'name': 'A'},
        {'id': '2', 'name': 'B'},
      ],
    };

    await HttpOfflineCache.put(db, options, data);
    final cached = await HttpOfflineCache.get(db, options);

    expect(cached, isA<Map>());
    expect((cached as Map)['items'], isA<List>());
  });
}
