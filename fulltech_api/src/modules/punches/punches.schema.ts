import { z } from 'zod';

export const punchTypeEnum = z.enum(['IN', 'LUNCH_START', 'LUNCH_END', 'OUT']);
export const syncStatusEnum = z.enum(['PENDING', 'SYNCED', 'FAILED']);

export const createPunchSchema = z.object({
  type: punchTypeEnum,
  datetime_utc: z.string().datetime(),
  datetime_local: z.string().optional(),
  timezone: z.string().optional(),
  location_lat: z.number().min(-90).max(90).optional(),
  location_lng: z.number().min(-180).max(180).optional(),
  location_accuracy: z.number().positive().optional(),
  location_provider: z.string().optional(),
  address_text: z.string().optional(),
  location_missing: z.boolean().optional(),
  device_id: z.string().optional(),
  device_name: z.string().optional(),
  platform: z.string().optional(),
  note: z.string().optional(),
  sync_status: syncStatusEnum.optional(),
});

export const updatePunchSchema = z.object({
  type: punchTypeEnum.optional(),
  datetime_utc: z.string().datetime().optional(),
  datetime_local: z.string().optional(),
  timezone: z.string().optional(),
  location_lat: z.number().min(-90).max(90).optional(),
  location_lng: z.number().min(-180).max(180).optional(),
  location_accuracy: z.number().positive().optional(),
  location_provider: z.string().optional(),
  address_text: z.string().optional(),
  device_id: z.string().optional(),
  device_name: z.string().optional(),
  platform: z.string().optional(),
  note: z.string().optional(),
  is_manual_edit: z.boolean().optional(),
  sync_status: syncStatusEnum.optional(),
});

export const listPunchesQuerySchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  userId: z.string().uuid().optional(),
  type: punchTypeEnum.optional(),
  limit: z.coerce.number().int().positive().max(500).optional().default(100),
  offset: z.coerce.number().int().min(0).optional().default(0),
});

export type CreatePunchDto = z.infer<typeof createPunchSchema>;
export type UpdatePunchDto = z.infer<typeof updatePunchSchema>;
export type ListPunchesQuery = z.infer<typeof listPunchesQuerySchema>;
