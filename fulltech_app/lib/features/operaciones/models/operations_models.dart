import 'dart:convert';

class OperationsJob {
  final String id;
  final String empresaId;
  final String crmCustomerId;
  final String? crmChatId;
  final String? crmTaskType;
  final String? productId;
  final String? serviceId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? locationText;
  final double? locationLat;
  final double? locationLng;
  final String serviceType;
  final String priority;
  final String status;
  final String? notes;
  final String? technicianNotes;
  final String? cancelReason;
  final DateTime? scheduledDate;
  final String? preferredTime;
  final String? createdByUserId;
  final String? assignedTechId;
  final String? lastUpdateByUserId;
  final List<String> assignedTeamIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? lastError;

  const OperationsJob({
    required this.id,
    required this.empresaId,
    required this.crmCustomerId,
    required this.customerName,
    required this.serviceType,
    required this.priority,
    required this.status,
    this.crmChatId,
    this.crmTaskType,
    this.productId,
    this.serviceId,
    this.customerPhone,
    this.customerAddress,
    this.locationText,
    this.locationLat,
    this.locationLng,
    this.notes,
    this.technicianNotes,
    this.cancelReason,
    this.scheduledDate,
    this.preferredTime,
    this.createdByUserId,
    this.assignedTechId,
    this.lastUpdateByUserId,
    required this.assignedTeamIds,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.deletedAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsJob.fromServerJson(Map<String, dynamic> json) {
    String s(String a, [String? b]) => (json[a] ?? (b == null ? null : json[b]) ?? '').toString();
    String? so(String a, [String? b]) {
      final v = json[a] ?? (b == null ? null : json[b]);
      if (v == null) return null;
      final out = v.toString();
      return out.trim().isEmpty ? null : out;
    }

    final createdAt = DateTime.tryParse(s('created_at', 'createdAt')) ?? DateTime.now();
    final updatedAt = DateTime.tryParse(s('updated_at', 'updatedAt')) ?? createdAt;

    final assignedTeamIdsRaw = json['assigned_team_ids'] ?? json['assignedTeamIds'];
    final assignedTeamIds = assignedTeamIdsRaw is List
        ? assignedTeamIdsRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    DateTime? scheduledDate;
    String? preferredTime;
    final schedule = json['schedule'];
    String? locationText;
    double? locationLat;
    double? locationLng;
    if (schedule is Map) {
      final sc = schedule.cast<String, dynamic>();
      final rawDate = (sc['scheduled_date'] ?? sc['scheduledDate'])?.toString();
      if (rawDate != null && rawDate.trim().isNotEmpty) {
        scheduledDate = DateTime.tryParse(rawDate);
      }
      preferredTime = (sc['preferred_time'] ?? sc['preferredTime'])?.toString();
      if (preferredTime != null && preferredTime.trim().isEmpty) preferredTime = null;

      locationText = (sc['location_text'] ?? sc['locationText'] ?? sc['location'])?.toString();
      if (locationText != null && locationText.trim().isEmpty) locationText = null;

      final rawLat = sc['lat'] ?? sc['latitude'] ?? sc['location_lat'] ?? sc['locationLat'];
      final rawLng = sc['lng'] ?? sc['longitude'] ?? sc['location_lng'] ?? sc['locationLng'];
      if (rawLat is num) locationLat = rawLat.toDouble();
      if (rawLng is num) locationLng = rawLng.toDouble();
    }

    // Some backends may expose location fields at the job level.
    locationText ??= (json['location_text'] ?? json['locationText'] ?? json['location'])?.toString();
    if (locationText != null && locationText!.trim().isEmpty) locationText = null;
    final rawLat2 = json['lat'] ?? json['latitude'] ?? json['location_lat'] ?? json['locationLat'];
    final rawLng2 = json['lng'] ?? json['longitude'] ?? json['location_lng'] ?? json['locationLng'];
    if (locationLat == null && rawLat2 is num) locationLat = rawLat2.toDouble();
    if (locationLng == null && rawLng2 is num) locationLng = rawLng2.toDouble();

    return OperationsJob(
      id: s('id'),
      empresaId: s('empresa_id', 'empresaId'),
      crmCustomerId: s('crm_customer_id', 'crmCustomerId'),
      crmChatId: so('crm_chat_id', 'crmChatId'),
      crmTaskType: so('crm_task_type', 'crmTaskType'),
      productId: so('product_id', 'productId'),
      serviceId: so('service_id', 'serviceId'),
      customerName: s('customer_name', 'customerName'),
      customerPhone: so('customer_phone', 'customerPhone'),
      customerAddress: so('customer_address', 'customerAddress'),
      locationText: locationText,
      locationLat: locationLat,
      locationLng: locationLng,
      serviceType: s('service_type', 'serviceType'),
      priority: so('priority') ?? 'normal',
      status: so('status') ?? 'pending_survey',
      notes: so('notes'),
      technicianNotes: so('technician_notes', 'technicianNotes'),
      cancelReason: so('cancel_reason', 'cancelReason'),
      scheduledDate: scheduledDate,
      preferredTime: preferredTime,
      createdByUserId: so('created_by_user_id', 'createdByUserId'),
      assignedTechId: so('assigned_tech_id', 'assignedTechId'),
      lastUpdateByUserId: so('last_update_by_user_id', 'lastUpdateByUserId'),
      assignedTeamIds: assignedTeamIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deleted: false,
      deletedAt: null,
      syncStatus: 'synced',
      lastError: null,
    );
  }

  factory OperationsJob.fromLocalRow(Map<String, Object?> row) {
    final assignedTeamIdsJson = (row['assigned_team_ids_json'] as String?) ?? '[]';
    final assignedTeamIds = (jsonDecode(assignedTeamIdsJson) as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];

    final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now();
    final updatedAt = DateTime.tryParse((row['updated_at'] ?? '').toString()) ?? createdAt;
    final scheduledDate = DateTime.tryParse((row['scheduled_date'] ?? '').toString());

    return OperationsJob(
      id: (row['id'] ?? '').toString(),
      empresaId: (row['empresa_id'] ?? '').toString(),
      crmCustomerId: (row['crm_customer_id'] ?? '').toString(),
      crmChatId: row['crm_chat_id'] as String?,
      crmTaskType: row['crm_task_type'] as String?,
      productId: row['product_id'] as String?,
      serviceId: row['service_id'] as String?,
      customerName: (row['customer_name'] ?? '').toString(),
      customerPhone: (row['customer_phone'] as String?),
      customerAddress: (row['customer_address'] as String?),
      locationText: null,
      locationLat: null,
      locationLng: null,
      serviceType: (row['service_type'] ?? '').toString(),
      priority: (row['priority'] ?? 'normal').toString(),
      status: (row['status'] ?? 'pending_survey').toString(),
      notes: (row['notes'] as String?),
      technicianNotes: (row['technician_notes'] as String?),
      cancelReason: (row['cancel_reason'] as String?),
      scheduledDate: scheduledDate,
      preferredTime: (row['preferred_time'] as String?),
      createdByUserId: (row['created_by_user_id'] as String?),
      assignedTechId: (row['assigned_tech_id'] as String?),
      lastUpdateByUserId: (row['last_update_by_user_id'] as String?),
      assignedTeamIds: assignedTeamIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deleted: (row['deleted'] as int? ?? 0) == 1,
      deletedAt: DateTime.tryParse((row['deleted_at'] ?? '').toString()),
      syncStatus: (row['sync_status'] ?? 'synced').toString(),
      lastError: (row['last_error'] as String?),
    );
  }

  Map<String, Object?> toLocalRow({
    String? overrideSyncStatus,
    String? overrideLastError,
  }) {
    return {
      'id': id,
      'empresa_id': empresaId,
      'crm_customer_id': crmCustomerId,
      'crm_chat_id': crmChatId,
      'crm_task_type': crmTaskType,
      'product_id': productId,
      'service_id': serviceId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'service_type': serviceType,
      'priority': priority,
      'status': status,
      'notes': notes,
      'technician_notes': technicianNotes,
      'cancel_reason': cancelReason,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'preferred_time': preferredTime,
      'created_by_user_id': createdByUserId,
      'assigned_tech_id': assignedTechId,
      'last_update_by_user_id': lastUpdateByUserId,
      'assigned_team_ids_json': jsonEncode(assignedTeamIds),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted': deleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': overrideLastError ?? lastError,
    };
  }

  Map<String, dynamic> toCreatePayload({
    required String initialStatus,
  }) {
    return {
      'id': id,
      'crm_customer_id': crmCustomerId,
      'service_type': serviceType,
      'priority': priority,
      'notes': notes,
      'initial_status': initialStatus,
      'assigned_tech_id': assignedTechId,
      'assigned_team_ids': assignedTeamIds,
    };
  }
}

class OperationsSurvey {
  final String id;
  final String jobId;
  final String mode;
  final double? gpsLat;
  final double? gpsLng;
  final String? addressConfirmed;
  final String complexity;
  final String? siteNotes;
  final dynamic toolsNeeded;
  final dynamic materialsNeeded;
  final dynamic productsToUse;
  final String? futureOpportunities;
  final String? createdByTechId;
  final DateTime createdAt;
  final String syncStatus;
  final String? lastError;

  const OperationsSurvey({
    required this.id,
    required this.jobId,
    required this.mode,
    required this.gpsLat,
    required this.gpsLng,
    required this.addressConfirmed,
    required this.complexity,
    required this.siteNotes,
    required this.toolsNeeded,
    required this.materialsNeeded,
    required this.productsToUse,
    required this.futureOpportunities,
    required this.createdByTechId,
    required this.createdAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsSurvey.fromLocalRow(Map<String, Object?> row) {
    dynamic decode(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      try {
        return jsonDecode(s);
      } catch (_) {
        return null;
      }
    }

    return OperationsSurvey(
      id: (row['id'] ?? '').toString(),
      jobId: (row['job_id'] ?? '').toString(),
      mode: (row['mode'] ?? 'physical').toString(),
      gpsLat: (row['gps_lat'] as num?)?.toDouble(),
      gpsLng: (row['gps_lng'] as num?)?.toDouble(),
      addressConfirmed: row['address_confirmed'] as String?,
      complexity: (row['complexity'] ?? 'basic').toString(),
      siteNotes: row['site_notes'] as String?,
      toolsNeeded: decode(row['tools_needed_json'] as String?),
      materialsNeeded: decode(row['materials_needed_json'] as String?),
      productsToUse: decode(row['products_to_use_json'] as String?),
      futureOpportunities: row['future_opportunities'] as String?,
      createdByTechId: row['created_by_tech_id'] as String?,
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? 'pending').toString(),
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideSyncStatus}) {
    String? encode(dynamic v) => v == null ? null : jsonEncode(v);

    return {
      'id': id,
      'job_id': jobId,
      'mode': mode,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'address_confirmed': addressConfirmed,
      'complexity': complexity,
      'site_notes': siteNotes,
      'tools_needed_json': encode(toolsNeeded),
      'materials_needed_json': encode(materialsNeeded),
      'products_to_use_json': encode(productsToUse),
      'future_opportunities': futureOpportunities,
      'created_by_tech_id': createdByTechId,
      'created_at': createdAt.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': lastError,
    };
  }
}

class OperationsSurveyMedia {
  final String id;
  final String surveyId;
  final String type;
  final String urlOrPath;
  final String? caption;
  final DateTime createdAt;
  final String syncStatus;
  final String? lastError;

  const OperationsSurveyMedia({
    required this.id,
    required this.surveyId,
    required this.type,
    required this.urlOrPath,
    required this.caption,
    required this.createdAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsSurveyMedia.fromLocalRow(Map<String, Object?> row) {
    return OperationsSurveyMedia(
      id: (row['id'] ?? '').toString(),
      surveyId: (row['survey_id'] ?? '').toString(),
      type: (row['type'] ?? 'image').toString(),
      urlOrPath: (row['url_or_path'] ?? '').toString(),
      caption: row['caption'] as String?,
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? 'pending').toString(),
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideSyncStatus}) {
    return {
      'id': id,
      'survey_id': surveyId,
      'type': type,
      'url_or_path': urlOrPath,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': lastError,
    };
  }
}

class OperationsSchedule {
  final String id;
  final String jobId;
  final DateTime scheduledDate;
  final String? preferredTime;
  final String assignedTechId;
  final List<String> additionalTechIds;
  final String? customerAvailabilityNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final String? lastError;

  const OperationsSchedule({
    required this.id,
    required this.jobId,
    required this.scheduledDate,
    required this.preferredTime,
    required this.assignedTechId,
    required this.additionalTechIds,
    required this.customerAvailabilityNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsSchedule.fromLocalRow(Map<String, Object?> row) {
    final additionalJson = (row['additional_tech_ids_json'] as String?) ?? '[]';
    final additional = (jsonDecode(additionalJson) as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];

    final scheduledDate = DateTime.tryParse((row['scheduled_date'] ?? '').toString()) ?? DateTime.now();

    return OperationsSchedule(
      id: (row['id'] ?? '').toString(),
      jobId: (row['job_id'] ?? '').toString(),
      scheduledDate: scheduledDate,
      preferredTime: row['preferred_time'] as String?,
      assignedTechId: (row['assigned_tech_id'] ?? '').toString(),
      additionalTechIds: additional,
      customerAvailabilityNotes: row['customer_availability_notes'] as String?,
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((row['updated_at'] ?? '').toString()) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? 'pending').toString(),
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideSyncStatus}) {
    return {
      'id': id,
      'job_id': jobId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'preferred_time': preferredTime,
      'assigned_tech_id': assignedTechId,
      'additional_tech_ids_json': jsonEncode(additionalTechIds),
      'customer_availability_notes': customerAvailabilityNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': lastError,
    };
  }
}

class OperationsInstallationReport {
  final String id;
  final String jobId;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? techNotes;
  final String? workDoneSummary;
  final dynamic installedProducts;
  final List<String> mediaUrls;
  final String? signatureName;
  final String? createdByTechId;
  final DateTime createdAt;
  final String syncStatus;
  final String? lastError;

  const OperationsInstallationReport({
    required this.id,
    required this.jobId,
    required this.startedAt,
    required this.finishedAt,
    required this.techNotes,
    required this.workDoneSummary,
    required this.installedProducts,
    required this.mediaUrls,
    required this.signatureName,
    required this.createdByTechId,
    required this.createdAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsInstallationReport.fromLocalRow(Map<String, Object?> row) {
    dynamic decode(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      try {
        return jsonDecode(s);
      } catch (_) {
        return null;
      }
    }

    final mediaJson = (row['media_urls_json'] as String?) ?? '[]';
    final mediaUrls = (jsonDecode(mediaJson) as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];

    return OperationsInstallationReport(
      id: (row['id'] ?? '').toString(),
      jobId: (row['job_id'] ?? '').toString(),
      startedAt: DateTime.tryParse((row['started_at'] ?? '').toString()),
      finishedAt: DateTime.tryParse((row['finished_at'] ?? '').toString()),
      techNotes: row['tech_notes'] as String?,
      workDoneSummary: row['work_done_summary'] as String?,
      installedProducts: decode(row['installed_products_json'] as String?),
      mediaUrls: mediaUrls,
      signatureName: row['signature_name'] as String?,
      createdByTechId: row['created_by_tech_id'] as String?,
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? 'pending').toString(),
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideSyncStatus}) {
    String? encode(dynamic v) => v == null ? null : jsonEncode(v);

    return {
      'id': id,
      'job_id': jobId,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'tech_notes': techNotes,
      'work_done_summary': workDoneSummary,
      'installed_products_json': encode(installedProducts),
      'media_urls_json': jsonEncode(mediaUrls),
      'signature_name': signatureName,
      'created_by_tech_id': createdByTechId,
      'created_at': createdAt.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': lastError,
    };
  }
}

class OperationsWarrantyTicket {
  final String id;
  final String jobId;
  final String reason;
  final DateTime reportedAt;
  final String status;
  final String? assignedTechId;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final String syncStatus;
  final String? lastError;

  const OperationsWarrantyTicket({
    required this.id,
    required this.jobId,
    required this.reason,
    required this.reportedAt,
    required this.status,
    required this.assignedTechId,
    required this.resolutionNotes,
    required this.resolvedAt,
    required this.createdAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory OperationsWarrantyTicket.fromLocalRow(Map<String, Object?> row) {
    final reportedAt = DateTime.tryParse((row['reported_at'] ?? '').toString()) ?? DateTime.now();

    return OperationsWarrantyTicket(
      id: (row['id'] ?? '').toString(),
      jobId: (row['job_id'] ?? '').toString(),
      reason: (row['reason'] ?? '').toString(),
      reportedAt: reportedAt,
      status: (row['status'] ?? 'pending').toString(),
      assignedTechId: row['assigned_tech_id'] as String?,
      resolutionNotes: row['resolution_notes'] as String?,
      resolvedAt: DateTime.tryParse((row['resolved_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? reportedAt,
      syncStatus: (row['sync_status'] ?? 'pending').toString(),
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideSyncStatus}) {
    return {
      'id': id,
      'job_id': jobId,
      'reason': reason,
      'reported_at': reportedAt.toIso8601String(),
      'status': status,
      'assigned_tech_id': assignedTechId,
      'resolution_notes': resolutionNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sync_status': overrideSyncStatus ?? syncStatus,
      'last_error': lastError,
    };
  }
}
