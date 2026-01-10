import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { requireRole } from '../../middleware/requireRole';
import {
  createAttendancePunchSchema,
  listAttendanceQuerySchema,
  updateAttendancePunchSchema,
} from './attendance.schema';
import { ZodError } from 'zod';

function isAdminRole(role: string | undefined): boolean {
  return role === 'admin' || role === 'administrador';
}

function normalizeType(type: string): 'IN' | 'OUT' | 'LUNCH_START' | 'LUNCH_END' {
  if (type === 'CHECK_IN') return 'IN';
  if (type === 'CHECK_OUT') return 'OUT';
  if (type === 'IN' || type === 'OUT' || type === 'LUNCH_START' || type === 'LUNCH_END') return type;
  // Fallback to IN (should never happen due to zod enum)
  return 'IN';
}

function toPunchDto(p: any) {
  return {
    id: p.id,
    empresaId: p.empresa_id,
    userId: p.user_id,
    type: p.type,
    datetimeUtc: p.datetime_utc?.toISOString?.() ?? p.datetime_utc,
    datetimeLocal: p.datetime_local ?? '',
    timezone: p.timezone ?? 'UTC',
    locationLat: p.location_lat ?? null,
    locationLng: p.location_lng ?? null,
    locationAccuracy: p.location_accuracy ?? null,
    locationProvider: p.location_provider ?? null,
    addressText: p.address_text ?? null,
    locationMissing: p.location_missing ?? false,
    deviceId: p.device_id ?? null,
    deviceName: p.device_name ?? null,
    platform: p.platform ?? null,
    note: p.note ?? null,
    isManualEdit: p.is_manual_edit ?? false,
    syncStatus: p.sync_status ?? 'SYNCED',
    createdAt: p.created_at?.toISOString?.() ?? p.created_at,
    updatedAt: p.updated_at?.toISOString?.() ?? p.updated_at,
    deletedAt: p.deleted_at?.toISOString?.() ?? p.deleted_at ?? null,
    userName: p.user?.nombre_completo ?? null,
    userEmail: p.user?.email ?? null,
  };
}

/**
 * POST /api/attendance/punch
 */
export async function createPunch(req: Request, res: Response) {
  try {
    const body = createAttendancePunchSchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    const type = normalizeType(body.type);

    const datetimeUtcStr =
      (body as any).datetimeUtc ?? (body as any).datetime_utc ?? new Date().toISOString();
    const datetimeUtc = new Date(datetimeUtcStr);

    const businessRule = (code: string, message: string) => {
      console.info('[ATTENDANCE] BUSINESS_RULE', {
        code,
        userId: userId ? `…${String(userId).slice(-6)}` : null,
        type,
      });
      return res.status(400).json({ error: 'BUSINESS_RULE', code, message, retryable: false });
    };

    // Disallow Sunday punches (best-effort based on UTC).
    // Client also enforces this using local time.
    if (datetimeUtc.getUTCDay() === 0) {
      return businessRule('SUNDAY_NOT_ALLOWED', 'No se permite ponchar los domingos');
    }

    const today = datetimeUtc.toISOString().split('T')[0];
    const todayStart = new Date(today + 'T00:00:00Z');
    const todayEnd = new Date(today + 'T23:59:59Z');

    const todayPunches = await prisma.punchRecord.findMany({
      where: {
        user_id: userId,
        empresa_id: empresaId,
        datetime_utc: {
          gte: todayStart,
          lte: todayEnd,
        },
        deleted_at: null,
      },
      orderBy: { datetime_utc: 'desc' },
      include: {
        user: { select: { id: true, nombre_completo: true, email: true } },
      },
    });

    const has = (t: 'IN' | 'OUT' | 'LUNCH_START' | 'LUNCH_END') =>
      todayPunches.some((p) => p.type === t);

    // Strong per-day rules ("smart" and consistent)
    if (has('OUT')) {
      const out = todayPunches.find((p) => p.type === 'OUT');
      if (out) return res.status(200).json(toPunchDto(out));
      return businessRule('ALREADY_OUT', 'Ya registraste la salida hoy');
    }

    // Disallow repeating same type within the same day.
    if (has(type)) {
      const existing = todayPunches.find((p) => p.type === type);
      if (existing) return res.status(200).json(toPunchDto(existing));
      return businessRule('ALREADY_PUNCHED_TYPE', `Ya registraste "${type}" hoy`);
    }

    if (type === 'IN') {
      // Already covered by has(type) above.
    }

    if (type === 'LUNCH_START') {
      if (!has('IN')) {
        return businessRule('LUNCH_START_WITHOUT_IN', 'No puedes iniciar almuerzo sin haber entrado');
      }
      if (has('LUNCH_END')) {
        return businessRule(
          'LUNCH_START_AFTER_LUNCH_END',
          'No puedes iniciar almuerzo después de finalizarlo',
        );
        return res.status(400).json({ error: 'No puedes iniciar almuerzo después de finalizarlo' });
      }
    }

    if (type === 'LUNCH_END') {
      if (!has('LUNCH_START')) {
        return businessRule(
          'LUNCH_END_WITHOUT_LUNCH_START',
          'No puedes finalizar almuerzo sin haberlo iniciado',
        );
      }
    }

    if (type === 'OUT') {
      if (!has('IN')) {
        return businessRule('OUT_WITHOUT_IN', 'No puedes registrar salida sin haber entrado');
      }
      if (has('LUNCH_START') && !has('LUNCH_END')) {
        return businessRule(
          'OUT_WITHOUT_LUNCH_END',
          'No puedes registrar salida sin finalizar el almuerzo',
        );
      }
    }

    const punch = await prisma.punchRecord.create({
      data: {
        empresa_id: empresaId,
        user_id: userId,
        type,
        datetime_utc: datetimeUtc,
        datetime_local: (body as any).datetimeLocal ?? (body as any).datetime_local,
        timezone: body.timezone,
        location_lat: (body as any).locationLat ?? (body as any).location_lat,
        location_lng: (body as any).locationLng ?? (body as any).location_lng,
        location_accuracy: (body as any).locationAccuracy ?? (body as any).location_accuracy,
        location_provider: (body as any).locationProvider ?? (body as any).location_provider,
        address_text: (body as any).addressText ?? (body as any).address_text,
        location_missing: (body as any).locationMissing ?? (body as any).location_missing ?? false,
        device_id: (body as any).deviceId ?? (body as any).device_id,
        device_name: (body as any).deviceName ?? (body as any).device_name,
        platform: body.platform,
        note: body.note,
        sync_status: (body as any).syncStatus ?? (body as any).sync_status ?? 'SYNCED',
      },
      include: {
        user: {
          select: { id: true, nombre_completo: true, email: true },
        },
      },
    });

    return res.status(201).json(toPunchDto(punch));
  } catch (error: any) {
    if (error instanceof ZodError) {
      console.info('[ATTENDANCE] VALIDATION_ERROR', {
        issues: error.issues?.map((i) => ({ path: i.path, message: i.message })) ?? [],
      });
      return res.status(422).json({
        error: 'VALIDATION_ERROR',
        fields: error.flatten(),
      });
    }
    console.error('[ATTENDANCE] Create error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    return res.status(500).json({ error: 'Error al crear registro de asistencia' });
  }
}

/**
 * GET /api/attendance/records
 */
export async function listRecords(req: Request, res: Response) {
  try {
    const query = listAttendanceQuerySchema.parse(req.query);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    const isAdmin = isAdminRole(req.user!.role);
    const targetUserId = isAdmin && query.userId ? query.userId : userId;

    const where: any = {
      empresa_id: empresaId,
      user_id: targetUserId,
      deleted_at: null,
    };

    if (query.date) {
      where.datetime_utc = {
        gte: new Date(query.date + 'T00:00:00Z'),
        lte: new Date(query.date + 'T23:59:59Z'),
      };
    } else if (query.from || query.to) {
      where.datetime_utc = {};
      if (query.from) where.datetime_utc.gte = new Date(query.from + 'T00:00:00Z');
      if (query.to) where.datetime_utc.lte = new Date(query.to + 'T23:59:59Z');
    }

    if (query.type) {
      where.type = normalizeType(query.type);
    }

    const [rows, total] = await Promise.all([
      prisma.punchRecord.findMany({
        where,
        orderBy: { datetime_utc: 'desc' },
        take: query.limit,
        skip: query.offset,
        include: {
          user: {
            select: { id: true, nombre_completo: true, email: true },
          },
        },
      }),
      prisma.punchRecord.count({ where }),
    ]);

    res.json({
      items: rows.map(toPunchDto),
      total,
      limit: query.limit,
      offset: query.offset,
    });
  } catch (error: any) {
    console.error('[ATTENDANCE] List error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Query inválido', details: error.errors });
    }
    return res.status(500).json({ error: 'Error al listar registros de asistencia' });
  }
}

/**
 * GET /api/attendance/records/:id
 */
export async function getRecord(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = isAdminRole(req.user!.role);

    const punch = await prisma.punchRecord.findFirst({
      where: { id, empresa_id: empresaId, deleted_at: null },
      include: {
        user: { select: { id: true, nombre_completo: true, email: true } },
      },
    });

    if (!punch) return res.status(404).json({ error: 'Registro no encontrado' });
    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso' });
    }

    return res.json(toPunchDto(punch));
  } catch (error: any) {
    console.error('[ATTENDANCE] Get error:', error);
    return res.status(500).json({ error: 'Error al obtener registro' });
  }
}

/**
 * PUT /api/attendance/records/:id
 */
export async function updateRecord(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = updateAttendancePunchSchema.parse(req.body);

    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = isAdminRole(req.user!.role);

    const punch = await prisma.punchRecord.findFirst({
      where: { id, empresa_id: empresaId, deleted_at: null },
    });

    if (!punch) return res.status(404).json({ error: 'Registro no encontrado' });
    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso para editar' });
    }

    if (!isAdmin) {
      const punchDate = punch.datetime_utc.toISOString().split('T')[0];
      const today = new Date().toISOString().split('T')[0];
      if (punchDate !== today) {
        return res.status(403).json({ error: 'Solo puedes editar registros del día actual' });
      }
    }

    if (isAdmin && !(body.note ?? (body as any).note)?.trim()) {
      return res.status(400).json({ error: 'Nota requerida para ediciones manuales' });
    }

    const datetimeUtcStr = (body as any).datetimeUtc ?? (body as any).datetime_utc;

    const updated = await prisma.punchRecord.update({
      where: { id },
      data: {
        type: body.type ? normalizeType(body.type) : undefined,
        datetime_utc: datetimeUtcStr ? new Date(datetimeUtcStr) : undefined,
        datetime_local: (body as any).datetimeLocal ?? (body as any).datetime_local,
        timezone: body.timezone,
        location_lat: (body as any).locationLat ?? (body as any).location_lat,
        location_lng: (body as any).locationLng ?? (body as any).location_lng,
        location_accuracy: (body as any).locationAccuracy ?? (body as any).location_accuracy,
        location_provider: (body as any).locationProvider ?? (body as any).location_provider,
        address_text: (body as any).addressText ?? (body as any).address_text,
        device_id: (body as any).deviceId ?? (body as any).device_id,
        device_name: (body as any).deviceName ?? (body as any).device_name,
        platform: body.platform,
        note: body.note,
        is_manual_edit: (body as any).isManualEdit ?? (body as any).is_manual_edit ?? undefined,
        sync_status: (body as any).syncStatus ?? (body as any).sync_status ?? undefined,
      },
      include: {
        user: { select: { id: true, nombre_completo: true, email: true } },
      },
    });

    return res.json(toPunchDto(updated));
  } catch (error: any) {
    console.error('[ATTENDANCE] Update error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    return res.status(500).json({ error: 'Error al actualizar registro' });
  }
}

/**
 * DELETE /api/attendance/records/:id
 */
export async function deleteRecord(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = isAdminRole(req.user!.role);

    const punch = await prisma.punchRecord.findFirst({
      where: { id, empresa_id: empresaId, deleted_at: null },
    });

    if (!punch) return res.status(404).json({ error: 'Registro no encontrado' });

    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso para eliminar' });
    }

    if (!isAdmin) {
      const punchDate = punch.datetime_utc.toISOString().split('T')[0];
      const today = new Date().toISOString().split('T')[0];
      if (punchDate !== today) {
        return res.status(403).json({ error: 'Solo puedes eliminar registros del día actual' });
      }
    }

    await prisma.punchRecord.update({
      where: { id },
      data: { deleted_at: new Date() },
    });

    return res.status(204).send();
  } catch (error: any) {
    console.error('[ATTENDANCE] Delete error:', error);
    return res.status(500).json({ error: 'Error al eliminar registro' });
  }
}

/**
 * GET /api/attendance/summary
 * Compatible with /api/punches/summary response shape.
 */
export async function getSummary(req: Request, res: Response) {
  try {
    // Reuse query contract (from/to/userId/type/limit/offset) but ignore paging
    const query = listAttendanceQuerySchema.parse(req.query);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = isAdminRole(req.user!.role);

    const targetUserId = isAdmin && query.userId ? query.userId : userId;

    const where: any = {
      empresa_id: empresaId,
      user_id: targetUserId,
      deleted_at: null,
    };

    if (query.date) {
      where.datetime_utc = {
        gte: new Date(query.date + 'T00:00:00Z'),
        lte: new Date(query.date + 'T23:59:59Z'),
      };
    } else if (query.from || query.to) {
      where.datetime_utc = {};
      if (query.from) where.datetime_utc.gte = new Date(query.from + 'T00:00:00Z');
      if (query.to) where.datetime_utc.lte = new Date(query.to + 'T23:59:59Z');
    }

    const punches = await prisma.punchRecord.findMany({
      where,
      orderBy: { datetime_utc: 'asc' },
    });

    const daysWorked = new Set<string>();
    let totalHours = 0;
    let totalLunchHours = 0;

    const dayGroups = new Map<string, typeof punches>();
    punches.forEach((p) => {
      const day = p.datetime_utc.toISOString().split('T')[0];
      if (!dayGroups.has(day)) dayGroups.set(day, []);
      dayGroups.get(day)!.push(p);
    });

    dayGroups.forEach((dayPunches, day) => {
      daysWorked.add(day);

      const inPunch = dayPunches.find((p) => p.type === 'IN');
      const outPunch = dayPunches.find((p) => p.type === 'OUT');
      const lunchStart = dayPunches.find((p) => p.type === 'LUNCH_START');
      const lunchEnd = dayPunches.find((p) => p.type === 'LUNCH_END');

      if (inPunch && outPunch) {
        totalHours +=
          (outPunch.datetime_utc.getTime() - inPunch.datetime_utc.getTime()) / (1000 * 60 * 60);
      }

      if (lunchStart && lunchEnd) {
        totalLunchHours +=
          (lunchEnd.datetime_utc.getTime() - lunchStart.datetime_utc.getTime()) /
          (1000 * 60 * 60);
      }
    });

    res.json({
      daysWorked: daysWorked.size,
      totalPunches: punches.length,
      totalHours: Math.round(totalHours * 100) / 100,
      totalLunchHours: Math.round(totalLunchHours * 100) / 100,
      effectiveHours: Math.round((totalHours - totalLunchHours) * 100) / 100,
      byType: {
        IN: punches.filter((p) => p.type === 'IN').length,
        LUNCH_START: punches.filter((p) => p.type === 'LUNCH_START').length,
        LUNCH_END: punches.filter((p) => p.type === 'LUNCH_END').length,
        OUT: punches.filter((p) => p.type === 'OUT').length,
      },
    });
  } catch (error: any) {
    console.error('[ATTENDANCE] Summary error:', error);
    return res.status(500).json({ error: 'Error al calcular resumen' });
  }
}

/**
 * Admin-only listing endpoint (alias) to satisfy /api/attendance/admin/... requirement.
 * GET /api/attendance/admin/records
 */
export const adminListRecords = [requireRole(['admin', 'administrador']), listRecords] as any;
