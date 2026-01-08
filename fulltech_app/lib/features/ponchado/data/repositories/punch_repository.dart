import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/storage/local_db_interface.dart';
import '../datasources/punch_remote_datasource.dart';
import '../models/punch_record.dart';

class PunchRepository {
  final PunchRemoteDataSource remoteDataSource;
  final LocalDb db;
  CancelToken? _cancelToken;

  static const String _store = 'attendance_records';
  static const String _syncModule = 'attendance';

  PunchRepository(this.remoteDataSource, this.db) {
    _cancelToken = CancelToken();
  }

  void cancelRequests() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  String _newLocalId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'local-$ms-${ms % 9973}';
  }

  Future<List<PunchRecord>> _loadLocalPunches({
    String? from,
    String? to,
    PunchType? type,
  }) async {
    final rows = await db.listEntitiesJson(store: _store);
    final items = <PunchRecord>[];
    for (final raw in rows) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final record = PunchRecord.fromJson(map);
        items.add(record);
      } catch (_) {
        // Ignore corrupt rows
      }
    }

    bool inRange(PunchRecord r) {
      if (from == null && to == null) return true;
      final day = r.datetimeUtc.toIso8601String().split('T')[0];
      if (from != null && day.compareTo(from) < 0) return false;
      if (to != null && day.compareTo(to) > 0) return false;
      return true;
    }

    final filtered =
        items
            .where((r) => inRange(r))
            .where((r) => type == null ? true : r.type == type)
            .toList()
          ..sort((a, b) => b.datetimeUtc.compareTo(a.datetimeUtc));

    return filtered;
  }

  Future<void> _upsertLocalPunch(
    PunchRecord record, {
    Map<String, dynamic>? extra,
  }) async {
    final map = record.toJson();
    if (extra != null) {
      map.addAll(extra);
    }
    await db.upsertEntity(store: _store, id: record.id, json: jsonEncode(map));
  }

  /// Offline-first create:
  /// 1) write a local PENDING record to SQLite
  /// 2) enqueue sync
  /// 3) try to sync in background
  Future<PunchRecord> createPunchOfflineFirst(CreatePunchDto dto) async {
    final session = await db.readSession();
    if (session == null) {
      throw StateError('No session');
    }

    final now = DateTime.now().toUtc();
    final localRecord = PunchRecord(
      id: _newLocalId(),
      empresaId: session.user.empresaId,
      userId: session.user.id,
      type: dto.type,
      datetimeUtc: dto.datetimeUtc,
      datetimeLocal: dto.datetimeLocal,
      timezone: dto.timezone,
      locationLat: dto.locationLat,
      locationLng: dto.locationLng,
      locationAccuracy: dto.locationAccuracy,
      locationProvider: dto.locationProvider,
      addressText: dto.addressText,
      locationMissing: dto.locationMissing,
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      platform: dto.platform,
      note: dto.note,
      isManualEdit: false,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      userName: session.user.name,
      userEmail: session.user.email,
    );

    await _upsertLocalPunch(
      localRecord,
      extra: {'_localOnly': true, '_syncAttempts': 0, '_lastSyncAttemptMs': 0},
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

  /// Best-effort sync for queued attendance ops.
  Future<void> syncPending() async {
    final items = await db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;
      if (item.op != 'create') continue;

      try {
        // Update local attempt counters (if present)
        final localRaw = await db.getEntityJson(store: _store, id: item.entityId);
        if (localRaw != null) {
          final localJson = jsonDecode(localRaw) as Map<String, dynamic>;
          final attempts = (localJson['_syncAttempts'] as int? ?? 0) + 1;
          localJson['_syncAttempts'] = attempts;
          localJson['_lastSyncAttemptMs'] = DateTime.now().millisecondsSinceEpoch;
          await db.upsertEntity(
            store: _store,
            id: item.entityId,
            json: jsonEncode(localJson),
          );
        }

        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final created = await remoteDataSource.createPunch(
          CreatePunchDto.fromJson(payload),
          cancelToken: _cancelToken,
        );

        // Replace local temp record with server record
        await db.deleteEntity(store: _store, id: item.entityId);
        await _upsertLocalPunch(
          created,
          extra: {
            '_localOnly': false,
            '_syncAttempts': 0,
            '_lastSyncAttemptMs': DateTime.now().millisecondsSinceEpoch,
          },
        );

        await db.markSyncItemSent(item.id);
      } catch (e) {
        await db.markSyncItemError(item.id);

        // Mark local record as FAILED (best-effort)
        try {
          final localRaw = await db.getEntityJson(store: _store, id: item.entityId);
          if (localRaw != null) {
            final local = jsonDecode(localRaw) as Map<String, dynamic>;
            local['syncStatus'] = 'FAILED';
            local['_lastSyncAttemptMs'] = DateTime.now().millisecondsSinceEpoch;
            await db.upsertEntity(
              store: _store,
              id: item.entityId,
              json: jsonEncode(local),
            );
          }
        } catch (_) {}
      }
    }
  }

  /// Re-enqueue FAILED local attendance records so they can be retried.
  Future<void> retryFailed() async {
    final rows = await db.listEntitiesJson(store: _store);
    for (final raw in rows) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['syncStatus'] != 'FAILED') continue;
        final record = PunchRecord.fromJson(map);

        final dto = CreatePunchDto(
          type: record.type,
          datetimeUtc: record.datetimeUtc,
          datetimeLocal: record.datetimeLocal,
          timezone: record.timezone,
          locationLat: record.locationLat,
          locationLng: record.locationLng,
          locationAccuracy: record.locationAccuracy,
          locationProvider: record.locationProvider,
          addressText: record.addressText,
          locationMissing: record.locationMissing,
          deviceId: record.deviceId,
          deviceName: record.deviceName,
          platform: record.platform,
          note: record.note,
          syncStatus: SyncStatus.pending,
        );

        await db.enqueueSync(
          module: _syncModule,
          op: 'create',
          entityId: record.id,
          payloadJson: jsonEncode(dto.toJson()),
        );

        map['syncStatus'] = 'PENDING';
        await db.upsertEntity(
          store: _store,
          id: record.id,
          json: jsonEncode(map),
        );
      } catch (_) {}
    }
  }

  Future<PunchRecord> createPunch(CreatePunchDto dto) async {
    try {
      return await remoteDataSource.createPunch(dto, cancelToken: _cancelToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<PunchListResponse> listPunches({
    String? from,
    String? to,
    String? userId,
    PunchType? type,
    int limit = 100,
    int offset = 0,
  }) async {
    // Always serve from local first (offline-first), and refresh from server if possible.
    final local = await _loadLocalPunches(from: from, to: to, type: type);
    final localPage = local.skip(offset).take(limit).toList();

    try {
      final remote = await remoteDataSource.listPunches(
        from: from,
        to: to,
        userId: userId,
        type: type,
        limit: limit,
        offset: offset,
        cancelToken: _cancelToken,
      );

      for (final r in remote.items) {
        await _upsertLocalPunch(r, extra: {'_localOnly': false});
      }

      // Merge remote with any local-only pending items.
      final pendingLocal = local
          .where((p) => p.syncStatus != SyncStatus.synced)
          .toList();
      final merged = <PunchRecord>{...remote.items, ...pendingLocal}.toList()
        ..sort((a, b) => b.datetimeUtc.compareTo(a.datetimeUtc));

      return PunchListResponse(
        items: merged,
        total: remote.total,
        limit: remote.limit,
        offset: remote.offset,
      );
    } catch (_) {
      // Offline fallback.
      return PunchListResponse(
        items: localPage,
        total: local.length,
        limit: limit,
        offset: offset,
      );
    }
  }

  Future<PunchRecord> getPunch(String id) async {
    try {
      return await remoteDataSource.getPunch(id, cancelToken: _cancelToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<PunchRecord> updatePunch(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updated = await remoteDataSource.updatePunch(
        id,
        updates,
        cancelToken: _cancelToken,
      );
      await db.upsertEntity(
        store: _store,
        id: updated.id,
        json: jsonEncode(updated.toJson()),
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePunch(String id) async {
    try {
      await remoteDataSource.deletePunch(id, cancelToken: _cancelToken);
      await db.deleteEntity(store: _store, id: id);
    } catch (e) {
      rethrow;
    }
  }

  Future<PunchSummary> getSummary({
    String? from,
    String? to,
    String? userId,
  }) async {
    try {
      return await remoteDataSource.getSummary(
        from: from,
        to: to,
        userId: userId,
        cancelToken: _cancelToken,
      );
    } catch (_) {
      // Offline fallback computed from local cache.
      final local = await _loadLocalPunches(from: from, to: to, type: null);
      final daysWorked = <String>{};
      var totalHours = 0.0;
      var totalLunchHours = 0.0;

      final byType = <String, int>{
        'IN': 0,
        'LUNCH_START': 0,
        'LUNCH_END': 0,
        'OUT': 0,
      };

      final dayGroups = <String, List<PunchRecord>>{};
      for (final p in local) {
        final day = p.datetimeUtc.toIso8601String().split('T')[0];
        dayGroups.putIfAbsent(day, () => []).add(p);
        switch (p.type) {
          case PunchType.in_:
            byType['IN'] = (byType['IN'] ?? 0) + 1;
            break;
          case PunchType.lunchStart:
            byType['LUNCH_START'] = (byType['LUNCH_START'] ?? 0) + 1;
            break;
          case PunchType.lunchEnd:
            byType['LUNCH_END'] = (byType['LUNCH_END'] ?? 0) + 1;
            break;
          case PunchType.out:
            byType['OUT'] = (byType['OUT'] ?? 0) + 1;
            break;
        }
      }

      for (final entry in dayGroups.entries) {
        daysWorked.add(entry.key);
        final dayPunches = entry.value
          ..sort((a, b) => a.datetimeUtc.compareTo(b.datetimeUtc));
        final inPunch = dayPunches
            .where((p) => p.type == PunchType.in_)
            .toList();
        final outPunch = dayPunches
            .where((p) => p.type == PunchType.out)
            .toList();
        if (inPunch.isNotEmpty && outPunch.isNotEmpty) {
          totalHours +=
              outPunch.first.datetimeUtc
                  .difference(inPunch.first.datetimeUtc)
                  .inMinutes /
              60.0;
        }
        final lunchStart = dayPunches
            .where((p) => p.type == PunchType.lunchStart)
            .toList();
        final lunchEnd = dayPunches
            .where((p) => p.type == PunchType.lunchEnd)
            .toList();
        if (lunchStart.isNotEmpty && lunchEnd.isNotEmpty) {
          totalLunchHours +=
              lunchEnd.first.datetimeUtc
                  .difference(lunchStart.first.datetimeUtc)
                  .inMinutes /
              60.0;
        }
      }

      double round2(double v) => (v * 100).roundToDouble() / 100;

      return PunchSummary(
        daysWorked: daysWorked.length,
        totalPunches: local.length,
        totalHours: round2(totalHours),
        totalLunchHours: round2(totalLunchHours),
        effectiveHours: round2(totalHours - totalLunchHours),
        byType: byType,
      );
    }
  }
}
