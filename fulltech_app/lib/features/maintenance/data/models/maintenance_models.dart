import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_models.freezed.dart';
part 'maintenance_models.g.dart';

// Enums
enum ProductHealthStatus {
  @JsonValue('OK_VERIFICADO')
  okVerificado,
  @JsonValue('CON_PROBLEMA')
  conProblema,
  @JsonValue('EN_GARANTIA')
  enGarantia,
  @JsonValue('PERDIDO')
  perdido,
  @JsonValue('DANADO_SIN_GARANTIA')
  danadoSinGarantia,
  @JsonValue('REPARADO')
  reparado,
  @JsonValue('EN_REVISION')
  enRevision,
}

enum MaintenanceType {
  @JsonValue('VERIFICACION')
  verificacion,
  @JsonValue('LIMPIEZA')
  limpieza,
  @JsonValue('DIAGNOSTICO')
  diagnostico,
  @JsonValue('REPARACION')
  reparacion,
  @JsonValue('GARANTIA')
  garantia,
  @JsonValue('AJUSTE_INVENTARIO')
  ajusteInventario,
  @JsonValue('OTRO')
  otro,
}

enum IssueCategory {
  @JsonValue('ELECTRICO')
  electrico,
  @JsonValue('PANTALLA')
  pantalla,
  @JsonValue('BATERIA')
  bateria,
  @JsonValue('ACCESORIOS')
  accesorios,
  @JsonValue('SOFTWARE')
  software,
  @JsonValue('FISICO')
  fisico,
  @JsonValue('OTRO')
  otro,
}

enum WarrantyStatus {
  @JsonValue('ABIERTO')
  abierto,
  @JsonValue('ENVIADO')
  enviado,
  @JsonValue('EN_PROCESO')
  enProceso,
  @JsonValue('APROBADO')
  aprobado,
  @JsonValue('RECHAZADO')
  rechazado,
  @JsonValue('CERRADO')
  cerrado,
}

enum AuditStatus {
  @JsonValue('BORRADOR')
  borrador,
  @JsonValue('FINALIZADO')
  finalizado,
}

enum AuditReason {
  @JsonValue('VENTA_NO_REGISTRADA')
  ventaNoRegistrada,
  @JsonValue('TRASLADO')
  traslado,
  @JsonValue('ERROR_CONTEO')
  errorConteo,
  @JsonValue('PERDIDA')
  perdida,
  @JsonValue('DANADO')
  danado,
  @JsonValue('GARANTIA')
  garantia,
  @JsonValue('AJUSTE_MANUAL')
  ajusteManual,
  @JsonValue('OTRO')
  otro,
}

enum AuditAction {
  @JsonValue('AJUSTADO')
  ajustado,
  @JsonValue('REPORTADO')
  reportado,
  @JsonValue('PENDIENTE')
  pendiente,
  @JsonValue('INVESTIGAR')
  investigar,
}

// Product basic info
@freezed
class ProductBasicInfo with _$ProductBasicInfo {
  const factory ProductBasicInfo({
    required String id,
    required String nombre,
    String? imagenUrl,
    double? precioVenta,
  }) = _ProductBasicInfo;

  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) =>
      _$ProductBasicInfoFromJson(json);
}

// User basic info
@freezed
class UserBasicInfo with _$UserBasicInfo {
  const factory UserBasicInfo({
    required String id,
    required String nombreCompleto,
    String? email,
  }) = _UserBasicInfo;

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) =>
      _$UserBasicInfoFromJson(json);
}

// Maintenance Record
@freezed
class MaintenanceRecord with _$MaintenanceRecord {
  const factory MaintenanceRecord({
    required String id,
    required String empresaId,
    required String productoId,
    required String createdByUserId,
    required MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    required ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    required String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    @Default([]) List<String> attachmentUrls,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  }) = _MaintenanceRecord;

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRecordFromJson(json);
}

// Warranty Case
@freezed
class WarrantyCase with _$WarrantyCase {
  const factory WarrantyCase({
    required String id,
    required String empresaId,
    required String productoId,
    required String createdByUserId,
    required WarrantyStatus warrantyStatus,
    String? supplierName,
    String? supplierTicket,
    DateTime? sentDate,
    DateTime? receivedDate,
    DateTime? closedAt,
    required String problemDescription,
    String? resolutionNotes,
    @Default([]) List<String> attachmentUrls,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    ProductBasicInfo? producto,
    UserBasicInfo? createdBy,
  }) = _WarrantyCase;

  factory WarrantyCase.fromJson(Map<String, dynamic> json) =>
      _$WarrantyCaseFromJson(json);
}

// Inventory Audit
@freezed
class InventoryAudit with _$InventoryAudit {
  const factory InventoryAudit({
    required String id,
    required String empresaId,
    required String createdByUserId,
    required DateTime auditFromDate,
    required DateTime auditToDate,
    required String weekLabel,
    String? notes,
    required AuditStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    UserBasicInfo? createdBy,
    int? totalItems,
    int? totalDiferencias,
  }) = _InventoryAudit;

  factory InventoryAudit.fromJson(Map<String, dynamic> json) =>
      _$InventoryAuditFromJson(json);
}

// Inventory Audit Item
@freezed
class InventoryAuditItem with _$InventoryAuditItem {
  const factory InventoryAuditItem({
    required String id,
    required String auditId,
    required String productoId,
    required int expectedQty,
    required int countedQty,
    required int diffQty,
    AuditReason? reason,
    String? explanation,
    required AuditAction actionTaken,
    required DateTime createdAt,
    ProductBasicInfo? producto,
  }) = _InventoryAuditItem;

  factory InventoryAuditItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryAuditItemFromJson(json);
}

// Maintenance Summary
@freezed
class MaintenanceSummary with _$MaintenanceSummary {
  const factory MaintenanceSummary({
    required int totalProductosConProblema,
    required int totalEnGarantia,
    required int totalPerdidos,
    required int totalDanadoSinGarantia,
    required int totalVerificados,
    required int totalReparados,
    required int totalEnRevision,
    required int garantiasAbiertas,
    InventoryAudit? ultimoAudit,
    @Default([]) List<ProductWithIncidents> topProductosConIncidencias,
  }) = _MaintenanceSummary;

  factory MaintenanceSummary.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceSummaryFromJson(json);
}

@freezed
class ProductWithIncidents with _$ProductWithIncidents {
  const factory ProductWithIncidents({
    required String id,
    required String nombre,
    String? imagenUrl,
    required int incidencias,
  }) = _ProductWithIncidents;

  factory ProductWithIncidents.fromJson(Map<String, dynamic> json) =>
      _$ProductWithIncidentsFromJson(json);
}

// Paginated responses
@freezed
class MaintenanceListResponse with _$MaintenanceListResponse {
  const factory MaintenanceListResponse({
    required List<MaintenanceRecord> items,
    required int total,
    required int page,
    required int limit,
    required int totalPages,
  }) = _MaintenanceListResponse;

  factory MaintenanceListResponse.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceListResponseFromJson(json);
}

@freezed
class WarrantyListResponse with _$WarrantyListResponse {
  const factory WarrantyListResponse({
    required List<WarrantyCase> items,
    required int total,
    required int page,
    required int limit,
    required int totalPages,
  }) = _WarrantyListResponse;

  factory WarrantyListResponse.fromJson(Map<String, dynamic> json) =>
      _$WarrantyListResponseFromJson(json);
}

@freezed
class AuditListResponse with _$AuditListResponse {
  const factory AuditListResponse({
    required List<InventoryAudit> items,
    required int total,
    required int page,
    required int limit,
    required int totalPages,
  }) = _AuditListResponse;

  factory AuditListResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditListResponseFromJson(json);
}

@freezed
class AuditItemsResponse with _$AuditItemsResponse {
  const factory AuditItemsResponse({
    required List<InventoryAuditItem> items,
  }) = _AuditItemsResponse;

  factory AuditItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditItemsResponseFromJson(json);
}

// DTOs for creation/update
@freezed
class CreateMaintenanceDto with _$CreateMaintenanceDto {
  const factory CreateMaintenanceDto({
    required String productoId,
    required MaintenanceType maintenanceType,
    ProductHealthStatus? statusBefore,
    required ProductHealthStatus statusAfter,
    IssueCategory? issueCategory,
    required String description,
    String? internalNotes,
    double? cost,
    String? warrantyCaseId,
    @Default([]) List<String> attachmentUrls,
  }) = _CreateMaintenanceDto;

  factory CreateMaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$CreateMaintenanceDtoFromJson(json);
}

@freezed
class CreateWarrantyDto with _$CreateWarrantyDto {
  const factory CreateWarrantyDto({
    required String productoId,
    required String problemDescription,
    String? supplierName,
    String? supplierTicket,
    @Default([]) List<String> attachmentUrls,
  }) = _CreateWarrantyDto;

  factory CreateWarrantyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateWarrantyDtoFromJson(json);
}

@freezed
class CreateAuditDto with _$CreateAuditDto {
  const factory CreateAuditDto({
    required DateTime auditFromDate,
    required DateTime auditToDate,
    required String weekLabel,
    String? notes,
  }) = _CreateAuditDto;

  factory CreateAuditDto.fromJson(Map<String, dynamic> json) =>
      _$CreateAuditDtoFromJson(json);
}

@freezed
class CreateAuditItemDto with _$CreateAuditItemDto {
  const factory CreateAuditItemDto({
    required String productoId,
    required int expectedQty,
    required int countedQty,
    AuditReason? reason,
    String? explanation,
    @Default(AuditAction.pendiente) AuditAction actionTaken,
  }) = _CreateAuditItemDto;

  factory CreateAuditItemDto.fromJson(Map<String, dynamic> json) =>
      _$CreateAuditItemDtoFromJson(json);
}
