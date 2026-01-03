import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  crmMessageCreateSchema,
  crmMessageListQuerySchema,
  crmSendMessageSchema,
  crmTaskCreateSchema,
  crmTaskPatchSchema,
  crmTasksListQuerySchema,
  crmThreadCreateSchema,
  crmThreadPatchSchema,
  crmThreadsListQuerySchema,
} from './crm.schema';
import { EvolutionClient } from '../../services/evolution/evolution_client';

function actorEmpresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

function parseBeforeDate(raw?: string): Date | null {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

export async function listThreads(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const parsed = crmThreadsListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { estado, assigned_user_id, search, pinned, limit, offset } = parsed.data;

  const where: any = {
    empresa_id,
    deleted_at: null,
  };

  if (estado && estado.trim().length > 0) where.estado_crm = estado.trim();
  if (assigned_user_id) where.assigned_user_id = assigned_user_id;
  if (typeof pinned === 'boolean') where.pinned = pinned;

  if (search && search.trim().length > 0) {
    const q = search.trim();
    where.OR = [
      { phone_number: { contains: q, mode: 'insensitive' } },
      { display_name: { contains: q, mode: 'insensitive' } },
      { last_message_preview: { contains: q, mode: 'insensitive' } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.crmThread.findMany({
      where,
      include: { customer: true },
      orderBy: [{ pinned: 'desc' }, { last_message_at: 'desc' }, { updated_at: 'desc' }],
      take: limit,
      skip: offset,
    }),
    prisma.crmThread.count({ where }),
  ]);

  res.json({ items, total, limit, offset });
}

export async function getThread(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id, empresa_id, deleted_at: null },
    include: { customer: true },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  res.json({ item: thread });
}

export async function createThread(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = crmThreadCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { phone_number, display_name, canal } = parsed.data;

  const existing = await prisma.crmThread.findFirst({
    where: { empresa_id, phone_number, deleted_at: null },
    include: { customer: true },
  });
  if (existing) {
    res.json({ item: existing, created: false });
    return;
  }

  const created = await prisma.crmThread.create({
    data: {
      empresa_id,
      phone_number,
      display_name: display_name ?? null,
      canal: canal ?? 'whatsapp',
    },
    include: { customer: true },
  });

  res.status(201).json({ item: created, created: true });
}

export async function patchThread(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const parsed = crmThreadPatchSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const existing = await prisma.crmThread.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Thread not found');

  const updated = await prisma.crmThread.update({
    where: { id },
    data: {
      ...parsed.data,
      sync_version: { increment: 1 },
    },
    include: { customer: true },
  });

  res.json({ item: updated });
}

export async function listMessages(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const threadId = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id: threadId, empresa_id, deleted_at: null },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  const parsed = crmMessageListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const beforeDate = parseBeforeDate(parsed.data.before);

  const where: any = {
    empresa_id,
    thread_id: threadId,
    deleted_at: null,
  };

  if (beforeDate) {
    where.created_at = { lt: beforeDate };
  }

  const itemsDesc = await prisma.crmMessage.findMany({
    where,
    orderBy: { created_at: 'desc' },
    take: parsed.data.limit,
  });

  const items = itemsDesc.slice().reverse();
  const nextBefore = itemsDesc.length > 0 ? itemsDesc[itemsDesc.length - 1].created_at : null;

  res.json({ items, next_before: nextBefore });
}

export async function postMessage(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const threadId = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id: threadId, empresa_id, deleted_at: null },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  const parsed = crmMessageCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const data = parsed.data;
  const hasBody = typeof data.body === 'string' && data.body.trim().length > 0;
  const hasMedia = typeof data.media_url === 'string' && data.media_url.trim().length > 0;
  if (!hasBody && !hasMedia) {
    throw new ApiError(400, 'body or media_url is required');
  }

  const createdAt = new Date();

  const created = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const msg = await tx.crmMessage.create({
      data: {
        empresa_id,
        thread_id: threadId,
        message_id: data.message_id ?? null,
        from_me: data.from_me,
        type: data.type,
        body: data.body ?? null,
        media_url: data.media_url ?? null,
        created_at: createdAt,
      },
    });

    await tx.crmThread.update({
      where: { id: threadId },
      data: {
        last_message_preview: hasBody ? (data.body ?? '').slice(0, 180) : '[media]',
        last_message_at: createdAt,
        sync_version: { increment: 1 },
      },
    });

    return msg;
  });

  // NOTA: aquí no integramos Evolution todavía.
  res.status(201).json({ item: created, ok: true });
}

export async function sendMessage(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const threadId = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id: threadId, empresa_id, deleted_at: null },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  const parsed = crmSendMessageSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { type, message, media_url } = parsed.data;
  const hasMessage = typeof message === 'string' && message.trim().length > 0;
  const hasMedia = typeof media_url === 'string' && media_url.trim().length > 0;

  if (!hasMessage && !hasMedia) {
    throw new ApiError(400, 'message or media_url is required');
  }

  const evo = new EvolutionClient();

  let sendResult: { messageId: string | null; raw: any };
  try {
    if (hasMedia) {
      sendResult = await evo.sendMedia({
        toPhone: thread.phone_number,
        mediaUrl: media_url!.trim(),
        caption: hasMessage ? message!.trim() : undefined,
        mediaType: type,
      });
    } else {
      sendResult = await evo.sendText({
        toPhone: thread.phone_number,
        text: message!.trim(),
      });
    }
  } catch (e: any) {
    throw new ApiError(502, 'Evolution send failed', { error: e?.message ?? String(e) });
  }

  const createdAt = new Date();
  const preview = hasMessage ? message!.trim().slice(0, 180) : '[media]';

  const created = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const msg = await tx.crmMessage.create({
      data: {
        empresa_id,
        thread_id: threadId,
        message_id: sendResult.messageId,
        from_me: true,
        type,
        body: hasMessage ? message!.trim() : null,
        media_url: hasMedia ? media_url!.trim() : null,
        created_at: createdAt,
      },
    });

    await tx.crmThread.update({
      where: { id: threadId },
      data: {
        last_message_preview: preview,
        last_message_at: createdAt,
        sync_version: { increment: 1 },
      },
    });

    return msg;
  });

  res.status(201).json({ ok: true, item: created, evolution: sendResult.raw });
}

export async function listTasks(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = crmTasksListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { assigned_user_id, status, date_from, date_to, limit } = parsed.data;

  const where: any = { empresa_id, deleted_at: null };
  if (assigned_user_id) where.assigned_user_id = assigned_user_id;
  if (status && status.trim().length > 0) where.status = status.trim();

  if (date_from || date_to) {
    where.fecha_hora = {
      ...(date_from ? { gte: new Date(date_from) } : null),
      ...(date_to ? { lte: new Date(date_to) } : null),
    };
  }

  const items = await prisma.crmTask.findMany({
    where,
    orderBy: { fecha_hora: 'asc' },
    take: limit,
    include: { thread: true },
  });

  res.json({ items });
}

export async function createTaskForThread(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const threadId = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id: threadId, empresa_id, deleted_at: null },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  const parsed = crmTaskCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const created = await prisma.crmTask.create({
    data: {
      empresa_id,
      thread_id: threadId,
      assigned_user_id: parsed.data.assigned_user_id,
      tipo: parsed.data.tipo,
      fecha_hora: new Date(parsed.data.fecha_hora),
      status: parsed.data.status,
      nota: parsed.data.nota ?? null,
    },
    include: { thread: true },
  });

  res.status(201).json({ item: created });
}

export async function patchTask(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const parsed = crmTaskPatchSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const existing = await prisma.crmTask.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Task not found');

  const updated = await prisma.crmTask.update({
    where: { id },
    data: {
      ...parsed.data,
      ...(parsed.data.fecha_hora ? { fecha_hora: new Date(parsed.data.fecha_hora) } : null),
      sync_version: { increment: 1 },
    },
  });

  res.json({ item: updated });
}

export async function deleteTask(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const existing = await prisma.crmTask.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Task not found');

  await prisma.crmTask.update({
    where: { id },
    data: { deleted_at: new Date(), sync_version: { increment: 1 } },
  });

  res.status(204).send();
}

export async function convertThreadToCustomer(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const threadId = req.params.id;

  const thread = await prisma.crmThread.findFirst({
    where: { id: threadId, empresa_id, deleted_at: null },
  });
  if (!thread) throw new ApiError(404, 'Thread not found');

  if (thread.customer_id) {
    const customer = await prisma.customer.findFirst({
      where: { id: thread.customer_id, empresa_id, deleted_at: null },
    });
    if (!customer) throw new ApiError(404, 'Customer not found');

    const updatedThread = await prisma.crmThread.findFirst({
      where: { id: threadId, empresa_id },
      include: { customer: true },
    });

    res.json({ customer, thread: updatedThread });
    return;
  }

  const phone = thread.phone_number;

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    // If a customer already exists with same phone, attach it.
    let customer = await tx.customer.findFirst({
      where: { empresa_id, telefono: phone, deleted_at: null },
    });

    if (!customer) {
      const name =
        (thread.display_name && thread.display_name.trim().length > 0
          ? thread.display_name.trim()
          : `Cliente WhatsApp ${phone}`);

      customer = await tx.customer.create({
        data: {
          empresa_id,
          nombre: name,
          telefono: phone,
          origen: 'whatsapp',
        },
      });
    }

    const updatedThread = await tx.crmThread.update({
      where: { id: threadId },
      data: {
        customer_id: customer.id,
        sync_version: { increment: 1 },
        // Si no está en compro, lo dejamos como está (por defecto) o lo movemos a interesado.
        ...(thread.estado_crm === 'pendiente' ? { estado_crm: 'interesado' } : null),
      },
      include: { customer: true },
    });

    return { customer, thread: updatedThread };
  });

  res.json(result);
}
