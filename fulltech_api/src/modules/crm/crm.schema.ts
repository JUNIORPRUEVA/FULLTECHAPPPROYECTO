import { z } from 'zod';

export const crmThreadCreateSchema = z.object({
  phone_number: z.string().min(5).max(50),
  display_name: z.string().max(200).optional().nullable(),
  canal: z.string().max(50).optional(),
});

export const crmThreadPatchSchema = z.object({
  estado_crm: z
    .enum([
      'pendiente',
      'interesado',
      'cotizado',
      'seguimiento',
      'compro',
      'perdido',
      'archivado',
    ])
    .optional(),
  assigned_user_id: z.string().uuid().optional().nullable(),
  pinned: z.boolean().optional(),
  primary_interest: z.string().max(200).optional().nullable(),
});

export const crmThreadsListQuerySchema = z.object({
  estado: z.string().max(50).optional(),
  assigned_user_id: z.string().uuid().optional(),
  search: z.string().max(200).optional(),
  pinned: z
    .union([z.string(), z.boolean()])
    .optional()
    .transform((v) => {
      if (typeof v === 'boolean') return v;
      if (typeof v !== 'string') return undefined;
      if (v === 'true') return true;
      if (v === 'false') return false;
      return undefined;
    }),
  limit: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 50))
    .refine((n) => Number.isFinite(n) && n > 0 && n <= 200, 'Invalid limit'),
  offset: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 0))
    .refine((n) => Number.isFinite(n) && n >= 0 && n <= 100000, 'Invalid offset'),
});

export const crmMessageListQuerySchema = z.object({
  limit: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 50))
    .refine((n) => Number.isFinite(n) && n > 0 && n <= 200, 'Invalid limit'),
  before: z.string().optional(),
});

export const crmMessageCreateSchema = z.object({
  from_me: z.boolean().optional().default(true),
  type: z.enum(['text', 'image', 'audio', 'video', 'document']).optional().default('text'),
  body: z.string().max(4000).optional().nullable(),
  media_url: z.string().max(1000).optional().nullable(),
  message_id: z.string().max(200).optional().nullable(),
});

export const crmSendMessageSchema = z.object({
  type: z.enum(['text', 'image', 'audio', 'video', 'document']).optional().default('text'),
  message: z.string().max(4000).optional().nullable(),
  media_url: z.string().max(1000).optional().nullable(),
});

export const crmTaskCreateSchema = z.object({
  tipo: z.enum(['whatsapp', 'llamada', 'visita']),
  fecha_hora: z.string().datetime(),
  status: z.enum(['pendiente', 'hecho', 'cancelado']).optional().default('pendiente'),
  nota: z.string().max(2000).optional().nullable(),
  assigned_user_id: z.string().uuid(),
});

export const crmTaskPatchSchema = z.object({
  tipo: z.enum(['whatsapp', 'llamada', 'visita']).optional(),
  fecha_hora: z.string().datetime().optional(),
  status: z.enum(['pendiente', 'hecho', 'cancelado']).optional(),
  nota: z.string().max(2000).optional().nullable(),
  assigned_user_id: z.string().uuid().optional(),
});

export const crmTasksListQuerySchema = z.object({
  assigned_user_id: z.string().uuid().optional(),
  status: z.string().max(50).optional(),
  date_from: z.string().datetime().optional(),
  date_to: z.string().datetime().optional(),
  limit: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 200))
    .refine((n) => Number.isFinite(n) && n > 0 && n <= 500, 'Invalid limit'),
});
