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

/**
 * GET /api/customers
 * Lista simplificada con stats globales
 */
export async function listCustomers(req: Request, res: Response) {
  const empresa_id = empresaId(req);

  const parsed = customerListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { q, search, status, limit, offset } = parsed.data;

  // Build where clause
  const where: any = {
    empresa_id,
    deleted_at: null,
  };

  // Unified search
  const searchTerm = q || search;
  if (searchTerm && searchTerm.trim().length > 0) {
    const term = searchTerm.trim();
    where.OR = [
      { nombre: { contains: term, mode: 'insensitive' } },
      { telefono: { contains: term, mode: 'insensitive' } },
      { notas: { contains: term, mode: 'insensitive' } },
    ];
  }

  // Filter by status tag
  if (status) {
    where.tags = { has: status };
  }

  // Fetch customers
  const [items, total] = await Promise.all([
    prisma.customer.findMany({
      where,
      orderBy: { updated_at: 'desc' },
      take: limit,
      skip: offset,
    }),
    prisma.customer.count({ where }),
  ]);

  // Transform to frontend format
  const enriched = items.map((c) => {
    const whatsappId = c.telefono ? `${c.telefono}@s.whatsapp.net` : null;
    const statusTag =
      c.tags.find((t: string) =>
        ['activo', 'interesado', 'reserva', 'compro', 'noInteresado'].includes(
          t.toLowerCase()
        )
      ) || 'activo';

    return {
      id: c.id,
      fullName: c.nombre,
      phone: c.telefono,
      whatsappId,
      avatarUrl: null,
      status: statusTag,
      isActiveCustomer: c.tags.includes('compro') || c.tags.includes('activo'),
      totalPurchasesCount: 0, // TODO: calculate when sales exist
      totalSpent: 0,
      lastPurchaseAt: null,
      lastChatAt: null,
      lastMessagePreview: null,
      assignedProduct: null,
      tags: c.tags,
      important: c.tags.includes('importante'),
      internalNote: c.notas,
    };
  });

  // Global stats
  const allCustomers = await prisma.customer.count({
    where: { empresa_id, deleted_at: null },
  });

  const activeCustomersCount = enriched.filter((c) => c.isActiveCustomer).length;

  // Count by status
  const byStatus = {
    activo: enriched.filter((c) => c.status === 'activo').length,
    interesado: enriched.filter((c) => c.status === 'interesado').length,
    reserva: enriched.filter((c) => c.status === 'reserva').length,
    compro: enriched.filter((c) => c.status === 'compro').length,
    noInteresado: enriched.filter((c) => c.status === 'noInteresado').length,
  };

  res.json({
    items: enriched,
    total,
    stats: {
      totalCustomers: allCustomers,
      activeCustomers: activeCustomersCount,
      totalPurchases: 0, // TODO
      totalIncome: 0, // TODO
      byStatus,
    },
    topProducts: [], // TODO
    topCustomers: enriched
      .filter((c) => c.isActiveCustomer)
      .slice(0, 5)
      .map((c) => ({
        id: c.id,
        fullName: c.fullName,
        totalSpent: c.totalSpent,
        totalPurchasesCount: c.totalPurchasesCount,
      })),
  });
}

/**
 * GET /api/customers/:id
 * Detalle completo del cliente
 */
export async function getCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const { id } = req.params;

  const customer = await prisma.customer.findUnique({
    where: { id, empresa_id, deleted_at: null },
  });

  if (!customer) throw new ApiError(404, 'Customer not found');

  // Get chats if any
  const whatsappId = customer.telefono ? `${customer.telefono}@s.whatsapp.net` : null;
  const chats = whatsappId
    ? await prisma.crmChat.findMany({
        where: { wa_id: whatsappId },
        orderBy: { last_message_at: 'desc' },
        select: {
          id: true,
          wa_id: true,
          display_name: true,
          last_message_preview: true,
          last_message_at: true,
          unread_count: true,
        },
      })
    : [];

  const chatsList = chats.map((chat) => ({
    chatId: chat.id,
    whatsappId: chat.wa_id,
    displayName: chat.display_name,
    lastMessagePreview: chat.last_message_preview,
    lastMessageAt: chat.last_message_at?.toISOString() || null,
    unreadCount: chat.unread_count,
  }));

  const statusTag =
    customer.tags.find((t: string) =>
      ['activo', 'interesado', 'reserva', 'compro', 'noInteresado'].includes(
        t.toLowerCase()
      )
    ) || 'activo';

  res.json({
    customer: {
      id: customer.id,
      fullName: customer.nombre,
      phone: customer.telefono,
      email: customer.email,
      address: customer.direccion,
      whatsappId,
      status: statusTag,
      tags: customer.tags,
      internalNote: customer.notas,
      important: customer.tags.includes('importante'),
      assignedProduct: null, // TODO
      createdAt: customer.created_at.toISOString(),
      updatedAt: customer.updated_at.toISOString(),
    },
    purchases: [], // TODO
    stats: {
      totalPurchases: 0,
      totalSpent: 0,
      lastPurchaseAt: null,
    },
    chats: chatsList,
  });
}

/**
 * DELETE /api/customers/:id
 * Soft delete
 */
export async function deleteCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const { id } = req.params;

  const customer = await prisma.customer.findUnique({
    where: { id, empresa_id },
  });

  if (!customer) throw new ApiError(404, 'Customer not found');

  await prisma.customer.update({
    where: { id },
    data: { deleted_at: new Date() },
  });

  res.json({ ok: true });
}

/**
 * GET /api/customers/:id/chats
 */
export async function getCustomerChats(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const { id } = req.params;

  const customer = await prisma.customer.findUnique({
    where: { id, empresa_id, deleted_at: null },
  });

  if (!customer) throw new ApiError(404, 'Customer not found');

  const whatsappId = customer.telefono ? `${customer.telefono}@s.whatsapp.net` : null;
  const chats = whatsappId
    ? await prisma.crmChat.findMany({
        where: { wa_id: whatsappId },
        orderBy: { last_message_at: 'desc' },
        select: {
          id: true,
          wa_id: true,
          display_name: true,
          last_message_preview: true,
          last_message_at: true,
          unread_count: true,
        },
      })
    : [];

  const items = chats.map((chat) => ({
    chatId: chat.id,
    whatsappId: chat.wa_id,
    displayName: chat.display_name,
    lastMessagePreview: chat.last_message_preview,
    lastMessageAt: chat.last_message_at?.toISOString() || null,
    unreadCount: chat.unread_count,
  }));

  res.json({ items });
}

/**
 * GET /api/crm/products/lookup
 */
export async function lookupProducts(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const query = (req.query.query as string) || '';

  const where: any = {
    empresa_id,
    is_active: true,
  };

  if (query.trim()) {
    where.nombre = { contains: query.trim(), mode: 'insensitive' };
  }

  const products = await prisma.producto.findMany({
    where,
    orderBy: { nombre: 'asc' },
    take: 20,
    select: {
      id: true,
      nombre: true,
      precio_venta: true,
      imagen_url: true,
    },
  });

  res.json(
    products.map((p) => ({
      id: p.id,
      name: p.nombre,
      price: Number(p.precio_venta),
      imageUrl: p.imagen_url,
    }))
  );
}

// Legacy endpoints
export async function createCustomer(req: Request, res: Response): Promise<void> {
  const empresa_id = empresaId(req);

  const parsed = customerCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { telefono, tags, ...rest } = parsed.data;

  const existing = await prisma.customer.findUnique({
    where: {
      empresa_id_telefono: { empresa_id, telefono },
    },
  });

  if (existing && !existing.deleted_at) {
    throw new ApiError(409, 'Ya existe un cliente con ese teléfono');
  }

  if (existing && existing.deleted_at) {
    const restored = await prisma.customer.update({
      where: { id: existing.id },
      data: {
        ...rest,
        telefono,
        tags: tags || [],
        deleted_at: null,
        updated_at: new Date(),
      },
    });
    res.status(200).json(restored);
    return;
  }

  const customer = await prisma.customer.create({
    data: {
      empresa_id,
      telefono,
      tags: tags || [],
      ...rest,
    },
  });

  res.status(201).json(customer);
}

export async function patchCustomer(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const { id } = req.params;

  const existing = await prisma.customer.findUnique({
    where: { id, empresa_id },
  });

  if (!existing) throw new ApiError(404, 'Customer not found');

  const parsed = customerUpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { tags, ...payload } = parsed.data;

  if (payload.telefono && payload.telefono !== existing.telefono) {
    const other = await prisma.customer.findUnique({
      where: {
        empresa_id_telefono: { empresa_id, telefono: payload.telefono },
      },
    });
    if (other) throw new ApiError(409, 'Ya existe un cliente con ese teléfono');
  }

  // Prepare data, excluding null tags
  const updateData: any = { ...payload };
  if (tags !== undefined) {
    if (tags === null) {
      updateData.tags = [];
    } else {
      updateData.tags = tags;
    }
  }

  const updated = await prisma.customer.update({
    where: { id },
    data: updateData,
  });

  res.json(updated);
}

export async function addCustomerNote(req: Request, res: Response) {
  const empresa_id = empresaId(req);
  const { id } = req.params;

  const existing = await prisma.customer.findUnique({
    where: { id, empresa_id },
  });

  if (!existing) throw new ApiError(404, 'Customer not found');

  const { text } = req.body;
  if (!text || typeof text !== 'string') {
    throw new ApiError(400, 'text is required');
  }

  const timestamp = new Date().toISOString();
  const newNote = `[${timestamp}] ${text}`;
  const updatedNotes = existing.notas ? `${existing.notas}\n\n${newNote}` : newNote;

  await prisma.customer.update({
    where: { id },
    data: { notas: updatedNotes },
  });

  res.json({ ok: true });
}
