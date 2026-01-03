import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  customerCreateSchema,
  customerListQuerySchema,
  customerUpdateSchema,
} from './customers.schema';

function empresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

export async function listCustomers(req: Request, res: Response) {
  const empresa_id = empresaId(req);

  const parsed = customerListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { search, tags, limit, offset } = parsed.data;

  const where: any = {
    empresa_id,
    deleted_at: null,
  };

  if (search && search.trim().length > 0) {
    const q = search.trim();
    where.OR = [
      { nombre: { contains: q, mode: 'insensitive' } },
      { telefono: { contains: q, mode: 'insensitive' } },
    ];
  }

  if (tags && tags.length > 0) {
    // Postgres array contains
    where.tags = { hasEvery: tags };
  }

  const [items, total] = await Promise.all([
    prisma.customer.findMany({
      where,
      orderBy: { updated_at: 'desc' },
      take: limit,
      skip: offset,
    }),
    prisma.customer.count({ where }),
  ]);

  res.json({ items, total, limit, offset });
}

export async function getCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const id = req.params.id;

  const customer = await prisma.customer.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!customer) throw new ApiError(404, 'Customer not found');

  const threads = await prisma.crmThread.findMany({
    where: { empresa_id, deleted_at: null, customer_id: customer.id },
    orderBy: [{ pinned: 'desc' }, { last_message_at: 'desc' }],
  });

  // Placeholder for future (ventas/cotizaciones summary)
  res.json({
    item: customer,
    threads,
    resumen: {
      ventas: null,
      cotizaciones: null,
    },
  });
}

export async function createCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);

  const parsed = customerCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const data = parsed.data;

  // Enforce unique phone per empresa.
  const existing = await prisma.customer.findFirst({
    where: { empresa_id, telefono: data.telefono, deleted_at: null },
  });
  if (existing) {
    throw new ApiError(409, 'Ya existe un cliente con ese teléfono');
  }

  const created = await prisma.customer.create({
    data: {
      empresa_id,
      nombre: data.nombre,
      telefono: data.telefono,
      email: data.email ?? null,
      direccion: data.direccion ?? null,
      ubicacion_mapa: data.ubicacion_mapa ?? null,
      tags: data.tags ?? [],
      notas: data.notas ?? null,
      origen: data.origen ?? 'whatsapp',
    },
  });

  res.status(201).json({ item: created });
}

export async function updateCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const id = req.params.id;

  const parsed = customerUpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const existing = await prisma.customer.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Customer not found');

  // If phone changes, re-check uniqueness.
  if (parsed.data.telefono && parsed.data.telefono !== existing.telefono) {
    const other = await prisma.customer.findFirst({
      where: {
        empresa_id,
        telefono: parsed.data.telefono,
        deleted_at: null,
        NOT: { id },
      },
    });
    if (other) throw new ApiError(409, 'Ya existe un cliente con ese teléfono');
  }

  const updated = await prisma.customer.update({
    where: { id },
    data: {
      ...parsed.data,
      tags: parsed.data.tags ?? undefined,
      sync_version: { increment: 1 },
    },
  });

  res.json({ item: updated });
}

export async function deleteCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const id = req.params.id;

  const existing = await prisma.customer.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Customer not found');

  await prisma.customer.update({
    where: { id },
    data: {
      deleted_at: new Date(),
      sync_version: { increment: 1 },
    },
  });

  res.status(204).send();
}
