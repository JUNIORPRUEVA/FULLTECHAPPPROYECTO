import { z } from 'zod';

// Keep compatibility with existing Flutter enums (IN/OUT/LUNCH_*)
// and also accept CHECK_IN/CHECK_OUT aliases.
export const attendanceTypeEnum = z.enum([
  'IN',
  'OUT',
  'LUNCH_START',
  'LUNCH_END',
  'CHECK_IN',
  'CHECK_OUT',
]);

export const syncStatusEnum = z.enum(['PENDING', 'SYNCED', 'FAILED']);

export const createAttendancePunchSchema = z
  .object({
    type: attendanceTypeEnum,

    // Accept both camelCase (Flutter) and snake_case (legacy) keys.
    datetimeUtc: z.string().datetime().optional(),
    datetime_utc: z.string().datetime().optional(),

    datetimeLocal: z.string().optional(),
    datetime_local: z.string().optional(),

    timezone: z.string().optional(),

    locationLat: z.number().min(-90).max(90).optional(),
    location_lat: z.number().min(-90).max(90).optional(),

    locationLng: z.number().min(-180).max(180).optional(),
    location_lng: z.number().min(-180).max(180).optional(),

    locationAccuracy: z.number().positive().optional(),
    location_accuracy: z.number().positive().optional(),

    locationProvider: z.string().optional(),
    location_provider: z.string().optional(),

    addressText: z.string().optional(),
    address_text: z.string().optional(),

    locationMissing: z.boolean().optional(),
    location_missing: z.boolean().optional(),

    deviceId: z.string().optional(),
    device_id: z.string().optional(),

    deviceName: z.string().optional(),
    device_name: z.string().optional(),

    platform: z.string().optional(),
    note: z.string().optional(),
    syncStatus: syncStatusEnum.optional(),
    sync_status: syncStatusEnum.optional(),
  })
  .refine((v) => v.datetimeUtc != null || v.datetime_utc != null, {
    message: 'datetimeUtc is required',
    path: ['datetimeUtc'],
  });

export const listAttendanceQuerySchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  date: z.string().optional(),
  userId: z.string().uuid().optional(),
  type: attendanceTypeEnum.optional(),
  limit: z.coerce.number().int().positive().max(500).optional().default(100),
  offset: z.coerce.number().int().min(0).optional().default(0),
});

export const updateAttendancePunchSchema = z.object({
  type: attendanceTypeEnum.optional(),

  datetimeUtc: z.string().datetime().optional(),
  datetime_utc: z.string().datetime().optional(),

  datetimeLocal: z.string().optional(),
  datetime_local: z.string().optional(),

  timezone: z.string().optional(),

  locationLat: z.number().min(-90).max(90).optional(),
  location_lat: z.number().min(-90).max(90).optional(),

  locationLng: z.number().min(-180).max(180).optional(),
  location_lng: z.number().min(-180).max(180).optional(),

  locationAccuracy: z.number().positive().optional(),
  location_accuracy: z.number().positive().optional(),

  locationProvider: z.string().optional(),
  location_provider: z.string().optional(),

  addressText: z.string().optional(),
  address_text: z.string().optional(),

  deviceId: z.string().optional(),
  device_id: z.string().optional(),

  deviceName: z.string().optional(),
  device_name: z.string().optional(),

  platform: z.string().optional(),
  note: z.string().optional(),
  isManualEdit: z.boolean().optional(),
  is_manual_edit: z.boolean().optional(),
  syncStatus: syncStatusEnum.optional(),
  sync_status: syncStatusEnum.optional(),
});
