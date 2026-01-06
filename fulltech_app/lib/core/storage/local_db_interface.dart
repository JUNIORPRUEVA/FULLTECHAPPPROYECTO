import 'auth_session.dart';
import 'sync_queue_item.dart';

abstract class LocalDb {
  Future<void> init();

  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clearSession();

  Future<void> enqueueSync({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  });

  /// Updates the payload for a pending queued item.
  ///
  /// Used when the user edits a local-only record that is still waiting to be
  /// created on the server.
  Future<void> updateQueuedSyncPayload({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  });

  /// Cancels (removes from pending queue) any queued sync items for an entity.
  ///
  /// Implementations should ensure cancelled items are not returned by
  /// `getPendingSyncItems()`.
  Future<void> cancelQueuedSync({
    required String module,
    required String entityId,
  });

  /// Re-queues previously errored items (status=2) back to pending (status=0).
  ///
  /// This keeps compatibility with the existing `sync_queue` table.
  /// Callers should throttle calls to avoid tight retry loops.
  Future<void> retryErroredSyncItems({
    String? module,
    Duration minAge = const Duration(seconds: 30),
  });

  Future<List<SyncQueueItem>> getPendingSyncItems();
  Future<void> markSyncItemSent(String id);
  Future<void> markSyncItemError(String id);

  /// Generic local cache store.
  ///
  /// This is used by offline-first modules to cache server snapshots locally.
  /// The `store` is a logical namespace (e.g. "catalog_products").
  Future<void> upsertEntity({
    required String store,
    required String id,
    required String json,
  });

  Future<List<String>> listEntitiesJson({
    required String store,
  });

  /// Reads a single cached entity JSON by id.
  ///
  /// Returns null when not found.
  Future<String?> getEntityJson({
    required String store,
    required String id,
  });

  Future<void> deleteEntity({
    required String store,
    required String id,
  });

  Future<void> clearStore({
    required String store,
  });

  // === Cotizaciones (local mirror tables) ===

  Future<void> upsertCotizacion({
    required Map<String, Object?> row,
  });

  Future<void> replaceCotizacionItems({
    required String quotationId,
    required List<Map<String, Object?>> items,
  });

  Future<List<Map<String, Object?>>> listCotizaciones({
    required String empresaId,
    String? q,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  });

  Future<Map<String, Object?>?> getCotizacion({
    required String id,
  });

  Future<List<Map<String, Object?>>> listCotizacionItems({
    required String quotationId,
  });

  Future<void> deleteCotizacion({
    required String id,
  });

  // === Presupuesto draft (local-only) ===

  /// Stores the current in-progress quotation draft for the user.
  ///
  /// This draft is local-only and exists to restore the Presupuesto screen
  /// when the user leaves and comes back.
  Future<void> savePresupuestoDraft({
    required String draftKey,
    required String draftJson,
  });

  Future<String?> loadPresupuestoDraftJson({
    required String draftKey,
  });

  Future<void> clearPresupuestoDraft({
    required String draftKey,
  });

  // === Cartas (letters) local mirror tables ===

  Future<void> upsertCarta({
    required Map<String, Object?> row,
  });

  Future<List<Map<String, Object?>>> listCartas({
    required String empresaId,
    String? q,
    String? letterType,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  });

  Future<Map<String, Object?>?> getCarta({
    required String id,
  });

  Future<void> markCartaDeleted({
    required String id,
    required String deletedAtIso,
  });

  // === Ventas (Sales) local mirror tables ===

  Future<void> upsertSalesRecord({
    required Map<String, Object?> row,
  });

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
  });

  Future<Map<String, Object?>?> getSalesRecord({
    required String id,
  });

  Future<void> markSalesRecordDeleted({
    required String id,
    required String deletedAtIso,
  });

  Future<void> upsertSalesEvidence({
    required Map<String, Object?> row,
  });

  Future<List<Map<String, Object?>>> listSalesEvidence({
    required String saleId,
  });

  // === Operaciones (Operations) local mirror tables ===

  Future<void> upsertOperationsJob({
    required Map<String, Object?> row,
  });

  Future<List<Map<String, Object?>>> listOperationsJobs({
    required String empresaId,
    String? q,
    String? status,
    String? assignedTechId,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  });

  Future<Map<String, Object?>?> getOperationsJob({
    required String id,
  });

  Future<void> markOperationsJobDeleted({
    required String id,
    required String deletedAtIso,
  });

  Future<void> upsertOperationsSurvey({
    required Map<String, Object?> row,
  });

  Future<Map<String, Object?>?> getOperationsSurveyByJob({
    required String jobId,
  });

  Future<void> replaceOperationsSurveyMedia({
    required String surveyId,
    required List<Map<String, Object?>> items,
  });

  Future<List<Map<String, Object?>>> listOperationsSurveyMedia({
    required String surveyId,
  });

  Future<void> upsertOperationsSchedule({
    required Map<String, Object?> row,
  });

  Future<Map<String, Object?>?> getOperationsScheduleByJob({
    required String jobId,
  });

  Future<void> upsertOperationsInstallationReport({
    required Map<String, Object?> row,
  });

  Future<List<Map<String, Object?>>> listOperationsInstallationReports({
    required String jobId,
  });

  Future<void> upsertOperationsWarrantyTicket({
    required Map<String, Object?> row,
  });

  Future<List<Map<String, Object?>>> listOperationsWarrantyTickets({
    required String jobId,
  });
}

LocalDb createLocalDb() {
  throw UnimplementedError(
    'No LocalDb implementation available for this platform.',
  );
}
