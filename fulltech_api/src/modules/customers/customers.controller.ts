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

  const { search, tags, limit, offset, productId, status, dateFrom, dateTo } = parsed.data;

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
    where.tags = { hasEvery: tags };
  }

  // Filter by customers who have purchased a specific product
  if (productId) {
    where.sales = {
      some: {
        deleted_at: null,
        detalles: {
          path: ['items'],
          array_contains: [{ productId }],
        },
      },
    };
  }

  // Filter by date range (based on sales)
  if (dateFrom || dateTo) {
    const dateFilter: any = {};
    if (dateFrom) dateFilter.gte = new Date(dateFrom);
    if (dateTo) dateFilter.lte = new Date(dateTo);
    where.sales = {
      some: {
        deleted_at: null,
        created_at: dateFilter,
      },
    };
  }

  const [items, total] = await Promise.all([
    prisma.customer.findMany({
      where,
      orderBy: { updated_at: 'desc' },
      take: limit,
      skip: offset,
      include: {
        _count: {
          select: { sales: { where: { deleted_at: null } } },
        },
      },
    }),
    prisma.customer.count({ where }),
  ]);

  // Enrich with purchase summary
  const enriched = await Promise.all(
    items.map(async (c) => {
      const salesAgg = await prisma.sale.aggregate({
        where: { customer_id: c.id, deleted_at: null },
        _sum: { total: true },
        _max: { created_at: true },
      });

      const lastSale = await prisma.sale.findFirst({
        where: { customer_id: c.id, deleted_at: null },
        orderBy: { created_at: 'desc' },
        select: { detalles: true },
      });

      let topProduct = null;
      if (lastSale?.detalles && typeof lastSale.detalles === 'object') {
        const items = (lastSale.detalles as any)?.items || [];
        if (items.length > 0) {
          const first = items[0];
          topProduct = {
            id: first.productId || null,
            name: first.name || 'Producto',
            imageUrl: first.imageUrl || '',
            price: first.price || 0,
          };
        }
      }

      return {
        id: c.id,
        displayName: c.nombre,
        phone: c.telefono,
        waId: c.telefono,
        avatarUrl: null,
        status: status || 'activo',
        lastPurchaseAt: salesAgg._max.created_at?.toISOString() || null,
        totalPurchases: (c as any)._count.sales || 0,
        totalSpent: Number(salesAgg._sum.total || 0),
        topProduct,
      };
    })
  );

  res.json({ items: enriched, total, limit, offset });
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

  // Purchase summary
  const salesAgg = await prisma.sale.aggregate({
    where: { customer_id: id, deleted_at: null },
    _count: true,
    _sum: { total: true },
    _max: { created_at: true },
  });

  const summary = {
    totalPurchases: salesAgg._count || 0,
    totalSpent: Number(salesAgg._sum.total || 0),
    lastPurchaseAt: salesAgg._max.created_at?.toISOString() || null,
  };

  // Recent purchases
  const recentSales = await prisma.sale.findMany({
    where: { customer_id: id, deleted_at: null },
    orderBy: { created_at: 'desc' },
    take: 10,
  });

  const recentPurchases = recentSales.map((s) => {
    const items = (s.detalles as any)?.items || [];
    return {
      id: s.id,
      date: s.created_at.toISOString(),
      total: Number(s.total),
      status: 'completed',
      items: items.map((i: any) => ({
        productId: i.productId || null,
        name: i.name || 'Producto',
        qty: i.qty || 1,
        price: i.price || 0,
        imageUrl: i.imageUrl || '',
      })),
    };
  });

  // Top products (aggregate from sales)
  const topProducts: any[] = [];
  const productMap = new Map<string, { name: string; count: number; imageUrl: string }>();
  recentSales.forEach((s) => {
    const items = (s.detalles as any)?.items || [];
    items.forEach((i: any) => {
      const pid = i.productId || 'unknown';
      if (!productMap.has(pid)) {
        productMap.set(pid, { name: i.name || 'Producto', count: 0, imageUrl: i.imageUrl || '' });
      }
      const entry = productMap.get(pid)!;
      entry.count += i.qty || 1;
    });
  });
  productMap.forEach((v, k) => {
    topProducts.push({ productId: k, name: v.name, count: v.count, imageUrl: v.imageUrl });
  });
  topProducts.sort((a, b) => b.count - a.count);

  // Notes (stored in customer.notas as JSON or string; for now return empty array)
  const notes: any[] = [];

  res.json({
    id: customer.id,
    displayName: customer.nombre,
    phone: customer.telefono,
    waId: customer.telefono,
    avatarUrl: null,
    status: 'activo',
    summary,
    recentPurchases,
    topProducts: topProducts.slice(0, 5),
    notes,
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
export async function patchCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const id = req.params.id;

  const existing = await prisma.customer.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Customer not found');

  const allowed = ['status', 'assignedToUserId', 'tags', 'notas'];
  const patch: any = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      patch[key] = req.body[key];
    }
  }

  const updated = await prisma.customer.update({
    where: { id },
    data: {
      ...patch,
      sync_version: { increment: 1 },
    },
  });

  res.json({ item: updated });
}

export async function addCustomerNote(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const id = req.params.id;

  const customer = await prisma.customer.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!customer) throw new ApiError(404, 'Customer not found');

  const { text, followUpAt, priority } = req.body;
  if (!text || typeof text !== 'string') {
    throw new ApiError(400, 'text is required');
  }

  // For now, store notes in the customer.notas field as JSON array
  // In production, create a separate CustomerNote table
  const existingNotes = customer.notas ? JSON.parse(customer.notas) : [];
  const newNote = {
    id: `note_${Date.now()}`,
    text,
    followUpAt: followUpAt || null,
    priority: priority || 'normal',
    createdAt: new Date().toISOString(),
    createdBy: req.user?.userId || null,
  };
  existingNotes.unshift(newNote);

  await prisma.customer.update({
    where: { id },
    data: {
      notas: JSON.stringify(existingNotes),
      sync_version: { increment: 1 },
    },
  });

  res.status(201).json({ note: newNote });
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
