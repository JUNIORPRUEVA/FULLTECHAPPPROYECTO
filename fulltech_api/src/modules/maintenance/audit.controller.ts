import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import {
  createAuditSchema,
  updateAuditSchema,
  createAuditItemSchema,
  listAuditQuerySchema,
} from './maintenance.schema';
import { mapInventoryAudit, mapInventoryAuditItem } from './maintenance.mappers';

/**
 * POST /api/inventory-audits
 * Create inventory audit
 */
export async function createAudit(req: Request, res: Response) {
  try {
    const body = createAuditSchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    const audit = await prisma.inventoryAudit.create({
      data: {
        empresa_id: empresaId,
        created_by_user_id: userId,
        audit_from_date: new Date(body.audit_from_date),
        audit_to_date: new Date(body.audit_to_date),
        week_label: body.week_label,
        notes: body.notes,
      },
      include: {
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    res.status(201).json(mapInventoryAudit(audit));
  } catch (error: any) {
    console.error('[AUDIT] Create error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear auditoría' });
  }
}

/**
 * GET /api/inventory-audits
 * List inventory audits
 */
export async function listAudits(req: Request, res: Response) {
  try {
    const query = listAuditQuerySchema.parse(req.query);
    const empresaId = req.user!.empresaId;

    const where: any = {
      empresa_id: empresaId,
    };

    if (query.from || query.to) {
      where.created_at = {};
      if (query.from) where.created_at.gte = new Date(query.from);
      if (query.to) where.created_at.lte = new Date(query.to);
    }

    if (query.status) {
      where.status = query.status;
    }

    const offset = (query.page - 1) * query.limit;

    const [items, total] = await Promise.all([
      prisma.inventoryAudit.findMany({
        where,
        orderBy: { created_at: 'desc' },
        take: query.limit,
        skip: offset,
        include: {
          created_by: {
            select: {
              id: true,
              nombre_completo: true,
            },
          },
          items: {
            select: {
              diff_qty: true,
            },
          },
        },
      }),
      prisma.inventoryAudit.count({ where }),
    ]);

    // Calculate total differences per audit
    const enrichedItems = items.map((audit) =>
      mapInventoryAudit({
        ...audit,
        totalDiferencias: audit.items.reduce(
          (sum, item) => sum + Math.abs(item.diff_qty),
          0,
        ),
        totalItems: audit.items.length,
      }),
    );

    res.json({
      items: enrichedItems,
      total,
      page: query.page,
      limit: query.limit,
      totalPages: Math.ceil(total / query.limit),
    });
  } catch (error: any) {
    console.error('[AUDIT] List error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Query inválido', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar auditorías' });
  }
}

/**
 * GET /api/inventory-audits/:id
 * Get audit detail
 */
export async function getAudit(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;

    const audit = await prisma.inventoryAudit.findFirst({
      where: {
        id,
        empresa_id: empresaId,
      },
      include: {
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    if (!audit) {
      return res.status(404).json({ error: 'Auditoría no encontrada' });
    }

    res.json(mapInventoryAudit(audit));
  } catch (error: any) {
    console.error('[AUDIT] Get error:', error);
    res.status(500).json({ error: 'Error al obtener auditoría' });
  }
}

/**
 * PUT /api/inventory-audits/:id
 * Update audit
 */
export async function updateAudit(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = updateAuditSchema.parse(req.body);
    const empresaId = req.user!.empresaId;

    const existing = await prisma.inventoryAudit.findFirst({
      where: {
        id,
        empresa_id: empresaId,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Auditoría no encontrada' });
    }

    // Prevent editing if finalized (unless admin)
    const isAdmin =
      req.user!.role === 'admin' || req.user!.role === 'administrador';
    
    if (existing.status === 'FINALIZADO' && !isAdmin) {
      return res.status(403).json({ error: 'No puedes editar auditorías finalizadas' });
    }

    const updateData: any = {
      ...body,
      updated_at: new Date(),
    };

    if (body.audit_from_date) {
      updateData.audit_from_date = new Date(body.audit_from_date);
    }

    if (body.audit_to_date) {
      updateData.audit_to_date = new Date(body.audit_to_date);
    }

    const updated = await prisma.inventoryAudit.update({
      where: { id },
      data: updateData,
      include: {
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
          },
        },
      },
    });

    res.json(mapInventoryAudit(updated));
  } catch (error: any) {
    console.error('[AUDIT] Update error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al actualizar auditoría' });
  }
}

/**
 * GET /api/inventory-audits/:id/items
 * Get audit items
 */
export async function getAuditItems(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;
    const { search } = req.query;

    // Verify audit exists and belongs to empresa
    const audit = await prisma.inventoryAudit.findFirst({
      where: {
        id,
        empresa_id: empresaId,
      },
    });

    if (!audit) {
      return res.status(404).json({ error: 'Auditoría no encontrada' });
    }

    const where: any = {
      audit_id: id,
    };

    if (search) {
      where.producto = {
        nombre: { contains: search as string, mode: 'insensitive' },
      };
    }

    const items = await prisma.inventoryAuditItem.findMany({
      where,
      include: {
        producto: {
          select: {
            id: true,
            nombre: true,
            imagen_url: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    res.json({ items: items.map(mapInventoryAuditItem) });
  } catch (error: any) {
    console.error('[AUDIT] Get items error:', error);
    res.status(500).json({ error: 'Error al obtener items de auditoría' });
  }
}

/**
 * POST /api/inventory-audits/:id/items
 * Add/update audit item
 */
export async function upsertAuditItem(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = createAuditItemSchema.parse(req.body);
    const empresaId = req.user!.empresaId;

    // Verify audit exists and belongs to empresa
    const audit = await prisma.inventoryAudit.findFirst({
      where: {
        id,
        empresa_id: empresaId,
      },
    });

    if (!audit) {
      return res.status(404).json({ error: 'Auditoría no encontrada' });
    }

    // Prevent editing if finalized (unless admin)
    const isAdmin =
      req.user!.role === 'admin' || req.user!.role === 'administrador';
    
    if (audit.status === 'FINALIZADO' && !isAdmin) {
      return res.status(403).json({ error: 'No puedes editar auditorías finalizadas' });
    }

    // Calculate diff
    const diff_qty = body.counted_qty - body.expected_qty;

    // Check if item already exists
    const existing = await prisma.inventoryAuditItem.findFirst({
      where: {
        audit_id: id,
        producto_id: body.producto_id,
      },
    });

    let item;

    if (existing) {
      // Update
      item = await prisma.inventoryAuditItem.update({
        where: { id: existing.id },
        data: {
          expected_qty: body.expected_qty,
          counted_qty: body.counted_qty,
          diff_qty,
          reason: body.reason,
          explanation: body.explanation,
          action_taken: body.action_taken,
        },
        include: {
          producto: {
            select: {
              id: true,
              nombre: true,
              imagen_url: true,
            },
          },
        },
      });
    } else {
      // Create
      item = await prisma.inventoryAuditItem.create({
        data: {
          audit_id: id,
          producto_id: body.producto_id,
          expected_qty: body.expected_qty,
          counted_qty: body.counted_qty,
          diff_qty,
          reason: body.reason,
          explanation: body.explanation,
          action_taken: body.action_taken,
        },
        include: {
          producto: {
            select: {
              id: true,
              nombre: true,
              imagen_url: true,
            },
          },
        },
      });
    }

    res.json(mapInventoryAuditItem(item));
  } catch (error: any) {
    console.error('[AUDIT] Upsert item error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al guardar item de auditoría' });
  }
}

/**
 * DELETE /api/inventory-audits/:id/items/:itemId
 * Delete audit item
 */
export async function deleteAuditItem(req: Request, res: Response) {
  try {
    const { id, itemId } = req.params;
    const empresaId = req.user!.empresaId;

    // Verify audit exists
    const audit = await prisma.inventoryAudit.findFirst({
      where: {
        id,
        empresa_id: empresaId,
      },
    });

    if (!audit) {
      return res.status(404).json({ error: 'Auditoría no encontrada' });
    }

    // Prevent editing if finalized (unless admin)
    const isAdmin =
      req.user!.role === 'admin' || req.user!.role === 'administrador';
    
    if (audit.status === 'FINALIZADO' && !isAdmin) {
      return res.status(403).json({ error: 'No puedes editar auditorías finalizadas' });
    }

    const item = await prisma.inventoryAuditItem.findFirst({
      where: {
        id: itemId,
        audit_id: id,
      },
    });

    if (!item) {
      return res.status(404).json({ error: 'Item no encontrado' });
    }

    await prisma.inventoryAuditItem.delete({
      where: { id: itemId },
    });

    res.status(204).send();
  } catch (error: any) {
    console.error('[AUDIT] Delete item error:', error);
    res.status(500).json({ error: 'Error al eliminar item de auditoría' });
  }
}
