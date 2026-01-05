import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import {
  createPunchSchema,
  updatePunchSchema,
  listPunchesQuerySchema,
  type CreatePunchDto,
} from './punches.schema';

/**
 * POST /api/punches
 * Create a new punch record
 */
export async function createPunch(req: Request, res: Response) {
  try {
    const body = createPunchSchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    // Business rules validation
    const today = new Date().toISOString().split('T')[0];
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
    });

    // Get last punch of the day
    const lastPunch = todayPunches[0];

    // Validation rules
    if (body.type === 'OUT' && !lastPunch) {
      return res.status(400).json({
        error: 'No puedes registrar salida sin haber entrado',
      });
    }

    if (body.type === 'LUNCH_END') {
      const hasLunchStart = todayPunches.some((p) => p.type === 'LUNCH_START');
      if (!hasLunchStart) {
        return res.status(400).json({
          error: 'No puedes finalizar almuerzo sin haberlo iniciado',
        });
      }
    }

    // Prevent duplicate consecutive types
    if (lastPunch && lastPunch.type === body.type) {
      return res.status(400).json({
        error: `Ya registraste "${body.type}" recientemente`,
      });
    }

    // Create punch record
    const punch = await prisma.punchRecord.create({
      data: {
        empresa_id: empresaId,
        user_id: userId,
        type: body.type,
        datetime_utc: new Date(body.datetime_utc),
        datetime_local: body.datetime_local,
        timezone: body.timezone,
        location_lat: body.location_lat,
        location_lng: body.location_lng,
        location_accuracy: body.location_accuracy,
        location_provider: body.location_provider,
        address_text: body.address_text,
        location_missing: body.location_missing ?? false,
        device_id: body.device_id,
        device_name: body.device_name,
        platform: body.platform,
        note: body.note,
        sync_status: body.sync_status ?? 'SYNCED',
      },
      include: {
        user: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    res.status(201).json(punch);
  } catch (error: any) {
    console.error('[PUNCHES] Create error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear registro de ponchado' });
  }
}

/**
 * GET /api/punches
 * List punch records with filters
 */
export async function listPunches(req: Request, res: Response) {
  try {
    const query = listPunchesQuerySchema.parse(req.query);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = req.user!.role === 'admin' || req.user!.role === 'administrador';

    // Non-admin users can only see their own records
    const targetUserId = isAdmin && query.userId ? query.userId : userId;

    const where: any = {
      empresa_id: empresaId,
      user_id: targetUserId,
      deleted_at: null,
    };

    if (query.from || query.to) {
      where.datetime_utc = {};
      if (query.from) {
        where.datetime_utc.gte = new Date(query.from + 'T00:00:00Z');
      }
      if (query.to) {
        where.datetime_utc.lte = new Date(query.to + 'T23:59:59Z');
      }
    }

    if (query.type) {
      where.type = query.type;
    }

    const [punches, total] = await Promise.all([
      prisma.punchRecord.findMany({
        where,
        orderBy: { datetime_utc: 'desc' },
        take: query.limit,
        skip: query.offset,
        include: {
          user: {
            select: {
              id: true,
              nombre_completo: true,
              email: true,
            },
          },
        },
      }),
      prisma.punchRecord.count({ where }),
    ]);

    res.json({
      items: punches,
      total,
      limit: query.limit,
      offset: query.offset,
    });
  } catch (error: any) {
    console.error('[PUNCHES] List error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Query inválido', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar registros' });
  }
}

/**
 * GET /api/punches/:id
 * Get punch record detail
 */
export async function getPunch(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = req.user!.role === 'admin' || req.user!.role === 'administrador';

    const punch = await prisma.punchRecord.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
      include: {
        user: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    if (!punch) {
      return res.status(404).json({ error: 'Registro no encontrado' });
    }

    // Non-admin can only see their own
    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso' });
    }

    res.json(punch);
  } catch (error: any) {
    console.error('[PUNCHES] Get error:', error);
    res.status(500).json({ error: 'Error al obtener registro' });
  }
}

/**
 * PUT /api/punches/:id
 * Update punch record (admin or owner, marks as manual edit)
 */
export async function updatePunch(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = updatePunchSchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = req.user!.role === 'admin' || req.user!.role === 'administrador';

    const punch = await prisma.punchRecord.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!punch) {
      return res.status(404).json({ error: 'Registro no encontrado' });
    }

    // Only admin or owner can edit
    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso para editar' });
    }

    // Only admin can edit if not same day
    if (!isAdmin) {
      const punchDate = punch.datetime_utc.toISOString().split('T')[0];
      const today = new Date().toISOString().split('T')[0];
      if (punchDate !== today) {
        return res.status(403).json({
          error: 'Solo puedes editar registros del día actual',
        });
      }
    }

    // Require note for manual edits
    if (isAdmin && !body.note) {
      return res.status(400).json({
        error: 'Debes proporcionar una nota para la edición manual',
      });
    }

    const updated = await prisma.punchRecord.update({
      where: { id },
      data: {
        ...body,
        datetime_utc: body.datetime_utc ? new Date(body.datetime_utc) : undefined,
        is_manual_edit: true,
        updated_at: new Date(),
      },
      include: {
        user: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    res.json(updated);
  } catch (error: any) {
    console.error('[PUNCHES] Update error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al actualizar registro' });
  }
}

/**
 * DELETE /api/punches/:id
 * Soft delete punch record
 */
export async function deletePunch(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = req.user!.role === 'admin' || req.user!.role === 'administrador';

    const punch = await prisma.punchRecord.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!punch) {
      return res.status(404).json({ error: 'Registro no encontrado' });
    }

    // Only admin or owner can delete
    if (!isAdmin && punch.user_id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso para eliminar' });
    }

    // Only admin can delete if not same day
    if (!isAdmin) {
      const punchDate = punch.datetime_utc.toISOString().split('T')[0];
      const today = new Date().toISOString().split('T')[0];
      if (punchDate !== today) {
        return res.status(403).json({
          error: 'Solo puedes eliminar registros del día actual',
        });
      }
    }

    await prisma.punchRecord.update({
      where: { id },
      data: { deleted_at: new Date() },
    });

    res.status(204).send();
  } catch (error: any) {
    console.error('[PUNCHES] Delete error:', error);
    res.status(500).json({ error: 'Error al eliminar registro' });
  }
}

/**
 * GET /api/punches/summary
 * Get summary statistics
 */
export async function getPunchesSummary(req: Request, res: Response) {
  try {
    const query = listPunchesQuerySchema.parse(req.query);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;
    const isAdmin = req.user!.role === 'admin' || req.user!.role === 'administrador';

    const targetUserId = isAdmin && query.userId ? query.userId : userId;

    const where: any = {
      empresa_id: empresaId,
      user_id: targetUserId,
      deleted_at: null,
    };

    if (query.from || query.to) {
      where.datetime_utc = {};
      if (query.from) {
        where.datetime_utc.gte = new Date(query.from + 'T00:00:00Z');
      }
      if (query.to) {
        where.datetime_utc.lte = new Date(query.to + 'T23:59:59Z');
      }
    }

    const punches = await prisma.punchRecord.findMany({
      where,
      orderBy: { datetime_utc: 'asc' },
    });

    // Calculate statistics
    const daysWorked = new Set<string>();
    let totalHours = 0;
    let totalLunchHours = 0;

    const dayGroups = new Map<string, typeof punches>();
    punches.forEach((p) => {
      const day = p.datetime_utc.toISOString().split('T')[0];
      if (!dayGroups.has(day)) {
        dayGroups.set(day, []);
      }
      dayGroups.get(day)!.push(p);
    });

    dayGroups.forEach((dayPunches, day) => {
      daysWorked.add(day);

      const inPunch = dayPunches.find((p) => p.type === 'IN');
      const outPunch = dayPunches.find((p) => p.type === 'OUT');
      const lunchStart = dayPunches.find((p) => p.type === 'LUNCH_START');
      const lunchEnd = dayPunches.find((p) => p.type === 'LUNCH_END');

      if (inPunch && outPunch) {
        const hours =
          (outPunch.datetime_utc.getTime() - inPunch.datetime_utc.getTime()) / (1000 * 60 * 60);
        totalHours += hours;
      }

      if (lunchStart && lunchEnd) {
        const lunchHours =
          (lunchEnd.datetime_utc.getTime() - lunchStart.datetime_utc.getTime()) / (1000 * 60 * 60);
        totalLunchHours += lunchHours;
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
    console.error('[PUNCHES] Summary error:', error);
    res.status(500).json({ error: 'Error al calcular resumen' });
  }
}
