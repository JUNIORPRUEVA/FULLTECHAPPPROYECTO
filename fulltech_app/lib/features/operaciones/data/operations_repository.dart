import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db_interface.dart';
import '../models/operations_models.dart';
import 'operations_api.dart';

class OperationsRepository {
  OperationsRepository({required OperationsApi api, required LocalDb db})
    : _api = api,
      _db = db;

  final OperationsApi _api;
  final LocalDb _db;

  final _uuid = const Uuid();

  static const _syncModule = 'operations';

  String _newId() => _uuid.v4();

  Future<List<OperationsJob>> listLocalJobs({
    required String empresaId,
    String? q,
    String? status,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;
    final rows = await _db.listOperationsJobs(
      empresaId: empresaId,
      q: q,
      status: status,
      estado: estado,
      tipoTrabajo: tipoTrabajo,
      assignedTechId: assignedTechId,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: pageSize,
      offset: offset,
    );

    return rows.map(OperationsJob.fromLocalRow).toList(growable: false);
  }

  Future<int> countLocalJobs({
    required String empresaId,
    String? q,
    String? status,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _db.listOperationsJobs(
      empresaId: empresaId,
      q: q,
      status: status,
      estado: estado,
      tipoTrabajo: tipoTrabajo,
      assignedTechId: assignedTechId,
      fromIso: from?.toIso8601String(),
      toIso: to?.toIso8601String(),
      limit: 100000,
      offset: 0,
    );
    return rows.length;
  }

  Future<void> refreshJobsFromServer({
    required String empresaId,
    String? tab,
    String? q,
    String? status,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;

    // Prefer the new simplified endpoint (`GET /operations`) when using tab/estado/tipo.
    // If the backend is an older deploy and returns 404, fall back to legacy `GET /operations/jobs`.
    late final Map<String, dynamic> data;
    if (tab != null || estado != null || tipoTrabajo != null) {
      try {
        data = await _api.listOperaciones(
          tab: tab,
          q: q,
          estado: estado,
          tipo: tipoTrabajo,
          tecnicoId: assignedTechId,
          from: from?.toIso8601String(),
          to: to?.toIso8601String(),
          limit: pageSize,
          offset: offset,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          data = await _api.listJobs(
            q: q,
            status: status,
            assignedTechId: assignedTechId,
            from: from?.toIso8601String(),
            to: to?.toIso8601String(),
            limit: pageSize,
            offset: offset,
          );
        } else {
          rethrow;
        }
      }
    } else {
      data = await _api.listJobs(
        q: q,
        status: status,
        assignedTechId: assignedTechId,
        from: from?.toIso8601String(),
        to: to?.toIso8601String(),
        limit: pageSize,
        offset: offset,
      );
    }

    final items =
        (data['items'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    for (final it in items) {
      final job = OperationsJob.fromServerJson(it);
      await _db.upsertOperationsJob(
        row: job.toLocalRow(
          overrideSyncStatus: 'synced',
          overrideLastError: null,
        ),
      );

      final schedule = it['schedule'];
      if (schedule is Map) {
        final scheduleJson = schedule.cast<String, dynamic>();
        final rawDate =
            (scheduleJson['scheduled_date'] ??
                    scheduleJson['scheduledDate'] ??
                    '')
                .toString();
        final rawTime = scheduleJson['preferred_time']?.toString();
        await _db.upsertOperationsSchedule(
          row: {
            'id': (scheduleJson['id'] ?? '').toString(),
            'job_id': job.id,
            'scheduled_date': rawDate,
            'preferred_time': rawTime,
            'assigned_tech_id':
                (scheduleJson['assigned_tech_id'] ??
                        scheduleJson['assignedTechId'] ??
                        '')
                    .toString(),
            'additional_tech_ids_json': jsonEncode(
              (scheduleJson['additional_tech_ids'] is List)
                  ? (scheduleJson['additional_tech_ids'] as List)
                        .map((e) => e.toString())
                        .toList()
                  : const <String>[],
            ),
            'customer_availability_notes':
                scheduleJson['customer_availability_notes']?.toString(),
            'created_at':
                (scheduleJson['created_at'] ??
                        scheduleJson['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'updated_at':
                (scheduleJson['updated_at'] ??
                        scheduleJson['updatedAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'sync_status': 'synced',
            'last_error': null,
          },
        );

        // Denormalize schedule into job row for fast agenda grouping/listing.
        final jobRow = job.toLocalRow(
          overrideSyncStatus: 'synced',
          overrideLastError: null,
        );
        jobRow['scheduled_date'] = DateTime.tryParse(
          rawDate,
        )?.toIso8601String();
        jobRow['preferred_time'] = rawTime;
        await _db.upsertOperationsJob(row: jobRow);
      }

      final survey = it['survey'];
      if (survey is Map) {
        final surveyJson = survey.cast<String, dynamic>();
        await _db.upsertOperationsSurvey(
          row: {
            'id': (surveyJson['id'] ?? '').toString(),
            'job_id': job.id,
            'mode': (surveyJson['mode'] ?? 'physical').toString(),
            'gps_lat': (surveyJson['gps_lat'] as num?)?.toDouble(),
            'gps_lng': (surveyJson['gps_lng'] as num?)?.toDouble(),
            'address_confirmed': surveyJson['address_confirmed']?.toString(),
            'complexity': (surveyJson['complexity'] ?? 'basic').toString(),
            'site_notes': surveyJson['site_notes']?.toString(),
            'tools_needed_json': surveyJson['tools_needed'] == null
                ? null
                : jsonEncode(surveyJson['tools_needed']),
            'materials_needed_json': surveyJson['materials_needed'] == null
                ? null
                : jsonEncode(surveyJson['materials_needed']),
            'products_to_use_json': surveyJson['products_to_use'] == null
                ? null
                : jsonEncode(surveyJson['products_to_use']),
            'future_opportunities': surveyJson['future_opportunities']
                ?.toString(),
            'created_by_tech_id':
                (surveyJson['created_by_tech_id'] ??
                        surveyJson['createdByTechId'])
                    ?.toString(),
            'created_at':
                (surveyJson['created_at'] ??
                        surveyJson['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'sync_status': 'synced',
            'last_error': null,
          },
        );
      }

      final warrantyTickets = it['warranty_tickets'];
      if (warrantyTickets is List) {
        for (final t in warrantyTickets.whereType<Map>()) {
          final jt = t.cast<String, dynamic>();
          await _db.upsertOperationsWarrantyTicket(
            row: {
              'id': (jt['id'] ?? '').toString(),
              'job_id': job.id,
              'reason': (jt['reason'] ?? '').toString(),
              'reported_at':
                  (jt['reported_at'] ??
                          jt['reportedAt'] ??
                          DateTime.now().toIso8601String())
                      .toString(),
              'status': (jt['status'] ?? 'pending').toString(),
              'assigned_tech_id': jt['assigned_tech_id']?.toString(),
              'resolution_notes': jt['resolution_notes']?.toString(),
              'resolved_at': jt['resolved_at']?.toString(),
              'created_at':
                  (jt['created_at'] ??
                          jt['createdAt'] ??
                          DateTime.now().toIso8601String())
                      .toString(),
              'sync_status': 'synced',
              'last_error': null,
            },
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> getJobDetailFromServer({
    required String jobId,
  }) async {
    final data = await _api.getJob(jobId);

    final job = OperationsJob.fromServerJson(data);
    await _db.upsertOperationsJob(
      row: job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      ),
    );

    final survey = data['survey'];
    if (survey is Map) {
      final s = survey.cast<String, dynamic>();
      await _db.upsertOperationsSurvey(
        row: {
          'id': (s['id'] ?? '').toString(),
          'job_id': job.id,
          'mode': (s['mode'] ?? 'physical').toString(),
          'gps_lat': (s['gps_lat'] as num?)?.toDouble(),
          'gps_lng': (s['gps_lng'] as num?)?.toDouble(),
          'address_confirmed': s['address_confirmed']?.toString(),
          'complexity': (s['complexity'] ?? 'basic').toString(),
          'site_notes': s['site_notes']?.toString(),
          'tools_needed_json': s['tools_needed'] == null
              ? null
              : jsonEncode(s['tools_needed']),
          'materials_needed_json': s['materials_needed'] == null
              ? null
              : jsonEncode(s['materials_needed']),
          'products_to_use_json': s['products_to_use'] == null
              ? null
              : jsonEncode(s['products_to_use']),
          'future_opportunities': s['future_opportunities']?.toString(),
          'created_by_tech_id':
              (s['created_by_tech_id'] ?? s['createdByTechId'])?.toString(),
          'created_at':
              (s['created_at'] ??
                      s['createdAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'sync_status': 'synced',
          'last_error': null,
        },
      );

      final media = s['media'];
      if (media is List) {
        final items = <Map<String, Object?>>[];
        for (final m in media.whereType<Map>()) {
          final jm = m.cast<String, dynamic>();
          items.add({
            'id': (jm['id'] ?? _newId()).toString(),
            'survey_id': (s['id'] ?? '').toString(),
            'type': (jm['type'] ?? 'image').toString(),
            'url_or_path': (jm['url_or_path'] ?? jm['urlOrPath'] ?? '')
                .toString(),
            'caption': jm['caption']?.toString(),
            'created_at':
                (jm['created_at'] ??
                        jm['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'sync_status': 'synced',
            'last_error': null,
          });
        }
        await _db.replaceOperationsSurveyMedia(
          surveyId: (s['id'] ?? '').toString(),
          items: items,
        );
      }
    }

    final schedule = data['schedule'];
    if (schedule is Map) {
      final sc = schedule.cast<String, dynamic>();
      await _db.upsertOperationsSchedule(
        row: {
          'id': (sc['id'] ?? '').toString(),
          'job_id': job.id,
          'scheduled_date': (sc['scheduled_date'] ?? sc['scheduledDate'] ?? '')
              .toString(),
          'preferred_time': sc['preferred_time']?.toString(),
          'assigned_tech_id':
              (sc['assigned_tech_id'] ?? sc['assignedTechId'] ?? '').toString(),
          'additional_tech_ids_json': jsonEncode(
            (sc['additional_tech_ids'] is List)
                ? (sc['additional_tech_ids'] as List)
                      .map((e) => e.toString())
                      .toList()
                : const <String>[],
          ),
          'customer_availability_notes': sc['customer_availability_notes']
              ?.toString(),
          'created_at':
              (sc['created_at'] ??
                      sc['createdAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'updated_at':
              (sc['updated_at'] ??
                      sc['updatedAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'sync_status': 'synced',
          'last_error': null,
        },
      );
    }

    final reports = data['installation_reports'];
    if (reports is List) {
      for (final r in reports.whereType<Map>()) {
        final jr = r.cast<String, dynamic>();
        await _db.upsertOperationsInstallationReport(
          row: {
            'id': (jr['id'] ?? '').toString(),
            'job_id': job.id,
            'started_at': jr['started_at']?.toString(),
            'finished_at': jr['finished_at']?.toString(),
            'tech_notes': jr['tech_notes']?.toString(),
            'work_done_summary': jr['work_done_summary']?.toString(),
            'installed_products_json': jr['installed_products'] == null
                ? null
                : jsonEncode(jr['installed_products']),
            'media_urls_json': jr['media_urls'] == null
                ? jsonEncode(const <String>[])
                : jsonEncode(
                    (jr['media_urls'] as List)
                        .map((e) => e.toString())
                        .toList(),
                  ),
            'signature_name': jr['signature_name']?.toString(),
            'created_by_tech_id':
                (jr['created_by_tech_id'] ?? jr['createdByTechId'])?.toString(),
            'created_at':
                (jr['created_at'] ??
                        jr['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'sync_status': 'synced',
            'last_error': null,
          },
        );
      }
    }

    final tickets = data['warranty_tickets'];
    if (tickets is List) {
      for (final t in tickets.whereType<Map>()) {
        final jt = t.cast<String, dynamic>();
        await _db.upsertOperationsWarrantyTicket(
          row: {
            'id': (jt['id'] ?? '').toString(),
            'job_id': job.id,
            'reason': (jt['reason'] ?? '').toString(),
            'reported_at':
                (jt['reported_at'] ??
                        jt['reportedAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'status': (jt['status'] ?? 'pending').toString(),
            'assigned_tech_id': jt['assigned_tech_id']?.toString(),
            'resolution_notes': jt['resolution_notes']?.toString(),
            'resolved_at': jt['resolved_at']?.toString(),
            'created_at':
                (jt['created_at'] ??
                        jt['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
            'sync_status': 'synced',
            'last_error': null,
          },
        );
      }
    }

    return data;
  }

  Future<void> updateJobStatus({
    required String jobId,
    required String status, // PENDIENTE|EN_PROCESO|TERMINADO|CANCELADO
    String? technicianNotes,
    String? cancelReason,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (technicianNotes != null) 'technicianNotes': technicianNotes,
      if (cancelReason != null) 'cancelReason': cancelReason,
    };

    final data = await _api.patchJobStatus(jobId, payload);
    final job = OperationsJob.fromServerJson(data);
    await _db.upsertOperationsJob(
      row: job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      ),
    );
  }

  Future<void> patchOperacionEstado({
    required String jobId,
    required String estado,
    String? note,
  }) async {
    final data = await _api.patchOperacionEstado(
      jobId,
      estado: estado,
      note: note,
    );
    final job = OperationsJob.fromServerJson(data);
    await _db.upsertOperationsJob(
      row: job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      ),
    );
  }

  Future<void> programarOperacion({
    required String jobId,
    required String scheduledDate, // YYYY-MM-DD
    String? preferredTime,
    String? assignedTechId,
    String? note,
  }) async {
    final data = await _api.programarOperacion(
      jobId,
      scheduledDate: scheduledDate,
      preferredTime: preferredTime,
      assignedTechId: assignedTechId,
      note: note,
    );

    final jobJson = (data['job'] is Map)
        ? (data['job'] as Map).cast<String, dynamic>()
        : data;
    final job = OperationsJob.fromServerJson(jobJson);
    await _db.upsertOperationsJob(
      row: job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      ),
    );

    final schedule = data['schedule'];
    if (schedule is Map) {
      final scheduleJson = schedule.cast<String, dynamic>();
      final rawDate =
          (scheduleJson['scheduled_date'] ??
                  scheduleJson['scheduledDate'] ??
                  '')
              .toString();
      final rawTime = scheduleJson['preferred_time']?.toString();
      await _db.upsertOperationsSchedule(
        row: {
          'id': (scheduleJson['id'] ?? '').toString(),
          'job_id': job.id,
          'scheduled_date': rawDate,
          'preferred_time': rawTime,
          'assigned_tech_id':
              (scheduleJson['assigned_tech_id'] ??
                      scheduleJson['assignedTechId'] ??
                      '')
                  .toString(),
          'additional_tech_ids_json': jsonEncode(
            (scheduleJson['additional_tech_ids'] is List)
                ? (scheduleJson['additional_tech_ids'] as List)
                      .map((e) => e.toString())
                      .toList()
                : const <String>[],
          ),
          'customer_availability_notes':
              scheduleJson['customer_availability_notes']?.toString(),
          'created_at':
              (scheduleJson['created_at'] ??
                      scheduleJson['createdAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'updated_at':
              (scheduleJson['updated_at'] ??
                      scheduleJson['updatedAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'sync_status': 'synced',
          'last_error': null,
        },
      );

      final jobRow = job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      );
      jobRow['scheduled_date'] = DateTime.tryParse(rawDate)?.toIso8601String();
      jobRow['preferred_time'] = rawTime;
      await _db.upsertOperationsJob(row: jobRow);
    }
  }

  Future<void> convertirALaAgenda({
    required String jobId,
    required String tipoDestino,
    required String scheduledDate,
    String? preferredTime,
    String? assignedTechId,
    String? note,
  }) async {
    final data = await _api.convertirALaAgenda(
      jobId,
      tipoDestino: tipoDestino,
      scheduledDate: scheduledDate,
      preferredTime: preferredTime,
      assignedTechId: assignedTechId,
      note: note,
    );

    final jobJson = (data['job'] is Map)
        ? (data['job'] as Map).cast<String, dynamic>()
        : data;
    final job = OperationsJob.fromServerJson(jobJson);
    await _db.upsertOperationsJob(
      row: job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      ),
    );

    final schedule = data['schedule'];
    if (schedule is Map) {
      final scheduleJson = schedule.cast<String, dynamic>();
      final rawDate =
          (scheduleJson['scheduled_date'] ??
                  scheduleJson['scheduledDate'] ??
                  '')
              .toString();
      final rawTime = scheduleJson['preferred_time']?.toString();
      await _db.upsertOperationsSchedule(
        row: {
          'id': (scheduleJson['id'] ?? '').toString(),
          'job_id': job.id,
          'scheduled_date': rawDate,
          'preferred_time': rawTime,
          'assigned_tech_id':
              (scheduleJson['assigned_tech_id'] ??
                      scheduleJson['assignedTechId'] ??
                      '')
                  .toString(),
          'additional_tech_ids_json': jsonEncode(
            (scheduleJson['additional_tech_ids'] is List)
                ? (scheduleJson['additional_tech_ids'] as List)
                      .map((e) => e.toString())
                      .toList()
                : const <String>[],
          ),
          'customer_availability_notes':
              scheduleJson['customer_availability_notes']?.toString(),
          'created_at':
              (scheduleJson['created_at'] ??
                      scheduleJson['createdAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'updated_at':
              (scheduleJson['updated_at'] ??
                      scheduleJson['updatedAt'] ??
                      DateTime.now().toIso8601String())
                  .toString(),
          'sync_status': 'synced',
          'last_error': null,
        },
      );

      final jobRow = job.toLocalRow(
        overrideSyncStatus: 'synced',
        overrideLastError: null,
      );
      jobRow['scheduled_date'] = DateTime.tryParse(rawDate)?.toIso8601String();
      jobRow['preferred_time'] = rawTime;
      await _db.upsertOperationsJob(row: jobRow);
    }
  }

  Future<List<Map<String, dynamic>>> listJobHistory({
    required String jobId,
  }) async {
    final data = await _api.listJobHistory(jobId);
    final items =
        (data['items'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    return items;
  }

  Future<OperationsJob?> getLocalJobById({required String id}) async {
    final row = await _db.getOperationsJob(id: id);
    if (row == null) return null;
    return OperationsJob.fromLocalRow(row);
  }

  Future<OperationsSurvey?> getLocalSurveyByJobId({
    required String jobId,
  }) async {
    final row = await _db.getOperationsSurveyByJob(jobId: jobId);
    if (row == null) return null;
    return OperationsSurvey.fromLocalRow(row);
  }

  Future<List<OperationsSurveyMedia>> listLocalSurveyMediaByJobId({
    required String jobId,
  }) async {
    final survey = await getLocalSurveyByJobId(jobId: jobId);
    if (survey == null) return const <OperationsSurveyMedia>[];
    final rows = await _db.listOperationsSurveyMedia(surveyId: survey.id);
    return rows.map(OperationsSurveyMedia.fromLocalRow).toList(growable: false);
  }

  Future<OperationsSchedule?> getLocalScheduleByJobId({
    required String jobId,
  }) async {
    final row = await _db.getOperationsScheduleByJob(jobId: jobId);
    if (row == null) return null;
    return OperationsSchedule.fromLocalRow(row);
  }

  Future<List<OperationsInstallationReport>> listLocalInstallationReports({
    required String jobId,
  }) async {
    final rows = await _db.listOperationsInstallationReports(jobId: jobId);
    return rows
        .map(OperationsInstallationReport.fromLocalRow)
        .toList(growable: false);
  }

  Future<List<OperationsWarrantyTicket>> listLocalWarrantyTickets({
    required String jobId,
  }) async {
    final rows = await _db.listOperationsWarrantyTickets(jobId: jobId);
    return rows
        .map(OperationsWarrantyTicket.fromLocalRow)
        .toList(growable: false);
  }

  Future<OperationsJob> createJobLocalFirst({
    required String empresaId,
    required String crmCustomerId,
    required String serviceType,
    required String priority,
    required String initialStatus,
    required String createdByUserId,
    String? notes,
    String? assignedTechId,
    List<String> assignedTeamIds = const [],
    String? customerName,
    String? customerPhone,
    String? customerAddress,
  }) async {
    final now = DateTime.now();
    final id = _newId();

    final inferredTipoTrabajo = () {
      final s = initialStatus.trim().toLowerCase();
      if (s.startsWith('warranty_') || s == 'closed') return 'GARANTIA';
      if (s.startsWith('pending_survey') || s.startsWith('survey_'))
        return 'LEVANTAMIENTO';
      final st = serviceType.trim().toLowerCase();
      if (st.contains('mantenimiento')) return 'MANTENIMIENTO';
      return 'INSTALACION';
    }();

    final inferredEstado = () {
      final s = initialStatus.trim().toLowerCase();
      if (s == 'cancelled') return 'CANCELADO';
      if (s == 'closed') return 'CERRADO';
      if (s == 'completed') return 'FINALIZADO';
      if (s == 'scheduled') return 'PROGRAMADO';
      if (s.endsWith('_in_progress')) return 'EN_EJECUCION';
      if (s == 'pending_scheduling') {
        return inferredTipoTrabajo == 'LEVANTAMIENTO'
            ? 'FINALIZADO'
            : 'PENDIENTE';
      }
      return 'PENDIENTE';
    }();

    final job = OperationsJob(
      id: id,
      empresaId: empresaId,
      crmCustomerId: crmCustomerId,
      customerName: customerName ?? 'Cliente',
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      serviceType: serviceType,
      priority: priority,
      status: initialStatus,
      tipoTrabajo: inferredTipoTrabajo,
      estado: inferredEstado,
      notes: notes,
      createdByUserId: createdByUserId,
      assignedTechId: assignedTechId,
      assignedTeamIds: assignedTeamIds,
      createdAt: now,
      updatedAt: now,
      deleted: false,
      deletedAt: null,
      syncStatus: 'pending',
      lastError: null,
    );

    await _db.upsertOperationsJob(row: job.toLocalRow());

    await _db.enqueueSync(
      module: _syncModule,
      op: 'create_job',
      entityId: id,
      payloadJson: jsonEncode(
        job.toCreatePayload(initialStatus: initialStatus),
      ),
    );

    // ignore: unawaited_futures
    syncPending();

    return job;
  }

  Future<void> submitSurveyLocalFirst({
    required String empresaId,
    required String jobId,
    required String createdByTechId,
    required String mode,
    double? gpsLat,
    double? gpsLng,
    String? addressConfirmed,
    String complexity = 'basic',
    String? siteNotes,
    dynamic toolsNeeded,
    dynamic materialsNeeded,
    dynamic productsToUse,
    String? futureOpportunities,
    List<OperationsSurveyMedia> media = const [],
  }) async {
    final now = DateTime.now();
    final surveyId = _newId();

    final survey = OperationsSurvey(
      id: surveyId,
      jobId: jobId,
      mode: mode,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      addressConfirmed: addressConfirmed,
      complexity: complexity,
      siteNotes: siteNotes,
      toolsNeeded: toolsNeeded,
      materialsNeeded: materialsNeeded,
      productsToUse: productsToUse,
      futureOpportunities: futureOpportunities,
      createdByTechId: createdByTechId,
      createdAt: now,
      syncStatus: 'pending',
      lastError: null,
    );

    await _db.upsertOperationsSurvey(row: survey.toLocalRow());

    await _db.replaceOperationsSurveyMedia(
      surveyId: surveyId,
      items: media
          .map(
            (m) => OperationsSurveyMedia(
              id: m.id,
              surveyId: surveyId,
              type: m.type,
              urlOrPath: m.urlOrPath,
              caption: m.caption,
              createdAt: m.createdAt,
              syncStatus: 'pending',
              lastError: null,
            ).toLocalRow(),
          )
          .toList(growable: false),
    );

    // Patch local job status best-effort
    final existingJobRow = await _db.getOperationsJob(id: jobId);
    if (existingJobRow != null) {
      final existingJob = OperationsJob.fromLocalRow(existingJobRow);
      final patched = OperationsJob(
        id: existingJob.id,
        empresaId: existingJob.empresaId,
        crmCustomerId: existingJob.crmCustomerId,
        customerName: existingJob.customerName,
        customerPhone: existingJob.customerPhone,
        customerAddress: existingJob.customerAddress,
        serviceType: existingJob.serviceType,
        priority: existingJob.priority,
        status: 'pending_scheduling',
        tipoTrabajo: existingJob.tipoTrabajo,
        estado: 'FINALIZADO',
        notes: existingJob.notes,
        createdByUserId: existingJob.createdByUserId,
        assignedTechId: existingJob.assignedTechId,
        assignedTeamIds: existingJob.assignedTeamIds,
        createdAt: existingJob.createdAt,
        updatedAt: now,
        deleted: existingJob.deleted,
        deletedAt: existingJob.deletedAt,
        syncStatus: 'pending',
        lastError: null,
      );
      await _db.upsertOperationsJob(row: patched.toLocalRow());
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'submit_survey',
      entityId: surveyId,
      payloadJson: jsonEncode({
        'id': surveyId,
        'job_id': jobId,
        'mode': mode,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'address_confirmed': addressConfirmed,
        'complexity': complexity,
        'site_notes': siteNotes,
        'tools_needed': toolsNeeded,
        'materials_needed': materialsNeeded,
        'products_to_use': productsToUse,
        'future_opportunities': futureOpportunities,
        'media': media
            .map(
              (m) => {
                'id': m.id,
                'type': m.type,
                'url_or_path': m.urlOrPath,
                'caption': m.caption,
              },
            )
            .toList(growable: false),
      }),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> scheduleJobLocalFirst({
    required String jobId,
    required String assignedTechId,
    required DateTime scheduledDate,
    String? preferredTime,
    List<String> additionalTechIds = const [],
    String? customerAvailabilityNotes,
  }) async {
    final now = DateTime.now();
    final scheduleId = _newId();

    final schedule = OperationsSchedule(
      id: scheduleId,
      jobId: jobId,
      scheduledDate: scheduledDate,
      preferredTime: preferredTime,
      assignedTechId: assignedTechId,
      additionalTechIds: additionalTechIds,
      customerAvailabilityNotes: customerAvailabilityNotes,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending',
      lastError: null,
    );

    await _db.upsertOperationsSchedule(row: schedule.toLocalRow());

    // Patch local job status best-effort
    final existingJobRow = await _db.getOperationsJob(id: jobId);
    if (existingJobRow != null) {
      final existingJob = OperationsJob.fromLocalRow(existingJobRow);
      final patched = OperationsJob(
        id: existingJob.id,
        empresaId: existingJob.empresaId,
        crmCustomerId: existingJob.crmCustomerId,
        customerName: existingJob.customerName,
        customerPhone: existingJob.customerPhone,
        customerAddress: existingJob.customerAddress,
        serviceType: existingJob.serviceType,
        priority: existingJob.priority,
        status: 'scheduled',
        tipoTrabajo: existingJob.tipoTrabajo,
        estado: 'PROGRAMADO',
        notes: existingJob.notes,
        createdByUserId: existingJob.createdByUserId,
        assignedTechId: assignedTechId,
        assignedTeamIds: existingJob.assignedTeamIds,
        createdAt: existingJob.createdAt,
        updatedAt: now,
        deleted: existingJob.deleted,
        deletedAt: existingJob.deletedAt,
        syncStatus: 'pending',
        lastError: null,
      );
      await _db.upsertOperationsJob(row: patched.toLocalRow());
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'schedule_job',
      entityId: scheduleId,
      payloadJson: jsonEncode({
        'id': scheduleId,
        'job_id': jobId,
        'scheduled_date': _isoDateOnly(scheduledDate),
        'preferred_time': preferredTime,
        'assigned_tech_id': assignedTechId,
        'additional_tech_ids': additionalTechIds,
        'customer_availability_notes': customerAvailabilityNotes,
      }),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> startInstallationLocalFirst({
    required String jobId,
    DateTime? startedAt,
  }) async {
    final now = DateTime.now();

    // Patch local job status best-effort
    final existingJobRow = await _db.getOperationsJob(id: jobId);
    if (existingJobRow != null) {
      final existingJob = OperationsJob.fromLocalRow(existingJobRow);
      final patched = OperationsJob(
        id: existingJob.id,
        empresaId: existingJob.empresaId,
        crmCustomerId: existingJob.crmCustomerId,
        customerName: existingJob.customerName,
        customerPhone: existingJob.customerPhone,
        customerAddress: existingJob.customerAddress,
        serviceType: existingJob.serviceType,
        priority: existingJob.priority,
        status: 'installation_in_progress',
        tipoTrabajo: existingJob.tipoTrabajo,
        estado: 'EN_EJECUCION',
        notes: existingJob.notes,
        createdByUserId: existingJob.createdByUserId,
        assignedTechId: existingJob.assignedTechId,
        assignedTeamIds: existingJob.assignedTeamIds,
        createdAt: existingJob.createdAt,
        updatedAt: now,
        deleted: existingJob.deleted,
        deletedAt: existingJob.deletedAt,
        syncStatus: 'pending',
        lastError: null,
      );
      await _db.upsertOperationsJob(row: patched.toLocalRow());
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'start_installation',
      entityId: jobId,
      payloadJson: jsonEncode({
        'job_id': jobId,
        if (startedAt != null) 'started_at': startedAt.toIso8601String(),
      }),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> completeInstallationLocalFirst({
    required String jobId,
    required String createdByTechId,
    DateTime? finishedAt,
    String? techNotes,
    String? workDoneSummary,
    dynamic installedProducts,
    List<String> mediaUrls = const [],
    String? signatureName,
  }) async {
    final now = DateTime.now();
    final id = _newId();

    final report = OperationsInstallationReport(
      id: id,
      jobId: jobId,
      startedAt: null,
      finishedAt: finishedAt ?? now,
      techNotes: techNotes,
      workDoneSummary: workDoneSummary,
      installedProducts: installedProducts,
      mediaUrls: mediaUrls,
      signatureName: signatureName,
      createdByTechId: createdByTechId,
      createdAt: now,
      syncStatus: 'pending',
      lastError: null,
    );

    await _db.upsertOperationsInstallationReport(row: report.toLocalRow());

    // Patch local job status best-effort
    final existingJobRow = await _db.getOperationsJob(id: jobId);
    if (existingJobRow != null) {
      final existingJob = OperationsJob.fromLocalRow(existingJobRow);
      final patched = OperationsJob(
        id: existingJob.id,
        empresaId: existingJob.empresaId,
        crmCustomerId: existingJob.crmCustomerId,
        customerName: existingJob.customerName,
        customerPhone: existingJob.customerPhone,
        customerAddress: existingJob.customerAddress,
        serviceType: existingJob.serviceType,
        priority: existingJob.priority,
        status: 'completed',
        tipoTrabajo: existingJob.tipoTrabajo,
        estado: 'FINALIZADO',
        notes: existingJob.notes,
        createdByUserId: existingJob.createdByUserId,
        assignedTechId: existingJob.assignedTechId,
        assignedTeamIds: existingJob.assignedTeamIds,
        createdAt: existingJob.createdAt,
        updatedAt: now,
        deleted: existingJob.deleted,
        deletedAt: existingJob.deletedAt,
        syncStatus: 'pending',
        lastError: null,
      );
      await _db.upsertOperationsJob(row: patched.toLocalRow());
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'complete_installation',
      entityId: id,
      payloadJson: jsonEncode({
        'id': id,
        'job_id': jobId,
        if (finishedAt != null) 'finished_at': finishedAt.toIso8601String(),
        'tech_notes': techNotes,
        'work_done_summary': workDoneSummary,
        'installed_products': installedProducts,
        'media_urls': mediaUrls,
        'signature_name': signatureName,
      }),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> createWarrantyTicketLocalFirst({
    required String jobId,
    required String reason,
    String? assignedTechId,
  }) async {
    final now = DateTime.now();
    final id = _newId();

    final ticket = OperationsWarrantyTicket(
      id: id,
      jobId: jobId,
      reason: reason,
      reportedAt: now,
      status: 'pending',
      assignedTechId: assignedTechId,
      resolutionNotes: null,
      resolvedAt: null,
      createdAt: now,
      syncStatus: 'pending',
      lastError: null,
    );

    await _db.upsertOperationsWarrantyTicket(row: ticket.toLocalRow());

    // Patch local job status best-effort
    final existingJobRow = await _db.getOperationsJob(id: jobId);
    if (existingJobRow != null) {
      final existingJob = OperationsJob.fromLocalRow(existingJobRow);
      final patched = OperationsJob(
        id: existingJob.id,
        empresaId: existingJob.empresaId,
        crmCustomerId: existingJob.crmCustomerId,
        customerName: existingJob.customerName,
        customerPhone: existingJob.customerPhone,
        customerAddress: existingJob.customerAddress,
        serviceType: existingJob.serviceType,
        priority: existingJob.priority,
        status: 'warranty_pending',
        tipoTrabajo: 'GARANTIA',
        estado: 'PENDIENTE',
        notes: existingJob.notes,
        createdByUserId: existingJob.createdByUserId,
        assignedTechId: existingJob.assignedTechId,
        assignedTeamIds: existingJob.assignedTeamIds,
        createdAt: existingJob.createdAt,
        updatedAt: now,
        deleted: existingJob.deleted,
        deletedAt: existingJob.deletedAt,
        syncStatus: 'pending',
        lastError: null,
      );
      await _db.upsertOperationsJob(row: patched.toLocalRow());
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'create_warranty_ticket',
      entityId: id,
      payloadJson: jsonEncode({
        'id': id,
        'job_id': jobId,
        'reason': reason,
        'assigned_tech_id': assignedTechId,
      }),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> patchWarrantyTicketLocalFirst({
    required String ticketId,
    required String jobId,
    Map<String, dynamic> patch = const {},
  }) async {
    // Update local ticket immediately for better UX.
    try {
      final rows = await _db.listOperationsWarrantyTickets(jobId: jobId);
      Map<String, Object?>? existing;
      for (final r in rows) {
        if ((r['id'] ?? '').toString() == ticketId) {
          existing = r;
          break;
        }
      }

      if (existing != null) {
        final merged = Map<String, Object?>.from(existing);
        if (patch.containsKey('status'))
          merged['status'] = patch['status']?.toString();
        if (patch.containsKey('assigned_tech_id'))
          merged['assigned_tech_id'] = patch['assigned_tech_id']?.toString();
        if (patch.containsKey('resolution_notes'))
          merged['resolution_notes'] = patch['resolution_notes']?.toString();
        if (patch.containsKey('resolved_at'))
          merged['resolved_at'] = patch['resolved_at']?.toString();
        merged['sync_status'] = 'pending';
        merged['last_error'] = null;
        await _db.upsertOperationsWarrantyTicket(row: merged);
      }
    } catch (_) {
      // Best-effort local update; sync queue still ensures eventual consistency.
    }

    // Patch local job status best-effort based on ticket status.
    final nextStatus = patch['status']?.toString().trim().toLowerCase();
    if (nextStatus != null && nextStatus.isNotEmpty) {
      try {
        final existingJobRow = await _db.getOperationsJob(id: jobId);
        if (existingJobRow != null) {
          final existingJob = OperationsJob.fromLocalRow(existingJobRow);

          String jobStatus = existingJob.status;
          String jobTipoTrabajo = existingJob.tipoTrabajo;
          String jobEstado = existingJob.estado;
          if (nextStatus == 'pending') {
            jobStatus = 'warranty_pending';
            jobTipoTrabajo = 'GARANTIA';
            jobEstado = 'PENDIENTE';
          } else if (nextStatus == 'in_progress') {
            jobStatus = 'warranty_in_progress';
            jobTipoTrabajo = 'GARANTIA';
            jobEstado = 'EN_EJECUCION';
          } else if (nextStatus == 'resolved') {
            jobStatus = 'closed';
            jobTipoTrabajo = 'GARANTIA';
            jobEstado = 'CERRADO';
          }

          final patchedJob = OperationsJob(
            id: existingJob.id,
            empresaId: existingJob.empresaId,
            crmCustomerId: existingJob.crmCustomerId,
            customerName: existingJob.customerName,
            customerPhone: existingJob.customerPhone,
            customerAddress: existingJob.customerAddress,
            serviceType: existingJob.serviceType,
            priority: existingJob.priority,
            status: jobStatus,
            tipoTrabajo: jobTipoTrabajo,
            estado: jobEstado,
            notes: existingJob.notes,
            createdByUserId: existingJob.createdByUserId,
            assignedTechId: existingJob.assignedTechId,
            assignedTeamIds: existingJob.assignedTeamIds,
            createdAt: existingJob.createdAt,
            updatedAt: DateTime.now(),
            deleted: existingJob.deleted,
            deletedAt: existingJob.deletedAt,
            syncStatus: 'pending',
            lastError: null,
          );

          await _db.upsertOperationsJob(row: patchedJob.toLocalRow());
        }
      } catch (_) {
        // Best-effort; not critical for sync.
      }
    }

    await _db.enqueueSync(
      module: _syncModule,
      op: 'patch_warranty_ticket',
      entityId: ticketId,
      payloadJson: jsonEncode(patch),
    );

    // ignore: unawaited_futures
    syncPending();
  }

  Future<void> syncPending() async {
    // CRITICAL: Verify session exists before attempting any sync
    final session = await _db.readSession();
    if (session == null) return;

    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.module != _syncModule) continue;

      try {
        if (item.op == 'create_job') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final server = await _api.createJob(payload);
          final job = OperationsJob.fromServerJson(server);
          await _db.upsertOperationsJob(
            row: job.toLocalRow(
              overrideSyncStatus: 'synced',
              overrideLastError: null,
            ),
          );
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'submit_survey') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.submitSurvey(payload);
          // Best-effort: refresh job detail to get consistent status.
          final jobId = (payload['job_id'] ?? '').toString();
          if (jobId.isNotEmpty) {
            // ignore: unawaited_futures
            getJobDetailFromServer(jobId: jobId);
          }
          // Mark local survey as synced
          final localSurveyRow = await _db.getOperationsSurveyByJob(
            jobId: jobId,
          );
          if (localSurveyRow != null) {
            final localSurvey = OperationsSurvey.fromLocalRow(localSurveyRow);
            await _db.upsertOperationsSurvey(
              row: localSurvey.toLocalRow(overrideSyncStatus: 'synced'),
            );
          }

          // If server returned media, we keep local media as-is.
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'schedule_job') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.scheduleJob(payload);
          final jobId = (payload['job_id'] ?? '').toString();
          if (jobId.isNotEmpty) {
            // ignore: unawaited_futures
            getJobDetailFromServer(jobId: jobId);
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'start_installation') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.startInstallation(payload);
          final jobId = (payload['job_id'] ?? '').toString();
          if (jobId.isNotEmpty) {
            // ignore: unawaited_futures
            getJobDetailFromServer(jobId: jobId);
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'complete_installation') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.completeInstallation(payload);
          final jobId = (payload['job_id'] ?? '').toString();
          if (jobId.isNotEmpty) {
            // ignore: unawaited_futures
            getJobDetailFromServer(jobId: jobId);
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'create_warranty_ticket') {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.createWarrantyTicket(payload);
          final jobId = (payload['job_id'] ?? '').toString();
          if (jobId.isNotEmpty) {
            // ignore: unawaited_futures
            getJobDetailFromServer(jobId: jobId);
          }
          await _db.markSyncItemSent(item.id);
          continue;
        }

        if (item.op == 'patch_warranty_ticket') {
          final patch = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          await _api.patchWarrantyTicket(item.entityId, patch);
          await _db.markSyncItemSent(item.id);
          continue;
        }

        // Unknown op: mark as error.
        await _db.markSyncItemError(item.id);
      } catch (e) {
        // CRITICAL: Stop retry loop on 401
        if (e is DioException && e.response?.statusCode == 401) {
          await _db.markSyncItemSent(item.id);
          return;
        }

        await _db.markSyncItemError(item.id);

        // Best-effort: mark job row with error if present
        final local = await _db.getOperationsJob(id: item.entityId);
        if (local != null) {
          final job = OperationsJob.fromLocalRow(local);
          await _db.upsertOperationsJob(
            row: job.toLocalRow(
              overrideSyncStatus: 'error',
              overrideLastError: e.toString(),
            ),
          );
        }
      }
    }
  }

  String _isoDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
