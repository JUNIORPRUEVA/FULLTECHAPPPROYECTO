import 'package:dio/dio.dart';
import '../models/maintenance_models.dart';

class MaintenanceRemoteDataSource {
  final Dio dio;

  MaintenanceRemoteDataSource(this.dio);

  static const _noOfflineQueueExtra = {'offlineQueue': false};

  Map<String, dynamic> _createMaintenancePayload(CreateMaintenanceDto dto) {
    return {
      'producto_id': dto.productoId,
      'maintenance_type': dto.maintenanceType.name.toUpperCase(),
      if (dto.statusBefore != null)
        'status_before': _healthStatusToString(dto.statusBefore!),
      'status_after': _healthStatusToString(dto.statusAfter),
      if (dto.issueCategory != null)
        'issue_category': dto.issueCategory!.name.toUpperCase(),
      'description': dto.description,
      if (dto.internalNotes != null && dto.internalNotes!.trim().isNotEmpty)
        'internal_notes': dto.internalNotes,
      if (dto.cost != null) 'cost': dto.cost,
      if (dto.warrantyCaseId != null && dto.warrantyCaseId!.trim().isNotEmpty)
        'warranty_case_id': dto.warrantyCaseId,
      if (dto.attachmentUrls.isNotEmpty) 'attachment_urls': dto.attachmentUrls,
    };
  }

  Map<String, dynamic> _createWarrantyPayload(CreateWarrantyDto dto) {
    return {
      'producto_id': dto.productoId,
      'problem_description': dto.problemDescription,
      if (dto.supplierName != null && dto.supplierName!.trim().isNotEmpty)
        'supplier_name': dto.supplierName,
      if (dto.supplierTicket != null && dto.supplierTicket!.trim().isNotEmpty)
        'supplier_ticket': dto.supplierTicket,
      if (dto.attachmentUrls.isNotEmpty) 'attachment_urls': dto.attachmentUrls,
    };
  }

  Map<String, dynamic> _createAuditPayload(CreateAuditDto dto) {
    return {
      'audit_from_date': dto.auditFromDate.toIso8601String(),
      'audit_to_date': dto.auditToDate.toIso8601String(),
      'week_label': dto.weekLabel,
      if (dto.notes != null && dto.notes!.trim().isNotEmpty) 'notes': dto.notes,
    };
  }

  Map<String, dynamic> _createAuditItemPayload(CreateAuditItemDto dto) {
    return {
      'producto_id': dto.productoId,
      'expected_qty': dto.expectedQty,
      'counted_qty': dto.countedQty,
      if (dto.reason != null) 'reason': dto.reason!.name.toUpperCase(),
      if (dto.explanation != null && dto.explanation!.trim().isNotEmpty)
        'explanation': dto.explanation,
      'action_taken': dto.actionTaken.name.toUpperCase(),
    };
  }

  BaseOptions get _defaultOptions => BaseOptions(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  // === MAINTENANCE ===

  Future<MaintenanceRecord> createMaintenance(
    CreateMaintenanceDto dto, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/maintenance',
      data: _createMaintenancePayload(dto),
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return MaintenanceRecord.fromJson(response.data);
  }

  Future<MaintenanceListResponse> listMaintenance({
    String? search,
    ProductHealthStatus? status,
    String? productoId,
    String? from,
    String? to,
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null) queryParams['search'] = search;
    if (status != null) queryParams['status'] = _healthStatusToString(status);
    if (productoId != null) queryParams['producto_id'] = productoId;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final response = await dio.get(
      '/maintenance',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return MaintenanceListResponse.fromJson(response.data);
  }

  Future<MaintenanceRecord> getMaintenance(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get(
      '/maintenance/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return MaintenanceRecord.fromJson(response.data);
  }

  Future<MaintenanceRecord> updateMaintenance(
    String id,
    Map<String, dynamic> updates, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.put(
      '/maintenance/$id',
      data: updates,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return MaintenanceRecord.fromJson(response.data);
  }

  Future<void> deleteMaintenance(String id, {CancelToken? cancelToken}) async {
    await dio.delete(
      '/maintenance/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<MaintenanceSummary> getSummary({
    String? from,
    String? to,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final response = await dio.get(
      '/maintenance/summary',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return MaintenanceSummary.fromJson(response.data);
  }

  // === WARRANTY ===

  Future<WarrantyCase> createWarranty(
    CreateWarrantyDto dto, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/warranty',
      data: _createWarrantyPayload(dto),
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return WarrantyCase.fromJson(response.data);
  }

  Future<WarrantyListResponse> listWarranty({
    String? search,
    WarrantyStatus? status,
    String? productoId,
    String? from,
    String? to,
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null) queryParams['search'] = search;
    if (status != null) queryParams['status'] = _warrantyStatusToString(status);
    if (productoId != null) queryParams['producto_id'] = productoId;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final response = await dio.get(
      '/warranty',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return WarrantyListResponse.fromJson(response.data);
  }

  Future<WarrantyCase> getWarranty(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get(
      '/warranty/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return WarrantyCase.fromJson(response.data);
  }

  Future<WarrantyCase> updateWarranty(
    String id,
    Map<String, dynamic> updates, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.put(
      '/warranty/$id',
      data: updates,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return WarrantyCase.fromJson(response.data);
  }

  Future<void> deleteWarranty(String id, {CancelToken? cancelToken}) async {
    await dio.delete(
      '/warranty/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
  }

  // === INVENTORY AUDITS ===

  Future<InventoryAudit> createAudit(
    CreateAuditDto dto, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/inventory-audits',
      data: _createAuditPayload(dto),
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return InventoryAudit.fromJson(response.data);
  }

  Future<AuditListResponse> listAudits({
    String? from,
    String? to,
    AuditStatus? status,
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    if (status != null) queryParams['status'] = _auditStatusToString(status);

    final response = await dio.get(
      '/inventory-audits',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return AuditListResponse.fromJson(response.data);
  }

  Future<InventoryAudit> getAudit(String id, {CancelToken? cancelToken}) async {
    final response = await dio.get(
      '/inventory-audits/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return InventoryAudit.fromJson(response.data);
  }

  Future<InventoryAudit> updateAudit(
    String id,
    Map<String, dynamic> updates, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.put(
      '/inventory-audits/$id',
      data: updates,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return InventoryAudit.fromJson(response.data);
  }

  Future<AuditItemsResponse> getAuditItems(
    String auditId, {
    String? search,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null) queryParams['search'] = search;

    final response = await dio.get(
      '/inventory-audits/$auditId/items',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return AuditItemsResponse.fromJson(response.data);
  }

  Future<InventoryAuditItem> upsertAuditItem(
    String auditId,
    CreateAuditItemDto dto, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/inventory-audits/$auditId/items',
      data: _createAuditItemPayload(dto),
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
    return InventoryAuditItem.fromJson(response.data);
  }

  Future<void> deleteAuditItem(
    String auditId,
    String itemId, {
    CancelToken? cancelToken,
  }) async {
    await dio.delete(
      '/inventory-audits/$auditId/items/$itemId',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
        extra: _noOfflineQueueExtra,
      ),
      cancelToken: cancelToken,
    );
  }

  // Helper methods
  String _healthStatusToString(ProductHealthStatus status) {
    switch (status) {
      case ProductHealthStatus.okVerificado:
        return 'OK_VERIFICADO';
      case ProductHealthStatus.conProblema:
        return 'CON_PROBLEMA';
      case ProductHealthStatus.enGarantia:
        return 'EN_GARANTIA';
      case ProductHealthStatus.perdido:
        return 'PERDIDO';
      case ProductHealthStatus.danadoSinGarantia:
        return 'DANADO_SIN_GARANTIA';
      case ProductHealthStatus.reparado:
        return 'REPARADO';
      case ProductHealthStatus.enRevision:
        return 'EN_REVISION';
    }
  }

  String _warrantyStatusToString(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.abierto:
        return 'ABIERTO';
      case WarrantyStatus.enviado:
        return 'ENVIADO';
      case WarrantyStatus.enProceso:
        return 'EN_PROCESO';
      case WarrantyStatus.aprobado:
        return 'APROBADO';
      case WarrantyStatus.rechazado:
        return 'RECHAZADO';
      case WarrantyStatus.cerrado:
        return 'CERRADO';
    }
  }

  String _auditStatusToString(AuditStatus status) {
    switch (status) {
      case AuditStatus.borrador:
        return 'BORRADOR';
      case AuditStatus.finalizado:
        return 'FINALIZADO';
    }
  }
}
