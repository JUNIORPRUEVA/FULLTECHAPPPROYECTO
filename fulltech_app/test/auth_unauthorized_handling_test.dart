import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulltech_app/core/services/auth_api.dart';
import 'package:fulltech_app/core/services/auth_events.dart';
import 'package:fulltech_app/core/storage/auth_session.dart';
import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/core/storage/sync_queue_item.dart';
import 'package:fulltech_app/features/auth/state/auth_controller.dart';
import 'package:fulltech_app/features/auth/state/auth_state.dart';

class FakeLocalDb implements LocalDb {
  AuthSession? session;
  int clearSessionCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(AuthSession session) async {
    this.session = session;
  }

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
    session = null;
  }

  // === Unused interface members in these tests ===
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
  }) async {}

  @override
  Future<void> upsertEntityDirect({
    required String store,
    required String id,
    required String json,
  }) async {}

  @override
  Future<List<String>> listEntitiesJson({required String store}) async =>
      const [];

  @override
  Future<String?> getEntityJson({
    required String store,
    required String id,
  }) async => null;

  @override
  Future<void> deleteEntity({
    required String store,
    required String id,
  }) async {}

  @override
  Future<void> clearStore({required String store}) async {}

  @override
  Future<void> clearStoreDirect({required String store}) async {}

  @override
  Future<void> upsertCotizacion({required Map<String, Object?> row}) async {}

  @override
  Future<void> replaceCotizacionItems({
    required String quotationId,
    required List<Map<String, Object?>> items,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> listCotizaciones({
    required String empresaId,
    String? q,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => const [];

  @override
  Future<Map<String, Object?>?> getCotizacion({required String id}) async =>
      null;

  @override
  Future<List<Map<String, Object?>>> listCotizacionItems({
    required String quotationId,
  }) async => const [];

  @override
  Future<void> deleteCotizacion({required String id}) async {}

  @override
  Future<void> savePresupuestoDraft({
    required String draftKey,
    required String draftJson,
  }) async {}

  @override
  Future<String?> loadPresupuestoDraftJson({required String draftKey}) async =>
      null;

  @override
  Future<void> clearPresupuestoDraft({required String draftKey}) async {}

  @override
  Future<void> upsertCarta({required Map<String, Object?> row}) async {}

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
  }) async => const [];

  @override
  Future<Map<String, Object?>?> getCarta({required String id}) async => null;

  @override
  Future<void> markCartaDeleted({
    required String id,
    required String deletedAtIso,
  }) async {}

  @override
  Future<void> upsertSalesRecord({required Map<String, Object?> row}) async {}

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
  }) async => const [];

  @override
  Future<Map<String, Object?>?> getSalesRecord({required String id}) async =>
      null;

  @override
  Future<void> markSalesRecordDeleted({
    required String id,
    required String deletedAtIso,
  }) async {}

  @override
  Future<void> upsertSalesEvidence({required Map<String, Object?> row}) async {}

  @override
  Future<List<Map<String, Object?>>> listSalesEvidence({
    required String saleId,
  }) async => const [];

  @override
  Future<void> upsertOperationsJob({required Map<String, Object?> row}) async {}

  @override
  Future<List<Map<String, Object?>>> listOperationsJobs({
    required String empresaId,
    String? q,
    String? status,
    String? assignedTechId,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async => const [];

  @override
  Future<Map<String, Object?>?> getOperationsJob({required String id}) async =>
      null;

  @override
  Future<void> markOperationsJobDeleted({
    required String id,
    required String deletedAtIso,
  }) async {}

  @override
  Future<void> upsertOperationsSurvey({
    required Map<String, Object?> row,
  }) async {}

  @override
  Future<Map<String, Object?>?> getOperationsSurveyByJob({
    required String jobId,
  }) async => null;

  @override
  Future<void> replaceOperationsSurveyMedia({
    required String surveyId,
    required List<Map<String, Object?>> items,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> listOperationsSurveyMedia({
    required String surveyId,
  }) async => const [];

  @override
  Future<void> upsertOperationsSchedule({
    required Map<String, Object?> row,
  }) async {}

  @override
  Future<Map<String, Object?>?> getOperationsScheduleByJob({
    required String jobId,
  }) async => null;

  @override
  Future<void> upsertOperationsInstallationReport({
    required Map<String, Object?> row,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> listOperationsInstallationReports({
    required String jobId,
  }) async => const [];

  @override
  Future<void> upsertOperationsWarrantyTicket({
    required Map<String, Object?> row,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> listOperationsWarrantyTickets({
    required String jobId,
  }) async => const [];
}

Dio buildFakeDio({required int meStatus}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/auth/login') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'token': 'token-1234567890',
                'user': {
                  'id': 'u1',
                  'empresa_id': 'e1',
                  'email': 'a@b.com',
                  'name': 'A',
                  'role': 'admin',
                },
              },
            ),
          );
          return;
        }

        if (options.path == '/auth/me') {
          if (meStatus == 200) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'user': {
                    'id': 'u1',
                    'empresa_id': 'e1',
                    'email': 'a@b.com',
                    'name': 'A',
                    'role': 'admin',
                  },
                },
              ),
            );
            return;
          }

          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: meStatus,
                data: {'message': 'unauthorized'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: 'unexpected path ${options.path}',
          ),
        );
      },
    ),
  );

  return dio;
}

void main() {
  test('Unauthorized event does not logout when /auth/me succeeds', () async {
    final db = FakeLocalDb();
    final api = AuthApi(buildFakeDio(meStatus: 200));
    final controller = AuthController(db: db, getApi: () => api);

    await controller.login(email: 'a@b.com', password: 'pw');
    expect(controller.state, isA<AuthAuthenticated>());

    AuthEvents.unauthorized(401, '401 GET /settings/permissions/me');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state, isA<AuthAuthenticated>());
    expect(db.clearSessionCalls, 0);
  });

  test('Unauthorized event logs out only when /auth/me returns 401', () async {
    final db = FakeLocalDb();
    final api = AuthApi(buildFakeDio(meStatus: 401));
    final controller = AuthController(db: db, getApi: () => api);

    await controller.login(email: 'a@b.com', password: 'pw');
    expect(controller.state, isA<AuthAuthenticated>());

    AuthEvents.unauthorized(401, '401 GET /crm/stream');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state, isA<AuthUnauthenticated>());
    expect(db.clearSessionCalls, 1);
  });
}
