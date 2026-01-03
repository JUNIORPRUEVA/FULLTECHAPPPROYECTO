import 'package:connectivity_plus/connectivity_plus.dart';

import '../storage/local_db.dart';

/// Synchronization skeleton (Local <-> Cloud).
///
/// This intentionally keeps the rules generic:
/// - If offline, changes are queued into `sync_queue`.
/// - When online, we push pending queue items.
///
/// TODO: Implement per-module strategies (conflict resolution, batching, retries).
class SyncService {
  final LocalDb _db;

  SyncService({
    required LocalDb db,
  }) : _db = db;

  Future<bool> get hasInternet async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> flushQueue() async {
    if (!await hasInternet) return;

    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      try {
        // TODO: Map module/op to actual REST endpoints.
        // Example (future):
        // - module=clientes, op=create => POST /clientes
        // - module=clientes, op=update => PUT /clientes/:id
        // - module=clientes, op=delete => DELETE /clientes/:id
        //
        // For now, we only mark as "sent".
        await _db.markSyncItemSent(item.id);
      } catch (_) {
        await _db.markSyncItemError(item.id);
      }
    }
  }
}
