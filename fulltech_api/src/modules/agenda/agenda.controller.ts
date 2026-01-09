import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  createAgendaItemSchema,
  updateAgendaItemSchema,
  listAgendaItemsQuerySchema,
} from './agenda.schema';

/**
 * GET /api/operations/agenda
 * List agenda items with filters
 */
export async function listAgendaItems(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;

  const parsed = listAgendaItemsQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { type, technician_id, is_completed, from_date, to_date, limit, offset } = parsed.data;

  const defaultStatuses = ['SERVICIO_RESERVADO', 'SOLUCION_GARANTIA'] as const;
  const mappedStatus =
    type === 'SERVICIO_RESERVADO'
      ? 'SERVICIO_RESERVADO'
      : type === 'SOLUCION_GARANTIA'
        ? 'SOLUCION_GARANTIA'
        : type === 'RESERVA'
          ? 'RESERVA'
          : type === 'GARANTIA'
            ? 'EN_GARANTIA'
            : null;

  const where: any = {
    empresa_id,
    deleted_at: null,
    status: mappedStatus ? mappedStatus : { in: defaultStatuses as any },
  };

  if (technician_id) {
    where.OR = [
      { assigned_tech_id: technician_id },
      { technician_user_id: technician_id },
    ];
  }

  if (typeof is_completed === 'boolean') {
    where.completed_at = is_completed ? { not: null } : null;
  }

  if (from_date || to_date) {
    where.OR = where.OR ?? [];
    const dateWhere: any = {};
    if (from_date) dateWhere.gte = new Date(from_date);
    if (to_date) dateWhere.lte = new Date(to_date);
    where.OR.push({ scheduled_at: dateWhere });
    where.OR.push({ resolution_due_at: dateWhere });
  }

  try {
    const [items, total] = await Promise.all([
      prisma.operationsJob.findMany({
        where,
        orderBy: [
          { completed_at: 'asc' },
          { scheduled_at: 'asc' },
          { resolution_due_at: 'asc' },
          { created_at: 'desc' },
        ],
        take: limit,
        skip: offset,
        include: {
          service: true,
          product: true,
          technician: true,
          vendedor: true,
          chat: true,
        },
      }),
      prisma.operationsJob.count({ where }),
    ]);

    res.json({ items, total, limit, offset });
  } catch (e: any) {
    const code = e?.code ?? e?.meta?.code;
    const msg = e?.message ?? String(e);
    console.error('[Operations] agenda list failed', { code, msg });
    if (code === 'P2021' || code === 'P2022') {
      res.json({ items: [], total: 0, limit, offset });
      return;
    }

    const name = String(e?.name ?? '');
    const looksLikeValidation =
      name.includes('PrismaClientValidationError') ||
      msg.includes('Unknown arg') ||
      msg.includes('Unknown field') ||
      msg.includes('include');

    if (looksLikeValidation) {
      try {
        const [items, total] = await Promise.all([
          prisma.operationsJob.findMany({
            where,
            orderBy: [
              { completed_at: 'asc' },
              { scheduled_at: 'asc' },
              { resolution_due_at: 'asc' },
              { created_at: 'desc' },
            ],
            take: limit,
            skip: offset,
          }),
          prisma.operationsJob.count({ where }),
        ]);

        res.json({ items, total, limit, offset });
        return;
      } catch (fallbackErr: any) {
        const fCode = fallbackErr?.code ?? fallbackErr?.meta?.code;
        const fMsg = fallbackErr?.message ?? String(fallbackErr);
        console.error('[Operations] agenda fallback failed', { fCode, fMsg });
        res.json({ items: [], total: 0, limit, offset });
        return;
      }
    }
    throw e;
  }
}

/**
 * GET /api/operations/agenda/:id
 * Get a single agenda item
 */
export async function getAgendaItem(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const item = await prisma.agendaItem.findFirst({
    where: { id, empresa_id },
    include: {
      service: true,
      technician: {
        select: {
          id: true,
          nombre_completo: true,
          telefono: true,
          rol: true,
        },
      },
      thread: {
        select: {
          id: true,
          phone_number: true,
          display_name: true,
        },
      },
    },
  });

  if (!item) {
    throw new ApiError(404, 'Agenda item not found');
  }

  res.json({ item });
}

/**
 * POST /api/operations/agenda
 * Create a new agenda item
 */
export async function createAgendaItem(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;

  const parsed = createAgendaItemSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid agenda item data', parsed.error.flatten());
  }

  const data = parsed.data;

  const item = await prisma.agendaItem.create({
    data: {
      empresa_id,
      thread_id: data.thread_id || null,
      client_phone: data.client_phone || null,
      client_name: data.client_name || null,
      type: data.type,
      scheduled_at: data.scheduled_at ? new Date(data.scheduled_at) : null,
      service_id: data.service_id || null,
      service_name: data.service_name || null,
      product_name: data.product_name || null,
      technician_id: data.technician_id || null,
      technician_name: data.technician_name || null,
      note: data.note || null,
      details: data.details || null,
      serial_number: data.serial_number || null,
      warranty_months: data.warranty_months || null,
      warranty_time: data.warranty_time || null,
      is_completed: data.is_completed || false,
    },
    include: {
      service: true,
      technician: {
        select: {
          id: true,
          nombre_completo: true,
          telefono: true,
          rol: true,
        },
      },
    },
  });

  console.log(`[Agenda] Created ${data.type} item ${item.id}`);

  res.status(201).json({ item });
}

/**
 * PUT /api/operations/agenda/:id
 * Update an agenda item
 */
export async function updateAgendaItem(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.agendaItem.findFirst({
    where: { id, empresa_id },
  });

  if (!existing) {
    throw new ApiError(404, 'Agenda item not found');
  }

  const parsed = updateAgendaItemSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid agenda item data', parsed.error.flatten());
  }

  const data = parsed.data;

  const updateData: any = {};

  if (data.scheduled_at !== undefined) {
    updateData.scheduled_at = data.scheduled_at ? new Date(data.scheduled_at) : null;
  }
  if (data.service_id !== undefined) updateData.service_id = data.service_id;
  if (data.service_name !== undefined) updateData.service_name = data.service_name;
  if (data.product_name !== undefined) updateData.product_name = data.product_name;
  if (data.technician_id !== undefined) updateData.technician_id = data.technician_id;
  if (data.technician_name !== undefined) updateData.technician_name = data.technician_name;
  if (data.note !== undefined) updateData.note = data.note;
  if (data.details !== undefined) updateData.details = data.details;
  if (data.serial_number !== undefined) updateData.serial_number = data.serial_number;
  if (data.warranty_months !== undefined) updateData.warranty_months = data.warranty_months;
  if (data.warranty_time !== undefined) updateData.warranty_time = data.warranty_time;
  if (data.is_completed !== undefined) updateData.is_completed = data.is_completed;
  if (data.completed_at !== undefined) {
    updateData.completed_at = data.completed_at ? new Date(data.completed_at) : null;
  }

  const updated = await prisma.agendaItem.update({
    where: { id },
    data: updateData,
    include: {
      service: true,
      technician: {
        select: {
          id: true,
          nombre_completo: true,
          telefono: true,
          rol: true,
        },
      },
    },
  });

  console.log(`[Agenda] Updated ${updated.type} item ${id}`);

  res.json({ item: updated });
}

/**
 * DELETE /api/operations/agenda/:id
 * Delete an agenda item
 */
export async function deleteAgendaItem(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.agendaItem.findFirst({
    where: { id, empresa_id },
  });

  if (!existing) {
    throw new ApiError(404, 'Agenda item not found');
  }

  await prisma.agendaItem.delete({
    where: { id },
  });

  console.log(`[Agenda] Deleted ${existing.type} item ${id}`);

  res.json({ message: 'Agenda item deleted' });
}
