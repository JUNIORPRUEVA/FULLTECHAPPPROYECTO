import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db_interface.dart';
import '../models/letter_models.dart';
import 'ai_letters_api.dart';
import 'company_settings_api.dart';
import 'letters_api.dart';

class LettersRepository {
  LettersRepository({
    required LettersApi lettersApi,
    required AiLettersApi aiApi,
    required CompanySettingsApi companySettingsApi,
    required LocalDb db,
  })  : _lettersApi = lettersApi,
        _aiApi = aiApi,
        _companySettingsApi = companySettingsApi,
        _db = db;

  final LettersApi _lettersApi;
  final AiLettersApi _aiApi;
  final CompanySettingsApi _companySettingsApi;
  final LocalDb _db;

  final _uuid = const Uuid();

  static const _syncModule = 'letters';

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<List<LetterRecord>> listLocal({
    required String empresaId,
    String? q,
    String? letterType,
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _db.listCartas(
      empresaId: empresaId,
      q: q,
      letterType: letterType,
      status: status,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: limit,
      offset: offset,
    );
    return rows.map(LetterRecord.fromLocalRow).toList();
  }

  Future<LetterRecord?> getLocal(String id) async {
    final row = await _db.getCarta(id: id);
    if (row == null) return null;
    return LetterRecord.fromLocalRow(row);
  }

  Future<void> refreshFromServer({
    required String empresaId,
    String? q,
    String? letterType,
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _lettersApi.listLettersPaged(
      q: q,
      letterType: letterType,
      status: status,
      from: from?.toIso8601String(),
      to: to?.toIso8601String(),
      limit: limit,
      offset: offset,
    );

    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    for (final it in items) {
      final record = LetterRecord.fromServerJson(
        it,
        empresaId: empresaId,
        syncStatus: SyncStatus.synced,
      );
      await _db.upsertCarta(row: record.toLocalRow());
    }
  }

  /// Local-first save (create or update). Best-effort sync to backend.
  ///
  /// Returns the saved record (possibly with a migrated server id).
  Future<LetterRecord> saveLetter({
    required String empresaId,
    required String userId,
    String? id,
    required String quotationId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required String letterType,
    required String subject,
    required String body,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();

    final existing = id == null ? null : await getLocal(id);

    final localId = id ?? _uuid.v4();

    final draft = LetterRecord(
      id: localId,
      empresaId: empresaId,
      userId: userId,
      quotationId: quotationId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      letterType: letterType,
      subject: subject,
      body: body,
      status: status,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      lastError: null,
    );

    await _db.upsertCarta(row: draft.toLocalRow());

    try {
      final Map<String, dynamic> server;
      if (existing == null) {
        server = await _lettersApi.createLetter(draft.toCreatePayload());
      } else {
        server = await _lettersApi.updateLetter(localId, draft.toCreatePayload());
      }

      final item = server['item'];
      if (item is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida del servidor');
      }

      final serverId = (item['id'] ?? '').toString();
      final synced = LetterRecord.fromServerJson(
        item,
        empresaId: empresaId,
        syncStatus: SyncStatus.synced,
      );

      if (serverId.isNotEmpty && serverId != localId) {
        // Migrate local ID to server ID.
        await _db.markCartaDeleted(id: localId, deletedAtIso: now);
        await _db.upsertCarta(row: synced.toLocalRow(overrideId: serverId));
        return synced.copyWith(id: serverId);
      }

      await _db.upsertCarta(row: synced.toLocalRow());
      return synced;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await _db.enqueueSync(
          module: _syncModule,
          op: 'upsert',
          entityId: localId,
          payloadJson: jsonEncode(draft.toCreatePayload()),
        );

        // Keep as pending (do not mark error on offline).
        final pending = draft.copyWith(syncStatus: SyncStatus.pending, lastError: null);
        await _db.upsertCarta(row: pending.toLocalRow());
        return pending;
      }

      final failed = draft.copyWith(
        syncStatus: SyncStatus.error,
        lastError: e.toString(),
      );
      await _db.upsertCarta(row: failed.toLocalRow());
      return failed;
    } catch (e) {
      final failed = draft.copyWith(
        syncStatus: SyncStatus.error,
        lastError: e.toString(),
      );
      await _db.upsertCarta(row: failed.toLocalRow());
      return failed;
    }
  }

  Future<void> deleteLetterLocalFirst({required String id}) async {
    final now = DateTime.now().toIso8601String();
    await _db.markCartaDeleted(id: id, deletedAtIso: now);

    try {
      await _lettersApi.deleteLetter(id);
    } on DioException catch (e) {
      // If it doesn't exist remotely, keep local delete.
      if (e.response?.statusCode == 404) return;
      if (_isNetworkError(e)) {
        await _db.enqueueSync(
          module: _syncModule,
          op: 'delete',
          entityId: id,
          payloadJson: jsonEncode(<String, dynamic>{}),
        );
        return;
      }
      rethrow;
    }
  }

  /// Processes queued sync items for letters.
  ///
  /// This is used by the global AutoSync wrapper.
  Future<void> syncPending() async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;

      try {
        if (item.op == 'upsert') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

          final existing = await getLocal(item.entityId);

          Map<String, dynamic> server;
          if (existing == null) {
            server = await _lettersApi.createLetter(payload);
          } else {
            server = await _lettersApi.updateLetter(item.entityId, payload);
          }

          final it = server['item'];
          if (it is Map<String, dynamic>) {
            final empresaId = (it['empresa_id'] ?? it['empresaId'] ?? existing?.empresaId ?? '').toString();
            final synced = LetterRecord.fromServerJson(it, empresaId: empresaId, syncStatus: SyncStatus.synced);
            await _db.upsertCarta(row: synced.toLocalRow());
          }

          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'delete') {
          try {
            await _lettersApi.deleteLetter(item.entityId);
          } on DioException catch (e) {
            if (e.response?.statusCode != 404) rethrow;
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        await _db.markSyncItemSent(item.id);
      } catch (e) {
        await _db.markSyncItemError(item.id);
        try {
          final existing = await getLocal(item.entityId);
          if (existing != null) {
            final failed = existing.copyWith(syncStatus: SyncStatus.error, lastError: e.toString());
            await _db.upsertCarta(row: failed.toLocalRow());
          }
        } catch (_) {}
      }
    }
  }

  Future<LetterRecord?> markSent({required String empresaId, required String id}) async {
    try {
      final server = await _lettersApi.markSent(id);
      final item = server['item'];
      if (item is! Map<String, dynamic>) throw Exception('Respuesta inválida del servidor');

      final updated = LetterRecord.fromServerJson(
        item,
        empresaId: empresaId,
        syncStatus: SyncStatus.synced,
      );
      await _db.upsertCarta(row: updated.toLocalRow());
      return updated;
    } catch (e) {
      final existing = await getLocal(id);
      if (existing == null) return null;
      final failed = existing.copyWith(syncStatus: SyncStatus.error, lastError: e.toString());
      await _db.upsertCarta(row: failed.toLocalRow());
      return failed;
    }
  }

  Future<Map<String, dynamic>> _loadCompanyProfileSafe() async {
    try {
      final data = await _companySettingsApi.getCompanySettings();
      final item = data['item'];
      if (item is Map<String, dynamic>) return item;
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<({String subject, String body})> generateAi({
    required String letterType,
    required Map<String, dynamic>? quotation,
    required Map<String, dynamic>? manualCustomer,
    required String? manualContext,
    required String action,
    String? subject,
    String? body,
  }) async {
    final companyProfile = await _loadCompanyProfileSafe();

    final resp = await _aiApi.generateLetter(
      companyProfile: companyProfile,
      letterType: letterType,
      quotation: quotation,
      manualCustomer: manualCustomer,
      manualContext: manualContext,
      action: action,
      subject: subject,
      body: body,
    );

    final s = (resp['subject'] ?? '').toString().trim();
    final b = (resp['body'] ?? '').toString().trim();
    if (s.isEmpty || b.isEmpty) throw Exception('La IA devolvió una carta inválida');
    return (subject: s, body: b);
  }

  Future<void> recordExport({required String id, String? fileUrl}) async {
    await _lettersApi.createExport(id, fileUrl: fileUrl);
  }
}
