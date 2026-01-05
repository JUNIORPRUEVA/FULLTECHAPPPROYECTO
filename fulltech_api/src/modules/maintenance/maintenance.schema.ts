import { z } from 'zod';

// Enums
export const productHealthStatusEnum = z.enum([
  'OK_VERIFICADO',
  'CON_PROBLEMA',
  'EN_GARANTIA',
  'PERDIDO',
  'DANADO_SIN_GARANTIA',
  'REPARADO',
  'EN_REVISION',
]);

export const maintenanceTypeEnum = z.enum([
  'VERIFICACION',
  'LIMPIEZA',
  'DIAGNOSTICO',
  'REPARACION',
  'GARANTIA',
  'AJUSTE_INVENTARIO',
  'OTRO',
]);

export const issueCategoryEnum = z.enum([
  'ELECTRICO',
  'PANTALLA',
  'BATERIA',
  'ACCESORIOS',
  'SOFTWARE',
  'FISICO',
  'OTRO',
]);

export const warrantyStatusEnum = z.enum([
  'ABIERTO',
  'ENVIADO',
  'EN_PROCESO',
  'APROBADO',
  'RECHAZADO',
  'CERRADO',
]);

export const auditStatusEnum = z.enum(['BORRADOR', 'FINALIZADO']);

export const auditReasonEnum = z.enum([
  'VENTA_NO_REGISTRADA',
  'TRASLADO',
  'ERROR_CONTEO',
  'PERDIDA',
  'DANADO',
  'GARANTIA',
  'AJUSTE_MANUAL',
  'OTRO',
]);

export const auditActionEnum = z.enum(['AJUSTADO', 'REPORTADO', 'PENDIENTE', 'INVESTIGAR']);

// === MAINTENANCE SCHEMAS ===

export const createMaintenanceSchema = z.object({
  producto_id: z.string().uuid(),
  maintenance_type: maintenanceTypeEnum,
  status_before: productHealthStatusEnum.optional(),
  status_after: productHealthStatusEnum,
  issue_category: issueCategoryEnum.optional(),
  description: z.string().min(1),
  internal_notes: z.string().optional(),
  cost: z.number().positive().optional(),
  warranty_case_id: z.string().uuid().optional(),
  attachment_urls: z.array(z.string().url()).optional(),
});

export const updateMaintenanceSchema = z.object({
  maintenance_type: maintenanceTypeEnum.optional(),
  status_before: productHealthStatusEnum.optional(),
  status_after: productHealthStatusEnum.optional(),
  issue_category: issueCategoryEnum.optional(),
  description: z.string().min(1).optional(),
  internal_notes: z.string().optional(),
  cost: z.number().positive().optional(),
  warranty_case_id: z.string().uuid().optional(),
  attachment_urls: z.array(z.string().url()).optional(),
});

export const listMaintenanceQuerySchema = z.object({
  search: z.string().optional(),
  status: productHealthStatusEnum.optional(),
  producto_id: z.string().uuid().optional(),
  from: z.string().optional(), // ISO date
  to: z.string().optional(), // ISO date
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(200).default(50),
});

// === WARRANTY SCHEMAS ===

export const createWarrantySchema = z.object({
  producto_id: z.string().uuid(),
  problem_description: z.string().min(1),
  supplier_name: z.string().optional(),
  supplier_ticket: z.string().optional(),
  attachment_urls: z.array(z.string().url()).optional(),
});

export const updateWarrantySchema = z.object({
  warranty_status: warrantyStatusEnum.optional(),
  supplier_name: z.string().optional(),
  supplier_ticket: z.string().optional(),
  sent_date: z.string().datetime().optional(),
  received_date: z.string().datetime().optional(),
  problem_description: z.string().min(1).optional(),
  resolution_notes: z.string().optional(),
  attachment_urls: z.array(z.string().url()).optional(),
});

export const listWarrantyQuerySchema = z.object({
  search: z.string().optional(),
  status: warrantyStatusEnum.optional(),
  producto_id: z.string().uuid().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(200).default(50),
});

// === INVENTORY AUDIT SCHEMAS ===

export const createAuditSchema = z.object({
  audit_from_date: z.string().datetime(),
  audit_to_date: z.string().datetime(),
  week_label: z.string(),
  notes: z.string().optional(),
});

export const updateAuditSchema = z.object({
  audit_from_date: z.string().datetime().optional(),
  audit_to_date: z.string().datetime().optional(),
  week_label: z.string().optional(),
  notes: z.string().optional(),
  status: auditStatusEnum.optional(),
});

export const createAuditItemSchema = z.object({
  producto_id: z.string().uuid(),
  expected_qty: z.number().int(),
  counted_qty: z.number().int(),
  reason: auditReasonEnum.optional(),
  explanation: z.string().optional(),
  action_taken: auditActionEnum.default('PENDIENTE'),
});

export const listAuditQuerySchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  status: auditStatusEnum.optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(200).default(50),
});

// Type exports
export type CreateMaintenanceDto = z.infer<typeof createMaintenanceSchema>;
export type UpdateMaintenanceDto = z.infer<typeof updateMaintenanceSchema>;
export type ListMaintenanceQuery = z.infer<typeof listMaintenanceQuerySchema>;

export type CreateWarrantyDto = z.infer<typeof createWarrantySchema>;
export type UpdateWarrantyDto = z.infer<typeof updateWarrantySchema>;
export type ListWarrantyQuery = z.infer<typeof listWarrantyQuerySchema>;

export type CreateAuditDto = z.infer<typeof createAuditSchema>;
export type UpdateAuditDto = z.infer<typeof updateAuditSchema>;
export type CreateAuditItemDto = z.infer<typeof createAuditItemSchema>;
export type ListAuditQuery = z.infer<typeof listAuditQuerySchema>;
