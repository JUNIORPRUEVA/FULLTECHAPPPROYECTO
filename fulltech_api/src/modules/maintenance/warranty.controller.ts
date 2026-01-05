import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import {
  createWarrantySchema,
  updateWarrantySchema,
  listWarrantyQuerySchema,
} from './maintenance.schema';
import { mapWarrantyCase } from './maintenance.mappers';

/**
 * GET /api/warranty/summary
 * Summary counts for warranty cases
 */
export async function getWarrantySummary(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const from = typeof req.query.from === 'string' ? req.query.from : undefined;
    const to = typeof req.query.to === 'string' ? req.query.to : undefined;

    const where: any = {
      empresa_id: empresaId,
      deleted_at: null,
    };

    if (from || to) {
      where.created_at = {};
      if (from) where.created_at.gte = new Date(from);
      if (to) where.created_at.lte = new Date(to);
    }

    const statuses = ['ABIERTO', 'ENVIADO', 'EN_PROCESO', 'APROBADO', 'RECHAZADO', 'CERRADO'] as const;

    const counts = await Promise.all(
      statuses.map(async (s) => {
        const count = await prisma.warrantyCase.count({
          where: {
            ...where,
            warranty_status: s,
          },
        });
        return [s, count] as const;
      }),
    );

    const total = counts.reduce((acc, [, c]) => acc + c, 0);
    const byStatus = Object.fromEntries(counts);

    res.json({
      total,
      byStatus,
    });
  } catch (error: any) {
    console.error('[WARRANTY] Summary error:', error);
    res.status(500).json({ error: 'Error al obtener resumen de garantías' });
  }
}

/**
 * POST /api/warranty
 * Create warranty case
 */
export async function createWarranty(req: Request, res: Response) {
  try {
    const body = createWarrantySchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    const warranty = await prisma.warrantyCase.create({
      data: {
        empresa_id: empresaId,
        producto_id: body.producto_id,
        created_by_user_id: userId,
        problem_description: body.problem_description,
        supplier_name: body.supplier_name,
        supplier_ticket: body.supplier_ticket,
        attachment_urls: body.attachment_urls || [],
      },
      include: {
        producto: {
          select: {
            id: true,
            nombre: true,
            imagen_url: true,
            precio_venta: true,
          },
        },
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    res.status(201).json(mapWarrantyCase(warranty));
  } catch (error: any) {
    console.error('[WARRANTY] Create error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear caso de garantía' });
  }
}

/**
 * GET /api/warranty
 * List warranty cases
 */
export async function listWarranty(req: Request, res: Response) {
  try {
    const query = listWarrantyQuerySchema.parse(req.query);
    const empresaId = req.user!.empresaId;

    const where: any = {
      empresa_id: empresaId,
      deleted_at: null,
    };

    if (query.search) {
      where.OR = [
        { problem_description: { contains: query.search, mode: 'insensitive' } },
        { supplier_name: { contains: query.search, mode: 'insensitive' } },
        { supplier_ticket: { contains: query.search, mode: 'insensitive' } },
        {
          producto: {
            nombre: { contains: query.search, mode: 'insensitive' },
          },
        },
      ];
    }

    if (query.status) {
      where.warranty_status = query.status;
    }

    if (query.producto_id) {
      where.producto_id = query.producto_id;
    }

    if (query.from || query.to) {
      where.created_at = {};
      if (query.from) where.created_at.gte = new Date(query.from);
      if (query.to) where.created_at.lte = new Date(query.to);
    }

    const offset = (query.page - 1) * query.limit;

    const [items, total] = await Promise.all([
      prisma.warrantyCase.findMany({
        where,
        orderBy: { created_at: 'desc' },
        take: query.limit,
        skip: offset,
        include: {
          producto: {
            select: {
              id: true,
              nombre: true,
              imagen_url: true,
              precio_venta: true,
            },
          },
          created_by: {
            select: {
              id: true,
              nombre_completo: true,
              email: true,
            },
          },
        },
      }),
      prisma.warrantyCase.count({ where }),
    ]);

    res.json({
      items: items.map(mapWarrantyCase),
      total,
      page: query.page,
      limit: query.limit,
      totalPages: Math.ceil(total / query.limit),
    });
  } catch (error: any) {
    console.error('[WARRANTY] List error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Query inválido', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar garantías' });
  }
}

/**
 * GET /api/warranty/:id
 * Get warranty detail
 */
export async function getWarranty(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;

    const warranty = await prisma.warrantyCase.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
      include: {
        producto: true,
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
        maintenances: {
          where: { deleted_at: null },
          orderBy: { created_at: 'desc' },
        },
      },
    });

    if (!warranty) {
      return res.status(404).json({ error: 'Caso de garantía no encontrado' });
    }

    res.json(mapWarrantyCase(warranty));
  } catch (error: any) {
    console.error('[WARRANTY] Get error:', error);
    res.status(500).json({ error: 'Error al obtener garantía' });
  }
}

/**
 * PUT /api/warranty/:id
 * Update warranty case
 */
export async function updateWarranty(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = updateWarrantySchema.parse(req.body);
    const empresaId = req.user!.empresaId;

    const existing = await prisma.warrantyCase.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Caso de garantía no encontrado' });
    }

    // Auto-set closed_at if status changes to CERRADO
    const updateData: any = {
      ...body,
      updated_at: new Date(),
    };

    if (body.warranty_status === 'CERRADO' && !existing.closed_at) {
      updateData.closed_at = new Date();
    }

    if (body.sent_date) {
      updateData.sent_date = new Date(body.sent_date);
    }

    if (body.received_date) {
      updateData.received_date = new Date(body.received_date);
    }

    const updated = await prisma.warrantyCase.update({
      where: { id },
      data: updateData,
      include: {
        producto: {
          select: {
            id: true,
            nombre: true,
            imagen_url: true,
            precio_venta: true,
          },
        },
        created_by: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
          },
        },
      },
    });

    res.json(mapWarrantyCase(updated));
  } catch (error: any) {
    console.error('[WARRANTY] Update error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al actualizar garantía' });
  }
}

/**
 * DELETE /api/warranty/:id
 * Soft delete warranty case
 */
export async function deleteWarranty(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;

    const existing = await prisma.warrantyCase.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Caso de garantía no encontrado' });
    }

    await prisma.warrantyCase.update({
      where: { id },
      data: { deleted_at: new Date() },
    });

    res.status(204).send();
  } catch (error: any) {
    console.error('[WARRANTY] Delete error:', error);
    res.status(500).json({ error: 'Error al eliminar garantía' });
  }
}
