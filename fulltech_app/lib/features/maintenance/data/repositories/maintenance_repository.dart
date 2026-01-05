import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/storage/local_db_interface.dart';
import '../datasources/maintenance_remote_datasource.dart';
import '../models/maintenance_models.dart';

class MaintenanceRepository {
  final MaintenanceRemoteDataSource remoteDataSource;
  final LocalDb db;
  CancelToken? _cancelToken;

  static const String _storeMaintenance = 'maintenance_records';
  static const String _syncModule = 'maintenance';

  MaintenanceRepository(this.remoteDataSource, this.db);

  void cancelRequests() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      final msg = e.error?.toString() ?? '';
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        return true;
      }
    }
    final msg = e.toString();
    return msg.contains('SocketException') || msg.contains('Failed host lookup');
  }

  String _newLocalId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'local-$ms-${ms % 9973}';
  }

  Future<void> _upsertLocalMaintenance(
    MaintenanceRecord record, {
    Map<String, dynamic>? extra,
  }) async {
    final map = record.toJson();
    if (extra != null) {
      map.addAll(extra);
    }
    await db.upsertEntity(
      store: _storeMaintenance,
      id: record.id,
      json: jsonEncode(map),
    );
  }

  Future<Map<String, dynamic>?> _getLocalMaintenanceJsonById(String id) async {
    final rows = await db.listEntitiesJson(store: _storeMaintenance);
    for (final raw in rows) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if (m['id'] == id) return m;
      } catch (_) {
        // ignore
      }
    }
    return null;
  }

  bool _isLocalOnlyJson(Map<String, dynamic> m) {
    final id = (m['id'] as String?) ?? '';
    return id.startsWith('local-') || (m['_localOnly'] == true);
  }

  Map<String, dynamic> _snakeToLocalPatch(Map<String, dynamic> updates) {
    final patch = <String, dynamic>{};

    void mapKey(String snake, String camel) {
      if (updates.containsKey(snake)) patch[camel] = updates[snake];
    }

    mapKey('maintenance_type', 'maintenanceType');
    mapKey('status_before', 'statusBefore');
    mapKey('status_after', 'statusAfter');
    mapKey('issue_category', 'issueCategory');
    mapKey('description', 'description');
    mapKey('internal_notes', 'internalNotes');
    mapKey('cost', 'cost');
    mapKey('warranty_case_id', 'warrantyCaseId');
    mapKey('attachment_urls', 'attachmentUrls');

    return patch;
  }

  Map<String, dynamic> _buildCreateDtoPayloadFromLocalJson(
    Map<String, dynamic> local,
  ) {
    return <String, dynamic>{
      'productoId': local['productoId'],
      'maintenanceType': local['maintenanceType'],
      'statusBefore': local['statusBefore'],
      'statusAfter': local['statusAfter'],
      'issueCategory': local['issueCategory'],
      'description': local['description'],
      'internalNotes': local['internalNotes'],
      'cost': local['cost'],
      'warrantyCaseId': local['warrantyCaseId'],
      'attachmentUrls': (local['attachmentUrls'] as List?) ?? const [],
    };
  }

  bool _dateInRange(DateTime createdAt, {String? from, String? to}) {
    if (from == null && to == null) return true;
    final day = createdAt.toIso8601String().split('T')[0];
    if (from != null && day.compareTo(from) < 0) return false;
    if (to != null && day.compareTo(to) > 0) return false;
    return true;
  }

  bool _matchesSearch(MaintenanceRecord r, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return true;
    final productName = (r.producto?.nombre ?? '').toLowerCase();
    final productId = r.productoId.toLowerCase();
    final desc = r.description.toLowerCase();
    return productName.contains(query) ||
        productId.contains(query) ||
        desc.contains(query);
  }

  Future<List<Map<String, dynamic>>> _listLocalJsonMaps() async {
    final rows = await db.listEntitiesJson(store: _storeMaintenance);
    return rows
        .map((e) {
          try {
            return jsonDecode(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<List<MaintenanceRecord>> listLocalMaintenance({
    String? search,
    ProductHealthStatus? status,
    String? productoId,
    String? from,
    String? to,
  }) async {
    final maps = await _listLocalJsonMaps();
    final items = <MaintenanceRecord>[];
    for (final m in maps) {
      try {
        final r = MaintenanceRecord.fromJson(m);
        items.add(r);
      } catch (_) {
        // Ignore corrupt rows
      }
    }

    final filtered =
        items
            .where((r) => _dateInRange(r.createdAt, from: from, to: to))
            .where((r) => productoId == null ? true : r.productoId == productoId)
            .where((r) => status == null ? true : r.statusAfter == status)
            .where((r) => search == null ? true : _matchesSearch(r, search))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  Future<List<MaintenanceRecord>> listLocalPendingMaintenance({
    String? search,
    ProductHealthStatus? status,
    String? productoId,
    String? from,
    String? to,
  }) async {
    final maps = await _listLocalJsonMaps();
    final items = <MaintenanceRecord>[];
    for (final m in maps) {
      final id = (m['id'] as String?) ?? '';
      final isLocal = id.startsWith('local-') || (m['_localOnly'] == true);
      if (!isLocal) continue;
      try {
        final r = MaintenanceRecord.fromJson(m);
        items.add(r);
      } catch (_) {
        // ignore
      }
    }

    final filtered =
        items
            .where((r) => _dateInRange(r.createdAt, from: from, to: to))
            .where((r) => productoId == null ? true : r.productoId == productoId)
            .where((r) => status == null ? true : r.statusAfter == status)
            .where((r) => search == null ? true : _matchesSearch(r, search))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  /// Offline-first create:
  /// 1) write a local PENDING record to SQLite
  /// 2) enqueue sync
  /// 3) try to sync in background
  Future<MaintenanceRecord> createMaintenanceOfflineFirst(
    CreateMaintenanceDto dto,
  ) async {
    final session = await db.readSession();
    if (session == null) {
      throw StateError('No session');
    }

    final now = DateTime.now().toUtc();
    final localRecord = MaintenanceRecord(
      id: _newLocalId(),
      empresaId: session.user.empresaId,
      productoId: dto.productoId,
      createdByUserId: session.user.id,
      maintenanceType: dto.maintenanceType,
      statusBefore: dto.statusBefore,
      statusAfter: dto.statusAfter,
      issueCategory: dto.issueCategory,
      description: dto.description,
      internalNotes: dto.internalNotes,
      cost: dto.cost,
      warrantyCaseId: null,
      attachmentUrls: const [],
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      producto: null,
      createdBy: UserBasicInfo(
        id: session.user.id,
        nombreCompleto: session.user.name,
        email: session.user.email,
      ),
    );

    await _upsertLocalMaintenance(
      localRecord,
      extra: {
        '_localOnly': true,
        'syncStatus': 'PENDING',
        '_syncAttempts': 0,
        '_lastSyncAttemptMs': 0,
      },
    );

    await db.enqueueSync(
      module: _syncModule,
      op: 'create',
      entityId: localRecord.id,
      payloadJson: jsonEncode(dto.toJson()),
    );

    // Best-effort immediate sync (non-blocking for UI)
    // ignore: unawaited_futures
    syncPending();

    return localRecord;
  }

  /// Best-effort sync for queued maintenance ops.
  Future<void> syncPending() async {
    final items = await db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;

      try {
        // Update local attempt counters (best-effort)
        try {
          final localJson = await _getLocalMaintenanceJsonById(item.entityId);
          if (localJson != null) {
            final attempts = (localJson['_syncAttempts'] as int? ?? 0) + 1;
            localJson['_syncAttempts'] = attempts;
            localJson['_lastSyncAttemptMs'] = DateTime.now().millisecondsSinceEpoch;
            await db.upsertEntity(
              store: _storeMaintenance,
              id: item.entityId,
              json: jsonEncode(localJson),
            );
          }
        } catch (_) {}

        if (item.op == 'create') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final created = await remoteDataSource.createMaintenance(
            CreateMaintenanceDto.fromJson(payload),
            cancelToken: _cancelToken,
          );

          // Replace local temp record with server record
          await db.deleteEntity(store: _storeMaintenance, id: item.entityId);
          await _upsertLocalMaintenance(
            created,
            extra: {
              '_localOnly': false,
              'syncStatus': 'SENT',
              '_syncAttempts': 0,
              '_lastSyncAttemptMs': DateTime.now().millisecondsSinceEpoch,
            },
          );

          await db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'update') {
          final updates = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final updated = await remoteDataSource.updateMaintenance(
            item.entityId,
            updates,
            cancelToken: _cancelToken,
          );
          await _upsertLocalMaintenance(updated, extra: {'_localOnly': false});
          await db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'delete') {
          await remoteDataSource.deleteMaintenance(
            item.entityId,
            cancelToken: _cancelToken,
          );
          await db.deleteEntity(store: _storeMaintenance, id: item.entityId);
          await db.markSyncItemSent(item.id);
          continue;
        }

        // Unknown op: mark as sent to avoid blocking the queue.
        await db.markSyncItemSent(item.id);
      } catch (_) {
        await db.markSyncItemError(item.id);

        // Mark local record as FAILED (best-effort)
        try {
          final local = await _getLocalMaintenanceJsonById(item.entityId);
          if (local != null) {
            local['syncStatus'] = 'FAILED';
            local['_lastSyncAttemptMs'] = DateTime.now().millisecondsSinceEpoch;
            await db.upsertEntity(
              store: _storeMaintenance,
              id: item.entityId,
              json: jsonEncode(local),
            );
          }
        } catch (_) {}
      }
    }
  }

  // === MAINTENANCE ===

  Future<MaintenanceRecord> createMaintenance(CreateMaintenanceDto dto) async {
    // Keep method name for call sites, but perform offline-first.
    return await createMaintenanceOfflineFirst(dto);
  }

  Future<MaintenanceListResponse> listMaintenance({
    String? search,
    ProductHealthStatus? status,
    String? productoId,
    String? from,
    String? to,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await remoteDataSource.listMaintenance(
        search: search,
        status: status,
        productoId: productoId,
        from: from,
        to: to,
        page: page,
        limit: limit,
        cancelToken: _cancelToken,
      );

      // Cache remote snapshot locally (best-effort)
      try {
        for (final r in res.items) {
          await _upsertLocalMaintenance(r, extra: {'_localOnly': false});
        }
      } catch (_) {}

      return res;
    } catch (e) {
      if (_isNetworkError(e)) {
        final local = await listLocalMaintenance(
          search: search,
          status: status,
          productoId: productoId,
          from: from,
          to: to,
        );
        return MaintenanceListResponse(
          items: local,
          total: local.length,
          page: 1,
          limit: local.length,
          totalPages: 1,
        );
      }
      rethrow;
    }
  }

  Future<MaintenanceRecord> getMaintenance(String id) async {
    return await remoteDataSource.getMaintenance(
      id,
      cancelToken: _cancelToken,
    );
  }

  Future<MaintenanceRecord> updateMaintenance(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updated = await remoteDataSource.updateMaintenance(
        id,
        updates,
        cancelToken: _cancelToken,
      );
      // Cache latest snapshot locally (best-effort)
      try {
        await _upsertLocalMaintenance(updated, extra: {'_localOnly': false});
      } catch (_) {}
      return updated;
    } catch (e) {
      if (!_isNetworkError(e)) rethrow;

      // Offline-first: apply patch locally and enqueue sync.
      final localJson = await _getLocalMaintenanceJsonById(id);
      if (localJson != null) {
        localJson.addAll(_snakeToLocalPatch(updates));
        localJson['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        localJson['syncStatus'] = 'PENDING';
        await db.upsertEntity(
          store: _storeMaintenance,
          id: id,
          json: jsonEncode(localJson),
        );

        if (_isLocalOnlyJson(localJson)) {
          // This record hasn't been created on the server yet: update its queued create payload.
          await db.updateQueuedSyncPayload(
            module: _syncModule,
            op: 'create',
            entityId: id,
            payloadJson: jsonEncode(_buildCreateDtoPayloadFromLocalJson(localJson)),
          );
        } else {
          await db.enqueueSync(
            module: _syncModule,
            op: 'update',
            entityId: id,
            payloadJson: jsonEncode(updates),
          );
        }

        // Best-effort background sync
        // ignore: unawaited_futures
        syncPending();

        return MaintenanceRecord.fromJson(localJson);
      }

      // If we don't have a local snapshot, still enqueue update.
      await db.enqueueSync(
        module: _syncModule,
        op: 'update',
        entityId: id,
        payloadJson: jsonEncode(updates),
      );
      // ignore: unawaited_futures
      syncPending();

      rethrow;
    }
  }

  Future<void> deleteMaintenance(String id) async {
    try {
      await remoteDataSource.deleteMaintenance(
        id,
        cancelToken: _cancelToken,
      );
      // Best-effort: remove locally
      try {
        await db.deleteEntity(store: _storeMaintenance, id: id);
      } catch (_) {}
      return;
    } catch (e) {
      if (!_isNetworkError(e)) rethrow;

      // Offline-first delete
      final localJson = await _getLocalMaintenanceJsonById(id);
      if (localJson != null && _isLocalOnlyJson(localJson)) {
        // Cancel the queued create and remove locally.
        await db.cancelQueuedSync(module: _syncModule, entityId: id);
        await db.deleteEntity(store: _storeMaintenance, id: id);
        return;
      }

      // Remove local snapshot and enqueue server delete.
      try {
        await db.deleteEntity(store: _storeMaintenance, id: id);
      } catch (_) {}

      await db.enqueueSync(
        module: _syncModule,
        op: 'delete',
        entityId: id,
        payloadJson: '{}',
      );

      // ignore: unawaited_futures
      syncPending();
      return;
    }
  }

  Future<MaintenanceSummary> getSummary({
    String? from,
    String? to,
  }) async {
    return await remoteDataSource.getSummary(
      from: from,
      to: to,
      cancelToken: _cancelToken,
    );
  }

  // === WARRANTY ===

  Future<WarrantyCase> createWarranty(CreateWarrantyDto dto) async {
    return await remoteDataSource.createWarranty(
      dto,
      cancelToken: _cancelToken,
    );
  }

  Future<WarrantyListResponse> listWarranty({
    String? search,
    WarrantyStatus? status,
    String? productoId,
    String? from,
    String? to,
    int page = 1,
    int limit = 50,
  }) async {
    return await remoteDataSource.listWarranty(
      search: search,
      status: status,
      productoId: productoId,
      from: from,
      to: to,
      page: page,
      limit: limit,
      cancelToken: _cancelToken,
    );
  }

  Future<WarrantyCase> getWarranty(String id) async {
    return await remoteDataSource.getWarranty(
      id,
      cancelToken: _cancelToken,
    );
  }

  Future<WarrantyCase> updateWarranty(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await remoteDataSource.updateWarranty(
      id,
      updates,
      cancelToken: _cancelToken,
    );
  }

  Future<void> deleteWarranty(String id) async {
    return await remoteDataSource.deleteWarranty(
      id,
      cancelToken: _cancelToken,
    );
  }

  // === INVENTORY AUDITS ===

  Future<InventoryAudit> createAudit(CreateAuditDto dto) async {
    return await remoteDataSource.createAudit(
      dto,
      cancelToken: _cancelToken,
    );
  }

  Future<AuditListResponse> listAudits({
    String? from,
    String? to,
    AuditStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    return await remoteDataSource.listAudits(
      from: from,
      to: to,
      status: status,
      page: page,
      limit: limit,
      cancelToken: _cancelToken,
    );
  }

  Future<InventoryAudit> getAudit(String id) async {
    return await remoteDataSource.getAudit(
      id,
      cancelToken: _cancelToken,
    );
  }

  Future<InventoryAudit> updateAudit(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await remoteDataSource.updateAudit(
      id,
      updates,
      cancelToken: _cancelToken,
    );
  }

  Future<AuditItemsResponse> getAuditItems(
    String auditId, {
    String? search,
  }) async {
    return await remoteDataSource.getAuditItems(
      auditId,
      search: search,
      cancelToken: _cancelToken,
    );
  }

  Future<InventoryAuditItem> upsertAuditItem(
    String auditId,
    CreateAuditItemDto dto,
  ) async {
    return await remoteDataSource.upsertAuditItem(
      auditId,
      dto,
      cancelToken: _cancelToken,
    );
  }

  Future<void> deleteAuditItem(String auditId, String itemId) async {
    return await remoteDataSource.deleteAuditItem(
      auditId,
      itemId,
      cancelToken: _cancelToken,
    );
  }
}
