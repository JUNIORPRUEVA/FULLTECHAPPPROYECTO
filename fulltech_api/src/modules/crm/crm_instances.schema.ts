import { z } from 'zod';

// ======================================
// CRM Instance Schemas
// ======================================

export const crmInstanceCreateSchema = z.object({
  nombre_instancia: z.string().min(1).max(100),
  evolution_base_url: z.string().url(),
  evolution_api_key: z.string().min(1),
});

export const crmInstanceUpdateSchema = z.object({
  nombre_instancia: z.string().min(1).max(100).optional(),
  evolution_base_url: z.string().url().optional(),
  evolution_api_key: z.string().min(1).optional(),
  is_active: z.boolean().optional(),
});

export const crmInstanceTestConnectionSchema = z.object({
  evolution_base_url: z.string().url(),
  evolution_api_key: z.string().min(1),
  nombre_instancia: z.string().min(1).max(100),
});

// ======================================
// Chat Transfer Schema
// ======================================

export const crmChatTransferSchema = z.object({
  toUserId: z.string().uuid(),
  toInstanceId: z.string().uuid().optional(),
  notes: z.string().optional(),
});

export type CrmInstanceCreate = z.infer<typeof crmInstanceCreateSchema>;
export type CrmInstanceUpdate = z.infer<typeof crmInstanceUpdateSchema>;
export type CrmInstanceTestConnection = z.infer<typeof crmInstanceTestConnectionSchema>;
export type CrmChatTransfer = z.infer<typeof crmChatTransferSchema>;
