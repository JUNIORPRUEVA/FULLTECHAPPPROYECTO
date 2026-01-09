import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  createServiceSchema,
  updateServiceSchema,
  listServicesQuerySchema,
} from './services.schema';

/**
 * GET /api/services
 * List services with filters
 */
export async function listServices(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;

  const parsed = listServicesQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { q, is_active, limit, offset } = parsed.data;

  const where: any = {
    empresa_id,
  };

  if (typeof is_active === 'boolean') {
    where.is_active = is_active;
  }

  if (q && q.trim().length > 0) {
    where.OR = [
      { name: { contains: q.trim(), mode: 'insensitive' } },
      { description: { contains: q.trim(), mode: 'insensitive' } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.service.findMany({
      where,
      orderBy: [{ is_active: 'desc' }, { name: 'asc' }],
      take: limit,
      skip: offset,
    }),
    prisma.service.count({ where }),
  ]);

  res.json({
    items,
    total,
    limit,
    offset,
  });
}

/**
 * GET /api/services/:id
 * Get a single service
 */
export async function getService(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const service = await prisma.service.findFirst({
    where: { id, empresa_id },
  });

  if (!service) {
    throw new ApiError(404, 'Service not found');
  }

  res.json({ item: service });
}

/**
 * POST /api/services
 * Create a new service
 */
export async function createService(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;

  const parsed = createServiceSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid service data', parsed.error.flatten());
  }

  const data = parsed.data;

  const service = await prisma.service.create({
    data: {
      empresa_id,
      name: data.name,
      description: data.description || null,
      default_price: data.default_price || null,
      is_active: data.is_active,
    },
  });

  console.log(`[Services] Created service ${service.id}: ${service.name}`);

  res.status(201).json({ item: service });
}

/**
 * PUT /api/services/:id
 * Update a service
 */
export async function updateService(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.service.findFirst({
    where: { id, empresa_id },
  });

  if (!existing) {
    throw new ApiError(404, 'Service not found');
  }

  const parsed = updateServiceSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid service data', parsed.error.flatten());
  }

  const data = parsed.data;

  const updated = await prisma.service.update({
    where: { id },
    data: {
      ...(data.name !== undefined && { name: data.name }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.default_price !== undefined && { default_price: data.default_price }),
      ...(data.is_active !== undefined && { is_active: data.is_active }),
    },
  });

  console.log(`[Services] Updated service ${id}: ${updated.name}`);

  res.json({ item: updated });
}

/**
 * DELETE /api/services/:id
 * Soft delete (deactivate) a service
 */
export async function deleteService(req: Request, res: Response) {
  const empresa_id = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.service.findFirst({
    where: { id, empresa_id },
  });

  if (!existing) {
    throw new ApiError(404, 'Service not found');
  }

  const updated = await prisma.service.update({
    where: { id },
    data: { is_active: false },
  });

  console.log(`[Services] Deactivated service ${id}: ${updated.name}`);

  res.json({ item: updated, message: 'Service deactivated' });
}
