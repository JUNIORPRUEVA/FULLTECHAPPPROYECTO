import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulltech_app/core/models/app_user.dart';
import 'package:fulltech_app/core/services/auth_api.dart';
import 'package:fulltech_app/core/storage/auth_session.dart';
import 'package:fulltech_app/core/storage/local_db_interface.dart';
import 'package:fulltech_app/core/storage/sync_queue_item.dart';
import 'package:fulltech_app/features/auth/state/auth_controller.dart';
import 'package:fulltech_app/features/auth/state/auth_state.dart';

class TestLocalDb implements LocalDb {
  AuthSession? session;
  int saveSessionCalls = 0;
  int readSessionCalls = 0;
  int clearSessionCalls = 0;
  
  // Simulate slow storage read (e.g., secure storage on Windows)
  Duration readDelay = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(AuthSession session) async {
    saveSessionCalls += 1;
    this.session = session;
  }

  @override
  Future<AuthSession?> readSession() async {
    readSessionCalls += 1;
    if (readDelay > Duration.zero) {
      await Future.delayed(readDelay);
    }
    return session;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
    session = null;
  }

  // === Unused interface members ===
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
  Future<List<String>> listEntitiesJson({required String store}) async => const [];

  @override
  Future<String?> getEntityJson({
    required String store,
    required String id,
  }) async => null;

  @override
  Future<void> deleteEntity({required String store, required String id}) async {}

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
  Future<Map<String, Object?>?> getCotizacion({required String id}) async => null;

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
  Future<Map<String, Object?>?> getSalesRecord({required String id}) async => null;

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
  Future<Map<String, Object?>?> getOperationsJob({required String id}) async => null;

  @override
  Future<void> markOperationsJobDeleted({
    required String id,
    required String deletedAtIso,
  }) async {}

  @override
  Future<void> upsertOperationsSurvey({required Map<String, Object?> row}) async {}

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
  Future<void> upsertOperationsSchedule({required Map<String, Object?> row}) async {}

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

Dio buildTestDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/auth/me') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'user': {
                  'id': 'u1',
                  'empresa_id': 'e1',
                  'email': 'test@example.com',
                  'name': 'Test User',
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
  group('Auth Bootstrap Race Condition', () {
    test('Multiple concurrent bootstrap calls should not cause issues', () async {
      final db = TestLocalDb();
      // Simulate slow storage read (common on Windows desktop with secure storage)
      db.readDelay = const Duration(milliseconds: 100);
      
      // Pre-populate a session
      final testUser = AppUser(
        id: 'u1',
        empresaId: 'e1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'admin',
      );
      db.session = AuthSession(token: 'test-token-123', user: testUser);

      final api = AuthApi(buildTestDio());
      final controller = AuthController(db: db, getApi: () => api);

      // Simulate the race condition: two bootstrap calls at the same time
      // This mimics what happens when:
      // 1. Initial bootstrap is scheduled
      // 2. apiEndpointSettingsProvider initializes and triggers another bootstrap
      final bootstrap1 = controller.bootstrap();
      final bootstrap2 = controller.bootstrap();
      final bootstrap3 = controller.bootstrap();

      // Wait for all to complete
      await Future.wait([bootstrap1, bootstrap2, bootstrap3]);

      // Verify state is correct (authenticated)
      expect(controller.state, isA<AuthAuthenticated>());
      final authedState = controller.state as AuthAuthenticated;
      expect(authedState.token, 'test-token-123');
      expect(authedState.user.email, 'test@example.com');

      // Verify session was not cleared
      expect(db.clearSessionCalls, 0);
      
      // Verify we only read from storage once (not multiple times)
      // The guard should prevent concurrent reads
      expect(db.readSessionCalls, 1);
    });

    test('Bootstrap during ongoing bootstrap waits for completion', () async {
      final db = TestLocalDb();
      db.readDelay = const Duration(milliseconds: 50);
      
      final testUser = AppUser(
        id: 'u1',
        empresaId: 'e1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'admin',
      );
      db.session = AuthSession(token: 'test-token-456', user: testUser);

      final api = AuthApi(buildTestDio());
      final controller = AuthController(db: db, getApi: () => api);

      // Start first bootstrap
      final bootstrap1Future = controller.bootstrap();
      
      // Let it start but not complete
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Try to start second bootstrap while first is still running
      final bootstrap2Future = controller.bootstrap();
      
      // Both should complete successfully
      await Future.wait([bootstrap1Future, bootstrap2Future]);

      // Verify state is correct
      expect(controller.state, isA<AuthAuthenticated>());
      
      // Verify we only read once (second call waited for first)
      expect(db.readSessionCalls, 1);
    });

    test('Bootstrap with no session transitions to unauthenticated', () async {
      final db = TestLocalDb();
      // No session stored
      db.session = null;

      final api = AuthApi(buildTestDio());
      final controller = AuthController(db: db, getApi: () => api);

      await controller.bootstrap();

      expect(controller.state, isA<AuthUnauthenticated>());
      expect(db.clearSessionCalls, 0);
    });

    test('Bootstrap with valid session transitions to authenticated', () async {
      final db = TestLocalDb();
      
      final testUser = AppUser(
        id: 'u1',
        empresaId: 'e1',
        email: 'valid@example.com',
        name: 'Valid User',
        role: 'user',
      );
      db.session = AuthSession(token: 'valid-token-789', user: testUser);

      final api = AuthApi(buildTestDio());
      final controller = AuthController(db: db, getApi: () => api);

      // Initially unknown
      expect(controller.state, isA<AuthUnknown>());

      await controller.bootstrap();

      // After bootstrap, should be authenticated
      expect(controller.state, isA<AuthAuthenticated>());
      final authedState = controller.state as AuthAuthenticated;
      expect(authedState.token, 'valid-token-789');
      expect(authedState.user.email, 'valid@example.com');
    });
  });
}
