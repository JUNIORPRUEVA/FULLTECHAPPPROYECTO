import { z } from 'zod';

export const agendaItemTypeEnum = z.enum([
  'RESERVA',
  'SERVICIO_RESERVADO',
  'GARANTIA',
  'SOLUCION_GARANTIA',
]);

export const createAgendaItemSchema = z.object({
  thread_id: z.string().uuid().optional().nullable(),
  client_phone: z.string().optional().nullable(),
  client_name: z.string().optional().nullable(),
  type: agendaItemTypeEnum,
  scheduled_at: z.string().datetime().optional().nullable(),
  service_id: z.string().uuid().optional().nullable(),
  service_name: z.string().optional().nullable(),
  product_name: z.string().optional().nullable(),
  technician_id: z.string().uuid().optional().nullable(),
  technician_name: z.string().optional().nullable(),
  note: z.string().optional().nullable(),
  details: z.string().optional().nullable(),
  serial_number: z.string().optional().nullable(),
  warranty_months: z.number().int().optional().nullable(),
  warranty_time: z.string().optional().nullable(),
  is_completed: z.boolean().optional().default(false),
});

export const updateAgendaItemSchema = createAgendaItemSchema.partial().extend({
  completed_at: z.string().datetime().optional().nullable(),
});

export const listAgendaItemsQuerySchema = z.object({
  type: agendaItemTypeEnum.optional(),
  technician_id: z.string().uuid().optional(),
  is_completed: z
    .union([z.boolean(), z.string()])
    .transform((v) => (typeof v === 'string' ? v === 'true' : v))
    .optional(),
  from_date: z.string().optional(),
  to_date: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(100),
  offset: z.coerce.number().int().min(0).default(0),
});

export type CreateAgendaItemInput = z.infer<typeof createAgendaItemSchema>;
export type UpdateAgendaItemInput = z.infer<typeof updateAgendaItemSchema>;
export type ListAgendaItemsQuery = z.infer<typeof listAgendaItemsQuerySchema>;
