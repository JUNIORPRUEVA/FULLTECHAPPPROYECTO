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

  Future<void> deleteEntity({
    required String store,
    required String id,
  });

  Future<void> clearStore({
    required String store,
  });
}

LocalDb createLocalDb() {
  throw UnimplementedError(
    'No LocalDb implementation available for this platform.',
  );
}
