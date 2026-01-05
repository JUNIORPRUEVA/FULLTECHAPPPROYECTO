import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import {
  createMaintenanceSchema,
  updateMaintenanceSchema,
  listMaintenanceQuerySchema,
} from './maintenance.schema';
import {
  mapInventoryAudit,
  mapMaintenanceRecord,
  mapProductBasicInfo,
} from './maintenance.mappers';

/**
 * POST /api/maintenance
 * Create maintenance record
 */
export async function createMaintenance(req: Request, res: Response) {
  try {
    const body = createMaintenanceSchema.parse(req.body);
    const userId = req.user!.userId;
    const empresaId = req.user!.empresaId;

    const maintenance = await prisma.productMaintenance.create({
      data: {
        empresa_id: empresaId,
        producto_id: body.producto_id,
        created_by_user_id: userId,
        maintenance_type: body.maintenance_type,
        status_before: body.status_before,
        status_after: body.status_after,
        issue_category: body.issue_category,
        description: body.description,
        internal_notes: body.internal_notes,
        cost: body.cost,
        warranty_case_id: body.warranty_case_id,
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

    res.status(201).json(mapMaintenanceRecord(maintenance));
  } catch (error: any) {
    console.error('[MAINTENANCE] Create error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear mantenimiento' });
  }
}

/**
 * GET /api/maintenance
 * List maintenance records
 */
export async function listMaintenance(req: Request, res: Response) {
  try {
    const query = listMaintenanceQuerySchema.parse(req.query);
    const empresaId = req.user!.empresaId;

    const where: any = {
      empresa_id: empresaId,
      deleted_at: null,
    };

    if (query.search) {
      where.OR = [
        { description: { contains: query.search, mode: 'insensitive' } },
        { internal_notes: { contains: query.search, mode: 'insensitive' } },
        {
          producto: {
            nombre: { contains: query.search, mode: 'insensitive' },
          },
        },
      ];
    }

    if (query.status) {
      where.status_after = query.status;
    }

    if (query.producto_id) {
      where.producto_id = query.producto_id;
    }

    if (query.from || query.to) {
      where.created_at = {};
      if (query.from) {
        where.created_at.gte = new Date(query.from);
      }
      if (query.to) {
        where.created_at.lte = new Date(query.to);
      }
    }

    const offset = (query.page - 1) * query.limit;

    const [items, total] = await Promise.all([
      prisma.productMaintenance.findMany({
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
      prisma.productMaintenance.count({ where }),
    ]);

    res.json({
      items: items.map(mapMaintenanceRecord),
      total,
      page: query.page,
      limit: query.limit,
      totalPages: Math.ceil(total / query.limit),
    });
  } catch (error: any) {
    console.error('[MAINTENANCE] List error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Query inválido', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar mantenimientos' });
  }
}

/**
 * GET /api/maintenance/:id
 * Get maintenance detail
 */
export async function getMaintenance(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;

    const maintenance = await prisma.productMaintenance.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
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
        warranty_case: true,
      },
    });

    if (!maintenance) {
      return res.status(404).json({ error: 'Mantenimiento no encontrado' });
    }

    res.json(mapMaintenanceRecord(maintenance));
  } catch (error: any) {
    console.error('[MAINTENANCE] Get error:', error);
    res.status(500).json({ error: 'Error al obtener mantenimiento' });
  }
}

/**
 * PUT /api/maintenance/:id
 * Update maintenance
 */
export async function updateMaintenance(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const body = updateMaintenanceSchema.parse(req.body);
    const empresaId = req.user!.empresaId;

    const existing = await prisma.productMaintenance.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Mantenimiento no encontrado' });
    }

    const updated = await prisma.productMaintenance.update({
      where: { id },
      data: {
        ...body,
        updated_at: new Date(),
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

    res.json(mapMaintenanceRecord(updated));
  } catch (error: any) {
    console.error('[MAINTENANCE] Update error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al actualizar mantenimiento' });
  }
}

/**
 * DELETE /api/maintenance/:id
 * Soft delete maintenance
 */
export async function deleteMaintenance(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const empresaId = req.user!.empresaId;

    const existing = await prisma.productMaintenance.findFirst({
      where: {
        id,
        empresa_id: empresaId,
        deleted_at: null,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Mantenimiento no encontrado' });
    }

    await prisma.productMaintenance.update({
      where: { id },
      data: { deleted_at: new Date() },
    });

    res.status(204).send();
  } catch (error: any) {
    console.error('[MAINTENANCE] Delete error:', error);
    res.status(500).json({ error: 'Error al eliminar mantenimiento' });
  }
}

/**
 * GET /api/maintenance/summary
 * Get summary statistics
 */
export async function getMaintenanceSummary(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const { from, to } = req.query;

    const where: any = {
      empresa_id: empresaId,
      deleted_at: null,
    };

    if (from || to) {
      where.created_at = {};
      if (from) where.created_at.gte = new Date(from as string);
      if (to) where.created_at.lte = new Date(to as string);
    }

    const [maintenances, warranties, lastAudit] = await Promise.all([
      prisma.productMaintenance.findMany({
        where,
        select: {
          status_after: true,
          producto_id: true,
        },
      }),
      prisma.warrantyCase.count({
        where: {
          empresa_id: empresaId,
          warranty_status: { in: ['ABIERTO', 'ENVIADO', 'EN_PROCESO'] },
          deleted_at: null,
        },
      }),
      prisma.inventoryAudit.findFirst({
        where: { empresa_id: empresaId },
        orderBy: { created_at: 'desc' },
        include: {
          created_by: {
            select: {
              id: true,
              nombre_completo: true,
              email: true,
            },
          },
          items: {
            select: {
              diff_qty: true,
            },
          },
        },
      }),
    ]);

    const statusCounts = {
      OK_VERIFICADO: 0,
      CON_PROBLEMA: 0,
      EN_GARANTIA: 0,
      PERDIDO: 0,
      DANADO_SIN_GARANTIA: 0,
      REPARADO: 0,
      EN_REVISION: 0,
    };

    maintenances.forEach((m) => {
      if (m.status_after) {
        statusCounts[m.status_after]++;
      }
    });

    // Top products with issues
    const productIssues = new Map<string, number>();
    maintenances
      .filter((m) => m.status_after !== 'OK_VERIFICADO' && m.status_after !== 'REPARADO')
      .forEach((m) => {
        productIssues.set(m.producto_id, (productIssues.get(m.producto_id) || 0) + 1);
      });

    const topProductIds = Array.from(productIssues.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map((e) => e[0]);

    const topProducts = await prisma.producto.findMany({
      where: {
        id: { in: topProductIds },
      },
      select: {
        id: true,
        nombre: true,
        imagen_url: true,
      },
    });

    const ultimoAuditDto =
      lastAudit == null
        ? null
        : mapInventoryAudit({
            ...lastAudit,
            totalDiferencias: lastAudit.items.reduce(
              (sum: number, item: any) => sum + Math.abs(item.diff_qty),
              0,
            ),
            totalItems: lastAudit.items.length,
          });

    res.json({
      totalProductosConProblema: statusCounts.CON_PROBLEMA,
      totalEnGarantia: statusCounts.EN_GARANTIA,
      totalPerdidos: statusCounts.PERDIDO,
      totalDanadoSinGarantia: statusCounts.DANADO_SIN_GARANTIA,
      totalVerificados: statusCounts.OK_VERIFICADO,
      totalReparados: statusCounts.REPARADO,
      totalEnRevision: statusCounts.EN_REVISION,
      garantiasAbiertas: warranties,
      ultimoAudit: ultimoAuditDto,
      topProductosConIncidencias: topProducts.map((p) => ({
        ...mapProductBasicInfo(p),
        incidencias: productIssues.get(p.id) || 0,
      })),
    });
  } catch (error: any) {
    console.error('[MAINTENANCE] Summary error:', error);
    res.status(500).json({ error: 'Error al obtener resumen' });
  }
}
