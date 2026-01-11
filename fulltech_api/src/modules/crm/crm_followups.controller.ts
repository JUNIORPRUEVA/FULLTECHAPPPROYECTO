import type { Request, Response } from 'express';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  crmBulkFollowupsSchema,
  crmCreateChatFollowupsSchema,
} from './crm_whatsapp.schema';
import { actorEmpresaId, actorUserId } from './crm_whatsapp.controller';

function isUndefinedTableError(err: unknown, tableName: string): boolean {
  const lower = tableName.toLowerCase();
  const message = String((err as any)?.message ?? '');
  const metaMessage = String((err as any)?.meta?.message ?? '');
  const metaCode = String((err as any)?.meta?.code ?? '');

  if (metaCode === '42P01') return true;

  const haystack = `${message}\n${metaMessage}`.toLowerCase();
  return (
    haystack.includes(`relation "${lower}" does not exist`) ||
    haystack.includes(`table "${lower}" does not exist`) ||
    haystack.includes(`no such table: ${lower}`)
  );
}

async function assertFollowupsSchemaReady(): Promise<void> {
  try {
    await prisma.$queryRawUnsafe(`SELECT 1 FROM crm_followup_tasks LIMIT 1`);
  } catch (e) {
    if (isUndefinedTableError(e, 'crm_followup_tasks')) {
      throw new ApiError(
        409,
        'Seguimientos no est\u00e1n instalados (falta crm_followup_tasks). Ejecuta las migraciones SQL.',
      );
    }
    throw e;
  }
}

async function getUserActiveInstanceId(userId: string): Promise<string | null> {
  try {
    const rows = await prisma.$queryRawUnsafe<{ id: string }[]>(
      `SELECT id FROM crm_instancias WHERE user_id = $1 AND is_active = TRUE LIMIT 1`,
      userId,
    );
    return rows.length > 0 ? String(rows[0].id) : null;
  } catch (e) {
    if (isUndefinedTableError(e, 'crm_instancias')) return null;
    throw e;
  }
}

async function requireChatAccess(opts: {
  empresaId: string;
  userId: string;
  chatId: string;
}): Promise<{ id: string; wa_id: string; phone: string | null; instancia_id: string | null; status: string | null }> {
  const chat = await prisma.crmChat.findFirst({
    where: { id: opts.chatId, empresa_id: opts.empresaId },
    select: { id: true, wa_id: true, phone: true, instancia_id: true, owner_user_id: true, asignado_a_user_id: true, status: true },
  });
  if (!chat) throw new ApiError(404, 'Chat not found');

  if (chat.instancia_id) {
    try {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `SELECT id FROM crm_instancias WHERE id = $1 AND user_id = $2 LIMIT 1`,
        chat.instancia_id,
        opts.userId,
      );
      if (rows.length === 0) throw new ApiError(403, 'You do not have access to this chat');
    } catch (e) {
      if (isUndefinedTableError(e, 'crm_instancias')) {
        throw new ApiError(409, 'CRM multi-instancia no est\u00e1 instalado (falta crm_instancias). Ejecuta las migraciones SQL.');
      }
      throw e;
    }
    return { id: chat.id, wa_id: chat.wa_id, phone: chat.phone, instancia_id: chat.instancia_id, status: chat.status };
  }

  if (chat.owner_user_id !== opts.userId && chat.asignado_a_user_id !== opts.userId) {
    throw new ApiError(403, 'You do not have access to this chat');
  }

  return { id: chat.id, wa_id: chat.wa_id, phone: chat.phone, instancia_id: null, status: chat.status };
}

function parseIsoDate(v: string): Date {
  const d = new Date(String(v ?? '').trim());
  if (Number.isNaN(d.getTime())) throw new ApiError(400, 'Invalid datetime');
  return d;
}

function buildSchedule(runAt: Date, repeatCount: number, intervalMinutes: number): Date[] {
  const dates: Date[] = [];
  for (let i = 0; i < repeatCount; i++) {
    dates.push(new Date(runAt.getTime() + i * intervalMinutes * 60_000));
  }
  return dates;
}

export async function listChatFollowups(req: Request, res: Response) {
  await assertFollowupsSchemaReady();
  const empresaId = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = String(req.params.chatId ?? '').trim();
  if (!chatId) throw new ApiError(400, 'chatId is required');

  await requireChatAccess({ empresaId, userId, chatId });

  const items = await prisma.crmFollowupTask.findMany({
    where: { empresa_id: empresaId, chat_id: chatId },
    orderBy: { run_at: 'asc' },
    take: 200,
  });
  res.json({ items });
}

export async function cancelChatFollowups(req: Request, res: Response) {
  await assertFollowupsSchemaReady();
  const empresaId = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = String(req.params.chatId ?? '').trim();
  if (!chatId) throw new ApiError(400, 'chatId is required');

  await requireChatAccess({ empresaId, userId, chatId });

  const now = new Date();
  const updated = await prisma.crmFollowupTask.updateMany({
    where: {
      empresa_id: empresaId,
      chat_id: chatId,
      sent_at: null,
      skipped_at: null,
    },
    data: {
      skipped_at: now,
      skip_reason: 'cancelled_by_user',
      processing_at: null,
      processing_by: null,
    },
  });

  res.json({ ok: true, cancelled: updated.count });
}

export async function createChatFollowups(req: Request, res: Response) {
  await assertFollowupsSchemaReady();
  const empresaId = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = String(req.params.chatId ?? '').trim();
  if (!chatId) throw new ApiError(400, 'chatId is required');

  const parsed = crmCreateChatFollowupsSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const chat = await requireChatAccess({ empresaId, userId, chatId });

  const runAt = parseIsoDate(parsed.data.runAt);
  const repeatCount = parsed.data.repeatCount ?? 1;
  const intervalMinutes = parsed.data.intervalMinutes ?? 24 * 60;

  const payload = parsed.data.payload;
  if (payload.type === 'text') {
    const text = String(payload.text ?? '').trim();
    if (!text) throw new ApiError(400, 'payload.text is required for text followups');
  } else if (payload.type === 'image') {
    const url = String(payload.mediaUrl ?? '').trim();
    if (!url) throw new ApiError(400, 'payload.mediaUrl is required for image followups');
  }

  const schedule = buildSchedule(runAt, repeatCount, intervalMinutes);
  const created = await prisma.crmFollowupTask.createMany({
    data: schedule.map((d) => ({
      empresa_id: empresaId,
      chat_id: chat.id,
      instancia_id: chat.instancia_id,
      run_at: d,
      payload: payload as any,
      constraints: (parsed.data.constraints ?? null) as any,
      created_by_user_id: userId,
    })),
  });

  res.status(201).json({ ok: true, created: created.count });
}

export async function createBulkFollowups(req: Request, res: Response) {
  await assertFollowupsSchemaReady();
  const empresaId = actorEmpresaId(req);
  const userId = actorUserId(req);

  const parsed = crmBulkFollowupsSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const instanceId = await getUserActiveInstanceId(userId);
  if (!instanceId) {
    throw new ApiError(
      409,
      'No tienes una instancia activa configurada. Configura tu Instancia Evolution antes de programar seguimientos.',
    );
  }

  const runAt = parseIsoDate(parsed.data.schedule.runAt);
  const repeatCount = parsed.data.schedule.repeatCount ?? 1;
  const intervalMinutes = parsed.data.schedule.intervalMinutes ?? 24 * 60;
  const schedule = buildSchedule(runAt, repeatCount, intervalMinutes);

  const payload = parsed.data.payload;
  if (payload.type === 'text') {
    const text = String(payload.text ?? '').trim();
    if (!text) throw new ApiError(400, 'payload.text is required for text followups');
  } else if (payload.type === 'image') {
    const url = String(payload.mediaUrl ?? '').trim();
    if (!url) throw new ApiError(400, 'payload.mediaUrl is required for image followups');
  }

  const filter = parsed.data.filter ?? {};
  const status = String(filter.status ?? '').trim();
  const productId = String(filter.productId ?? '').trim();

  const fromRaw = filter.lastMessageFrom ? String(filter.lastMessageFrom) : '';
  const toRaw = filter.lastMessageTo ? String(filter.lastMessageTo) : '';
  const lastMessageFrom = fromRaw.trim().length > 0 ? parseIsoDate(fromRaw) : null;
  const lastMessageTo = toRaw.trim().length > 0 ? parseIsoDate(toRaw) : null;

  // Select chats from the user's instance, with optional filters.
  // Note: product is stored in crm_chat_meta; use a left join.
  const params: any[] = [empresaId, instanceId];
  let idx = 3;
  let sql = `
    SELECT c.id
    FROM crm_chats c
    LEFT JOIN crm_chat_meta m ON m.chat_id = c.id
    WHERE c.empresa_id = $1::uuid
      AND c.instancia_id = $2::uuid
      AND c.status NOT IN ('eliminado')
  `;
  if (status) {
    sql += ` AND c.status = $${idx++}::text`;
    params.push(status);
  }
  if (productId) {
    sql += ` AND m.product_id = $${idx++}::text`;
    params.push(productId);
  }
  if (lastMessageFrom) {
    sql += ` AND c.last_message_at >= $${idx++}::timestamptz`;
    params.push(lastMessageFrom);
  }
  if (lastMessageTo) {
    sql += ` AND c.last_message_at <= $${idx++}::timestamptz`;
    params.push(lastMessageTo);
  }
  sql += ` ORDER BY c.last_message_at DESC NULLS LAST LIMIT 1000`;

  const rows = await prisma.$queryRawUnsafe<{ id: string }[]>(sql, ...params);

  const chatIds = rows.map((r) => String(r.id));
  if (chatIds.length === 0) {
    res.status(201).json({ ok: true, created: 0, chats: 0 });
    return;
  }

  // Create tasks: N schedule entries per chat.
  const data: any[] = [];
  for (const chatId of chatIds) {
    for (const d of schedule) {
      data.push({
        empresa_id: empresaId,
        chat_id: chatId,
        instancia_id: instanceId,
        run_at: d,
        payload: payload as any,
        constraints: (parsed.data.constraints ?? null) as any,
        created_by_user_id: userId,
      });
    }
  }

  const created = await prisma.crmFollowupTask.createMany({ data });
  res.status(201).json({ ok: true, created: created.count, chats: chatIds.length });
}
