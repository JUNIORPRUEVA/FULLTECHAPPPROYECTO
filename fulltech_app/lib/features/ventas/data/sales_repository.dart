import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db_interface.dart';
import '../models/sales_models.dart';
import 'sales_api.dart';

class SalesRepository {
  SalesRepository({required SalesApi api, required LocalDb db})
    : _api = api,
      _db = db;

  final SalesApi _api;
  final LocalDb _db;

  final _uuid = const Uuid();

  static const _syncModule = 'sales';

  Future<List<SalesRecord>> listLocal({
    required String empresaId,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;
    final rows = await _db.listSalesRecords(
      empresaId: empresaId,
      q: q,
      channel: channel,
      status: status,
      paymentMethod: paymentMethod,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: pageSize,
      offset: offset,
    );

    return rows.map(SalesRecord.fromLocalRow).toList();
  }

  Future<int> _countLocal({
    required String empresaId,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    DateTime? from,
    DateTime? to,
  }) async {
    // Quick + simple: read all and filter in memory (OK for moderate sizes).
    // If the dataset grows, we can add a separate COUNT query in LocalDb.
    final rows = await _db.listSalesRecords(
      empresaId: empresaId,
      q: q,
      channel: channel,
      status: status,
      paymentMethod: paymentMethod,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: 100000,
      offset: 0,
    );
    return rows.length;
  }

  Future<void> refreshFromServer({
    required String empresaId,
    int page = 1,
    int pageSize = 20,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await _api.listSales(
      page: page,
      pageSize: pageSize,
      q: q,
      channel: channel,
      status: status,
      paymentMethod: paymentMethod,
      from: from?.toIso8601String(),
      to: to?.toIso8601String(),
    );

    final items =
        (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    for (final it in items) {
      final record = SalesRecord.fromServerJson(it, empresaId: empresaId);
      await _db.upsertSalesRecord(
        row: record.toLocalRow(overrideEvidenceCount: record.evidenceCount),
      );
    }
  }

  String _newId() => _uuid.v4();

  Future<SalesRecord> createSaleLocalFirst({
    required String empresaId,
    required String userId,
    required List<SalesLineItem> items,
    required String productOrService,
    required double amount,
    DateTime? soldAt,
    String? customerName,
    String? customerPhone,
    String? customerDocument,
    String? notes,
    required bool evidenceRequired,
    required List<EvidenceDraft> evidences,
  }) async {
    if (evidenceRequired && evidences.isEmpty) {
      throw StateError('Debe adjuntar al menos una evidencia');
    }

    final now = DateTime.now();
    final id = _newId();

    final record = SalesRecord(
      id: id,
      empresaId: empresaId,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerDocument: customerDocument,
      productOrService: productOrService,
      items: items,
      amount: amount,
      paymentMethod: SalesPaymentMethod.other,
      channel: SalesChannel.other,
      status: SalesStatus.confirmed,
      notes: notes,
      soldAt: soldAt ?? now,
      evidenceRequired: evidenceRequired,
      evidenceCount: evidences.length,
      deleted: false,
      deletedAt: null,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      lastError: null,
    );

    await _db.upsertSalesRecord(row: record.toLocalRow());

    await _db.enqueueSync(
      module: _syncModule,
      op: 'create',
      entityId: id,
      payloadJson: jsonEncode({'id': id, ...record.toCreatePayload()}),
    );

    for (final ev in evidences) {
      final evidenceId = _newId();
      final localEvidence = SalesEvidence(
        id: evidenceId,
        saleId: id,
        type: ev.type,
        urlOrPath: ev.isFile ? 'local://$evidenceId/${ev.filename}' : ev.value,
        caption: ev.mimeType,
        createdAt: now,
        syncStatus: SyncStatus.pending,
        lastError: null,
      );
      await _db.upsertSalesEvidence(row: localEvidence.toLocalRow());

      await _db.enqueueSync(
        module: _syncModule,
        op: 'add_evidence',
        entityId: evidenceId,
        payloadJson: jsonEncode({
          'sale_id': id,
          'evidence_id': evidenceId,
          'type': ev.type,
          'value': ev.value,
          'is_file': ev.isFile,
          'filename': ev.filename,
          'mime_type': ev.mimeType,
          if (ev.isFile) 'bytes_b64': base64Encode(ev.bytes),
        }),
      );
    }

    // Best-effort sync
    // ignore: unawaited_futures
    syncPending();

    return record;
  }

  Future<SalesRecord> updateSaleLocalFirst({
    required SalesRecord existing,
    required Map<String, dynamic> patch,
  }) async {
    final now = DateTime.now();

    List<SalesLineItem> patchedItems = existing.items;
    if (patch['details'] is Map) {
      final rawDetails = (patch['details'] as Map).cast<String, dynamic>();
      final rawItems = rawDetails['items'];
      if (rawItems is List) {
        patchedItems = rawItems
            .whereType<Map>()
            .map((e) => SalesLineItem.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false);
      }
    }

    final updated = SalesRecord(
      id: existing.id,
      empresaId: existing.empresaId,
      userId: existing.userId,
      customerName:
          (patch['customer_name'] as String?) ?? existing.customerName,
      customerPhone:
          (patch['customer_phone'] as String?) ?? existing.customerPhone,
      customerDocument:
          (patch['customer_document'] as String?) ?? existing.customerDocument,
      productOrService:
          (patch['product_or_service'] as String?) ?? existing.productOrService,
      items: patchedItems,
      amount: (patch['amount'] as num?)?.toDouble() ?? existing.amount,
      paymentMethod:
          (patch['payment_method'] as String?) ?? existing.paymentMethod,
      channel: (patch['channel'] as String?) ?? existing.channel,
      status: (patch['status'] as String?) ?? existing.status,
      notes: (patch['notes'] as String?) ?? existing.notes,
      soldAt: patch['sold_at'] is String
          ? DateTime.tryParse(patch['sold_at'] as String) ?? existing.soldAt
          : existing.soldAt,
      evidenceRequired:
          (patch['evidence_required'] as bool?) ?? existing.evidenceRequired,
      evidenceCount: existing.evidenceCount,
      deleted: existing.deleted,
      deletedAt: existing.deletedAt,
      createdAt: existing.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      lastError: null,
    );

    await _db.upsertSalesRecord(row: updated.toLocalRow());

    await _db.enqueueSync(
      module: _syncModule,
      op: 'update',
      entityId: existing.id,
      payloadJson: jsonEncode(patch),
    );

    // ignore: unawaited_futures
    syncPending();

    return updated;
  }

  Future<void> deleteSaleLocalFirst({required String id}) async {
    final now = DateTime.now().toIso8601String();
    await _db.markSalesRecordDeleted(id: id, deletedAtIso: now);

    await _db.enqueueSync(
      module: _syncModule,
      op: 'delete',
      entityId: id,
      payloadJson: jsonEncode({}),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<List<SalesEvidence>> listEvidenceLocal(String saleId) async {
    final rows = await _db.listSalesEvidence(saleId: saleId);
    return rows.map(SalesEvidence.fromLocalRow).toList();
  }

  /// Best-effort sync for queued sales ops.
  Future<void> syncPending() async {
    // CRITICAL: Verify session exists before attempting any sync
    final session = await _db.readSession();
    if (session == null) return;

    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;

      try {
        if (item.op == 'create') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final localRow = await _db.getSalesRecord(id: item.entityId);
          final localEvidenceCount = localRow == null
              ? null
              : SalesRecord.fromLocalRow(localRow).evidenceCount;

          final server = await _api.createSale(payload);
          final it = server['item'];
          if (it is Map<String, dynamic>) {
            final empresaId = (it['empresa_id'] ?? it['empresaId'] ?? '')
                .toString();
            final record = SalesRecord.fromServerJson(
              it,
              empresaId: empresaId,
              syncStatus: SyncStatus.synced,
            );
            await _db.upsertSalesRecord(
              row: record.toLocalRow(overrideEvidenceCount: localEvidenceCount),
            );
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'update') {
          final patch = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final server = await _api.updateSale(item.entityId, patch);
          final it = server['item'];
          if (it is Map<String, dynamic>) {
            final local = await _db.getSalesRecord(id: item.entityId);
            final empresaId = (local?['empresa_id'] ?? it['empresa_id'] ?? '')
                .toString();
            final record = SalesRecord.fromServerJson(
              it,
              empresaId: empresaId,
              syncStatus: SyncStatus.synced,
            );
            await _db.upsertSalesRecord(row: record.toLocalRow());
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'delete') {
          await _api.deleteSale(item.entityId);
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'add_evidence') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final saleId = (payload['sale_id'] ?? '').toString();
          final type = (payload['type'] ?? SalesEvidenceType.image).toString();
          final isFile = payload['is_file'] == true;

          Map<String, dynamic> evidencePayload;

          if (isFile) {
            final b64 = (payload['bytes_b64'] ?? '').toString();
            final bytes = base64Decode(b64);
            final filename = (payload['filename'] ?? 'evidence').toString();
            final mimeType = payload['mime_type']?.toString();

            final upload = await _api.uploadEvidenceFile(
              bytes: Uint8List.fromList(bytes),
              filename: filename,
              mimeType: mimeType,
            );
            final url = (upload['url'] ?? '').toString();
            if (url.isEmpty) throw Exception('Upload falló');

            evidencePayload = {
              'type': type,
              'file_path': url,
              if (mimeType != null && mimeType.trim().isNotEmpty)
                'mime_type': mimeType,
            };
          } else {
            final value = (payload['value'] ?? '').toString();
            evidencePayload = {
              'type': type,
              if (type == SalesEvidenceType.link) 'url': value,
              if (type == SalesEvidenceType.text) 'text': value,
            };
          }

          final server = await _api.addEvidence(saleId, evidencePayload);
          final it = server['item'];
          if (it is Map<String, dynamic>) {
            final evidence = SalesEvidence.fromServerJson(
              it,
              saleId: saleId,
              syncStatus: SyncStatus.synced,
            );
            await _db.upsertSalesEvidence(row: evidence.toLocalRow());
          }

          await _db.markSyncItemSent(item.id);
          continue;
        }

        // Unknown op
        await _db.markSyncItemSent(item.id);
      } catch (e) {
        // CRITICAL: Stop retry loop on 401
        if (e is DioException && e.response?.statusCode == 401) {
          await _db.markSyncItemSent(item.id); // Remove from queue
          return; // Stop processing - session is invalid
        }

        await _db.markSyncItemError(item.id);

        // Best-effort: mark local entity as error (for create/update only)
        try {
          if (item.op == 'create' || item.op == 'update') {
            final row = await _db.getSalesRecord(id: item.entityId);
            if (row != null) {
              final current = SalesRecord.fromLocalRow(row);
              final failed = current.copyWith(
                syncStatus: SyncStatus.error,
                lastError: e.toString(),
              );
              await _db.upsertSalesRecord(row: failed.toLocalRow());
            }
          }
          if (item.op == 'add_evidence') {
            final payload =
                jsonDecode(item.payloadJson) as Map<String, dynamic>;
            final evidenceId = (payload['evidence_id'] ?? item.entityId)
                .toString();
            // There's no getEvidence method; just upsert a minimal error marker.
            await _db.upsertSalesEvidence(
              row: {
                'id': evidenceId,
                'sale_id': (payload['sale_id'] ?? '').toString(),
                'type': (payload['type'] ?? SalesEvidenceType.image).toString(),
                'url_or_path': (payload['value'] ?? '').toString(),
                'caption': payload['mime_type']?.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'sync_status': SyncStatus.error,
                'last_error': e.toString(),
              },
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<({List<SalesRecord> items, int total})> listSalesOfflineFirst({
    required String empresaId,
    int page = 1,
    int pageSize = 20,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    DateTime? from,
    DateTime? to,
  }) async {
    final localItems = await listLocal(
      empresaId: empresaId,
      q: q,
      channel: channel,
      status: status,
      paymentMethod: paymentMethod,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
    final localTotal = await _countLocal(
      empresaId: empresaId,
      q: q,
      channel: channel,
      status: status,
      paymentMethod: paymentMethod,
      from: from,
      to: to,
    );

    try {
      await refreshFromServer(
        empresaId: empresaId,
        page: page,
        pageSize: pageSize,
        q: q,
        channel: channel,
        status: status,
        paymentMethod: paymentMethod,
        from: from,
        to: to,
      );

      final refreshed = await listLocal(
        empresaId: empresaId,
        q: q,
        channel: channel,
        status: status,
        paymentMethod: paymentMethod,
        from: from,
        to: to,
        page: page,
        pageSize: pageSize,
      );

      final remoteData = await _api.listSales(
        page: page,
        pageSize: pageSize,
        q: q,
        channel: channel,
        status: status,
        paymentMethod: paymentMethod,
        from: from?.toIso8601String(),
        to: to?.toIso8601String(),
      );
      final total = (remoteData['total'] as num?)?.toInt() ?? localTotal;

      return (items: refreshed, total: total);
    } catch (_) {
      return (items: localItems, total: localTotal);
    }
  }
}

class EvidenceDraft {
  final String type;
  final bool isFile;
  final String value;
  final List<int> bytes;
  final String filename;
  final String? mimeType;

  const EvidenceDraft.file({
    required this.type,
    required this.bytes,
    required this.filename,
    this.mimeType,
  }) : isFile = true,
       value = '';

  const EvidenceDraft.value({required this.type, required this.value})
    : isFile = false,
      bytes = const [],
      filename = '',
      mimeType = null;
}
