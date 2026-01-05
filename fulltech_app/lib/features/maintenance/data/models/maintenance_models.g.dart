// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductBasicInfoImpl _$$ProductBasicInfoImplFromJson(
  Map<String, dynamic> json,
) => _$ProductBasicInfoImpl(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  imagenUrl: json['imagenUrl'] as String?,
  precioVenta: (json['precioVenta'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$ProductBasicInfoImplToJson(
  _$ProductBasicInfoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'imagenUrl': instance.imagenUrl,
  'precioVenta': instance.precioVenta,
};

_$UserBasicInfoImpl _$$UserBasicInfoImplFromJson(Map<String, dynamic> json) =>
    _$UserBasicInfoImpl(
      id: json['id'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$$UserBasicInfoImplToJson(_$UserBasicInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombreCompleto': instance.nombreCompleto,
      'email': instance.email,
    };

_$MaintenanceRecordImpl _$$MaintenanceRecordImplFromJson(
  Map<String, dynamic> json,
) => _$MaintenanceRecordImpl(
  id: json['id'] as String,
  empresaId: json['empresaId'] as String,
  productoId: json['productoId'] as String,
  createdByUserId: json['createdByUserId'] as String,
  maintenanceType: $enumDecode(
    _$MaintenanceTypeEnumMap,
    json['maintenanceType'],
  ),
  statusBefore: $enumDecodeNullable(
    _$ProductHealthStatusEnumMap,
    json['statusBefore'],
  ),
  statusAfter: $enumDecode(_$ProductHealthStatusEnumMap, json['statusAfter']),
  issueCategory: $enumDecodeNullable(
    _$IssueCategoryEnumMap,
    json['issueCategory'],
  ),
  description: json['description'] as String,
  internalNotes: json['internalNotes'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  warrantyCaseId: json['warrantyCaseId'] as String?,
  attachmentUrls:
      (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  producto: json['producto'] == null
      ? null
      : ProductBasicInfo.fromJson(json['producto'] as Map<String, dynamic>),
  createdBy: json['createdBy'] == null
      ? null
      : UserBasicInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$MaintenanceRecordImplToJson(
  _$MaintenanceRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'empresaId': instance.empresaId,
  'productoId': instance.productoId,
  'createdByUserId': instance.createdByUserId,
  'maintenanceType': _$MaintenanceTypeEnumMap[instance.maintenanceType]!,
  'statusBefore': _$ProductHealthStatusEnumMap[instance.statusBefore],
  'statusAfter': _$ProductHealthStatusEnumMap[instance.statusAfter]!,
  'issueCategory': _$IssueCategoryEnumMap[instance.issueCategory],
  'description': instance.description,
  'internalNotes': instance.internalNotes,
  'cost': instance.cost,
  'warrantyCaseId': instance.warrantyCaseId,
  'attachmentUrls': instance.attachmentUrls,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'producto': instance.producto,
  'createdBy': instance.createdBy,
};

const _$MaintenanceTypeEnumMap = {
  MaintenanceType.verificacion: 'VERIFICACION',
  MaintenanceType.limpieza: 'LIMPIEZA',
  MaintenanceType.diagnostico: 'DIAGNOSTICO',
  MaintenanceType.reparacion: 'REPARACION',
  MaintenanceType.garantia: 'GARANTIA',
  MaintenanceType.ajusteInventario: 'AJUSTE_INVENTARIO',
  MaintenanceType.otro: 'OTRO',
};

const _$ProductHealthStatusEnumMap = {
  ProductHealthStatus.okVerificado: 'OK_VERIFICADO',
  ProductHealthStatus.conProblema: 'CON_PROBLEMA',
  ProductHealthStatus.enGarantia: 'EN_GARANTIA',
  ProductHealthStatus.perdido: 'PERDIDO',
  ProductHealthStatus.danadoSinGarantia: 'DANADO_SIN_GARANTIA',
  ProductHealthStatus.reparado: 'REPARADO',
  ProductHealthStatus.enRevision: 'EN_REVISION',
};

const _$IssueCategoryEnumMap = {
  IssueCategory.electrico: 'ELECTRICO',
  IssueCategory.pantalla: 'PANTALLA',
  IssueCategory.bateria: 'BATERIA',
  IssueCategory.accesorios: 'ACCESORIOS',
  IssueCategory.software: 'SOFTWARE',
  IssueCategory.fisico: 'FISICO',
  IssueCategory.otro: 'OTRO',
};

_$WarrantyCaseImpl _$$WarrantyCaseImplFromJson(Map<String, dynamic> json) =>
    _$WarrantyCaseImpl(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      productoId: json['productoId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      warrantyStatus: $enumDecode(
        _$WarrantyStatusEnumMap,
        json['warrantyStatus'],
      ),
      supplierName: json['supplierName'] as String?,
      supplierTicket: json['supplierTicket'] as String?,
      sentDate: json['sentDate'] == null
          ? null
          : DateTime.parse(json['sentDate'] as String),
      receivedDate: json['receivedDate'] == null
          ? null
          : DateTime.parse(json['receivedDate'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      problemDescription: json['problemDescription'] as String,
      resolutionNotes: json['resolutionNotes'] as String?,
      attachmentUrls:
          (json['attachmentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      producto: json['producto'] == null
          ? null
          : ProductBasicInfo.fromJson(json['producto'] as Map<String, dynamic>),
      createdBy: json['createdBy'] == null
          ? null
          : UserBasicInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WarrantyCaseImplToJson(_$WarrantyCaseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'empresaId': instance.empresaId,
      'productoId': instance.productoId,
      'createdByUserId': instance.createdByUserId,
      'warrantyStatus': _$WarrantyStatusEnumMap[instance.warrantyStatus]!,
      'supplierName': instance.supplierName,
      'supplierTicket': instance.supplierTicket,
      'sentDate': instance.sentDate?.toIso8601String(),
      'receivedDate': instance.receivedDate?.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
      'problemDescription': instance.problemDescription,
      'resolutionNotes': instance.resolutionNotes,
      'attachmentUrls': instance.attachmentUrls,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'producto': instance.producto,
      'createdBy': instance.createdBy,
    };

const _$WarrantyStatusEnumMap = {
  WarrantyStatus.abierto: 'ABIERTO',
  WarrantyStatus.enviado: 'ENVIADO',
  WarrantyStatus.enProceso: 'EN_PROCESO',
  WarrantyStatus.aprobado: 'APROBADO',
  WarrantyStatus.rechazado: 'RECHAZADO',
  WarrantyStatus.cerrado: 'CERRADO',
};

_$InventoryAuditImpl _$$InventoryAuditImplFromJson(Map<String, dynamic> json) =>
    _$InventoryAuditImpl(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      auditFromDate: DateTime.parse(json['auditFromDate'] as String),
      auditToDate: DateTime.parse(json['auditToDate'] as String),
      weekLabel: json['weekLabel'] as String,
      notes: json['notes'] as String?,
      status: $enumDecode(_$AuditStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] == null
          ? null
          : UserBasicInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
      totalItems: (json['totalItems'] as num?)?.toInt(),
      totalDiferencias: (json['totalDiferencias'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$InventoryAuditImplToJson(
  _$InventoryAuditImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'empresaId': instance.empresaId,
  'createdByUserId': instance.createdByUserId,
  'auditFromDate': instance.auditFromDate.toIso8601String(),
  'auditToDate': instance.auditToDate.toIso8601String(),
  'weekLabel': instance.weekLabel,
  'notes': instance.notes,
  'status': _$AuditStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'createdBy': instance.createdBy,
  'totalItems': instance.totalItems,
  'totalDiferencias': instance.totalDiferencias,
};

const _$AuditStatusEnumMap = {
  AuditStatus.borrador: 'BORRADOR',
  AuditStatus.finalizado: 'FINALIZADO',
};

_$InventoryAuditItemImpl _$$InventoryAuditItemImplFromJson(
  Map<String, dynamic> json,
) => _$InventoryAuditItemImpl(
  id: json['id'] as String,
  auditId: json['auditId'] as String,
  productoId: json['productoId'] as String,
  expectedQty: (json['expectedQty'] as num).toInt(),
  countedQty: (json['countedQty'] as num).toInt(),
  diffQty: (json['diffQty'] as num).toInt(),
  reason: $enumDecodeNullable(_$AuditReasonEnumMap, json['reason']),
  explanation: json['explanation'] as String?,
  actionTaken: $enumDecode(_$AuditActionEnumMap, json['actionTaken']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  producto: json['producto'] == null
      ? null
      : ProductBasicInfo.fromJson(json['producto'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$InventoryAuditItemImplToJson(
  _$InventoryAuditItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'auditId': instance.auditId,
  'productoId': instance.productoId,
  'expectedQty': instance.expectedQty,
  'countedQty': instance.countedQty,
  'diffQty': instance.diffQty,
  'reason': _$AuditReasonEnumMap[instance.reason],
  'explanation': instance.explanation,
  'actionTaken': _$AuditActionEnumMap[instance.actionTaken]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'producto': instance.producto,
};

const _$AuditReasonEnumMap = {
  AuditReason.ventaNoRegistrada: 'VENTA_NO_REGISTRADA',
  AuditReason.traslado: 'TRASLADO',
  AuditReason.errorConteo: 'ERROR_CONTEO',
  AuditReason.perdida: 'PERDIDA',
  AuditReason.danado: 'DANADO',
  AuditReason.garantia: 'GARANTIA',
  AuditReason.ajusteManual: 'AJUSTE_MANUAL',
  AuditReason.otro: 'OTRO',
};

const _$AuditActionEnumMap = {
  AuditAction.ajustado: 'AJUSTADO',
  AuditAction.reportado: 'REPORTADO',
  AuditAction.pendiente: 'PENDIENTE',
  AuditAction.investigar: 'INVESTIGAR',
};

_$MaintenanceSummaryImpl _$$MaintenanceSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$MaintenanceSummaryImpl(
  totalProductosConProblema: (json['totalProductosConProblema'] as num).toInt(),
  totalEnGarantia: (json['totalEnGarantia'] as num).toInt(),
  totalPerdidos: (json['totalPerdidos'] as num).toInt(),
  totalDanadoSinGarantia: (json['totalDanadoSinGarantia'] as num).toInt(),
  totalVerificados: (json['totalVerificados'] as num).toInt(),
  totalReparados: (json['totalReparados'] as num).toInt(),
  totalEnRevision: (json['totalEnRevision'] as num).toInt(),
  garantiasAbiertas: (json['garantiasAbiertas'] as num).toInt(),
  ultimoAudit: json['ultimoAudit'] == null
      ? null
      : InventoryAudit.fromJson(json['ultimoAudit'] as Map<String, dynamic>),
  topProductosConIncidencias:
      (json['topProductosConIncidencias'] as List<dynamic>?)
          ?.map((e) => ProductWithIncidents.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$MaintenanceSummaryImplToJson(
  _$MaintenanceSummaryImpl instance,
) => <String, dynamic>{
  'totalProductosConProblema': instance.totalProductosConProblema,
  'totalEnGarantia': instance.totalEnGarantia,
  'totalPerdidos': instance.totalPerdidos,
  'totalDanadoSinGarantia': instance.totalDanadoSinGarantia,
  'totalVerificados': instance.totalVerificados,
  'totalReparados': instance.totalReparados,
  'totalEnRevision': instance.totalEnRevision,
  'garantiasAbiertas': instance.garantiasAbiertas,
  'ultimoAudit': instance.ultimoAudit,
  'topProductosConIncidencias': instance.topProductosConIncidencias,
};

_$ProductWithIncidentsImpl _$$ProductWithIncidentsImplFromJson(
  Map<String, dynamic> json,
) => _$ProductWithIncidentsImpl(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  imagenUrl: json['imagenUrl'] as String?,
  incidencias: (json['incidencias'] as num).toInt(),
);

Map<String, dynamic> _$$ProductWithIncidentsImplToJson(
  _$ProductWithIncidentsImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'imagenUrl': instance.imagenUrl,
  'incidencias': instance.incidencias,
};

_$MaintenanceListResponseImpl _$$MaintenanceListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$MaintenanceListResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$$MaintenanceListResponseImplToJson(
  _$MaintenanceListResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'totalPages': instance.totalPages,
};

_$WarrantyListResponseImpl _$$WarrantyListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$WarrantyListResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => WarrantyCase.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$$WarrantyListResponseImplToJson(
  _$WarrantyListResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'totalPages': instance.totalPages,
};

_$AuditListResponseImpl _$$AuditListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AuditListResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => InventoryAudit.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$$AuditListResponseImplToJson(
  _$AuditListResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'totalPages': instance.totalPages,
};

_$AuditItemsResponseImpl _$$AuditItemsResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AuditItemsResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => InventoryAuditItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$AuditItemsResponseImplToJson(
  _$AuditItemsResponseImpl instance,
) => <String, dynamic>{'items': instance.items};

_$CreateMaintenanceDtoImpl _$$CreateMaintenanceDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CreateMaintenanceDtoImpl(
  productoId: json['productoId'] as String,
  maintenanceType: $enumDecode(
    _$MaintenanceTypeEnumMap,
    json['maintenanceType'],
  ),
  statusBefore: $enumDecodeNullable(
    _$ProductHealthStatusEnumMap,
    json['statusBefore'],
  ),
  statusAfter: $enumDecode(_$ProductHealthStatusEnumMap, json['statusAfter']),
  issueCategory: $enumDecodeNullable(
    _$IssueCategoryEnumMap,
    json['issueCategory'],
  ),
  description: json['description'] as String,
  internalNotes: json['internalNotes'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  warrantyCaseId: json['warrantyCaseId'] as String?,
  attachmentUrls:
      (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CreateMaintenanceDtoImplToJson(
  _$CreateMaintenanceDtoImpl instance,
) => <String, dynamic>{
  'productoId': instance.productoId,
  'maintenanceType': _$MaintenanceTypeEnumMap[instance.maintenanceType]!,
  'statusBefore': _$ProductHealthStatusEnumMap[instance.statusBefore],
  'statusAfter': _$ProductHealthStatusEnumMap[instance.statusAfter]!,
  'issueCategory': _$IssueCategoryEnumMap[instance.issueCategory],
  'description': instance.description,
  'internalNotes': instance.internalNotes,
  'cost': instance.cost,
  'warrantyCaseId': instance.warrantyCaseId,
  'attachmentUrls': instance.attachmentUrls,
};

_$CreateWarrantyDtoImpl _$$CreateWarrantyDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CreateWarrantyDtoImpl(
  productoId: json['productoId'] as String,
  problemDescription: json['problemDescription'] as String,
  supplierName: json['supplierName'] as String?,
  supplierTicket: json['supplierTicket'] as String?,
  attachmentUrls:
      (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CreateWarrantyDtoImplToJson(
  _$CreateWarrantyDtoImpl instance,
) => <String, dynamic>{
  'productoId': instance.productoId,
  'problemDescription': instance.problemDescription,
  'supplierName': instance.supplierName,
  'supplierTicket': instance.supplierTicket,
  'attachmentUrls': instance.attachmentUrls,
};

_$CreateAuditDtoImpl _$$CreateAuditDtoImplFromJson(Map<String, dynamic> json) =>
    _$CreateAuditDtoImpl(
      auditFromDate: DateTime.parse(json['auditFromDate'] as String),
      auditToDate: DateTime.parse(json['auditToDate'] as String),
      weekLabel: json['weekLabel'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$CreateAuditDtoImplToJson(
  _$CreateAuditDtoImpl instance,
) => <String, dynamic>{
  'auditFromDate': instance.auditFromDate.toIso8601String(),
  'auditToDate': instance.auditToDate.toIso8601String(),
  'weekLabel': instance.weekLabel,
  'notes': instance.notes,
};

_$CreateAuditItemDtoImpl _$$CreateAuditItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CreateAuditItemDtoImpl(
  productoId: json['productoId'] as String,
  expectedQty: (json['expectedQty'] as num).toInt(),
  countedQty: (json['countedQty'] as num).toInt(),
  reason: $enumDecodeNullable(_$AuditReasonEnumMap, json['reason']),
  explanation: json['explanation'] as String?,
  actionTaken:
      $enumDecodeNullable(_$AuditActionEnumMap, json['actionTaken']) ??
      AuditAction.pendiente,
);

Map<String, dynamic> _$$CreateAuditItemDtoImplToJson(
  _$CreateAuditItemDtoImpl instance,
) => <String, dynamic>{
  'productoId': instance.productoId,
  'expectedQty': instance.expectedQty,
  'countedQty': instance.countedQty,
  'reason': _$AuditReasonEnumMap[instance.reason],
  'explanation': instance.explanation,
  'actionTaken': _$AuditActionEnumMap[instance.actionTaken]!,
};
