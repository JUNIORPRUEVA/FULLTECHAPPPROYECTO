import type { Request, Response } from 'express';
import { randomUUID } from 'crypto';

import { env } from '../../config/env';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { EvolutionClient } from '../../services/evolution/evolution_client';
import {
  crmChatMessagesListQuerySchema,
  crmChatsListQuerySchema,
  crmChatPatchSchema,
  crmSendMediaFieldsSchema,
  crmSendTextSchema,
} from './crm_whatsapp.schema';
import {
  detectMediaType,
  toPublicUrlFromAbsoluteFile,
  uploadCrmFile,
} from './crm_whatsapp.upload';
import { emitCrmEvent } from './crm_stream';

function parseBeforeDate(raw?: string): Date | null {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

function digitsOnly(v: string): string {
  return v.replace(/[^0-9]/g, '');
}

function phoneFromWaId(waId: string): string | null {
  const at = waId.indexOf('@');
  const base = at >= 0 ? waId.slice(0, at) : waId;
  const digits = digitsOnly(base);
  if (!digits) return null;
  return digits;
}

function toPhoneE164(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const d = digitsOnly(raw);
  if (!d) return null;

  // Minimal normalization: if it looks like a 10-digit NANP number, prefix country code "1".
  // Otherwise, keep as-is.
  if (d.length == 10) return `1${d}`;
  return d;
}

function toChatApiItem(chat: any) {
  const waId = String(chat.wa_id ?? chat.waId ?? '');
  const phoneCandidate = chat.phone ?? phoneFromWaId(waId);
  const phoneE164 = toPhoneE164(phoneCandidate);

  const important = Boolean(chat.important ?? chat.is_important ?? false);
  const productId = chat.product_id ?? chat.productId ?? null;
  const internalNote = chat.internal_note ?? chat.note ?? null;
  const assignedUserId = chat.assigned_user_id ?? chat.assigned_to_user_id ?? null;

  return {
    // canonical camelCase
    id: chat.id,
    waId,
    phoneE164,
    displayName: chat.display_name ?? null,
    lastMessageText: chat.last_message_preview ?? null,
    lastMessageAt: chat.last_message_at ?? null,
    unreadCount: chat.unread_count ?? 0,
    status: chat.status ?? 'activo',
    // preferred names per spec
    isImportant: important,
    productId,
    note: internalNote,
    assignedToUserId: assignedUserId,

    // backward compatible
    important,
    internalNote,
    assignedUserId,

    // backward compatible snake_case
    wa_id: waId,
    phone: phoneE164,
    display_name: chat.display_name ?? null,
    last_message_preview: chat.last_message_preview ?? null,
    last_message_at: chat.last_message_at ?? null,
    unread_count: chat.unread_count ?? 0,
    created_at: chat.created_at ?? null,
    updated_at: chat.updated_at ?? null,
    product_id: productId,
    internal_note: internalNote,
    assigned_user_id: assignedUserId,
    is_important: important,
    assigned_to_user_id: assignedUserId,
  };
}

function isMissingTableError(err: unknown, tableName: string): boolean {
  const lower = tableName.toLowerCase();
  const message = String((err as any)?.message ?? '');
  const metaMessage = String((err as any)?.meta?.message ?? '');
  const metaCode = String((err as any)?.meta?.code ?? '');

  // Postgres undefined_table
  if (metaCode === '42P01') return true;

  const haystack = `${message}\n${metaMessage}`.toLowerCase();
  return (
    haystack.includes(`relation "${lower}" does not exist`) ||
    haystack.includes(`table "${lower}" does not exist`) ||
    haystack.includes(`no such table: ${lower}`)
  );
}

async function fetchChatMeta(chatIds: string[]): Promise<Map<string, any>> {
  const map = new Map<string, any>();
  if (chatIds.length === 0) return map;

  // Safe, parameterized query.
  let rows: any[] = [];
  try {
    rows = await prisma.$queryRawUnsafe<any[]>(
      `
        SELECT chat_id, important, product_id, internal_note, assigned_user_id
        FROM crm_chat_meta
        WHERE chat_id = ANY($1::uuid[])
      `,
      chatIds,
    );
  } catch (e) {
    // If meta table doesn't exist yet, treat as no meta instead of 500.
    if (isMissingTableError(e, 'crm_chat_meta')) return map;
    throw e;
  }

  for (const r of rows) {
    map.set(String(r.chat_id), r);
  }
  return map;
}

async function upsertChatMeta(
  chatId: string,
  data: {
    important?: boolean;
    product_id?: string | null;
    internal_note?: string | null;
    assigned_user_id?: string | null;
  },
): Promise<void> {
  const important = data.important ?? false;
  const productId = data.product_id ?? null;
  const internalNote = data.internal_note ?? null;
  const assignedUserId = data.assigned_user_id ?? null;

  try {
    await prisma.$executeRawUnsafe(
      `
        INSERT INTO crm_chat_meta (chat_id, important, product_id, internal_note, assigned_user_id, updated_at)
        VALUES ($1::uuid, $2::boolean, $3::text, $4::text, $5::uuid, now())
        ON CONFLICT (chat_id)
        DO UPDATE SET
          important = EXCLUDED.important,
          product_id = EXCLUDED.product_id,
          internal_note = EXCLUDED.internal_note,
          assigned_user_id = EXCLUDED.assigned_user_id,
          updated_at = now()
      `,
      chatId,
      important,
      productId,
      internalNote,
      assignedUserId,
    );
  } catch (e) {
    // If meta table doesn't exist yet, ignore instead of 500.
    if (isMissingTableError(e, 'crm_chat_meta')) return;
    throw e;
  }
}

function toMessageApiItem(m: any) {
  const direction = String(m.direction ?? 'in');
  const fromMe = direction === 'out';
  const type = String(m.message_type ?? m.type ?? 'text');
  const createdAt = m.timestamp ?? m.created_at ?? null;
  const normalizeMediaUrl = (raw: unknown): string | null => {
    if (typeof raw !== 'string') return null;
    const url = raw.trim();
    if (url.length === 0) return null;

    const base = env.PUBLIC_BASE_URL.replace(/\/$/, '');

    if (url.startsWith('/uploads/')) return `${base}${url}`;

    try {
      const parsed = new URL(url);
      const host = parsed.hostname;
      if (host === 'localhost' || host === '127.0.0.1' || host === '0.0.0.0') {
        return `${base}${parsed.pathname}${parsed.search}`;
      }
    } catch {
      // ignore
    }

    return url;
  };

  const mediaUrl = normalizeMediaUrl(m.media_url ?? null);

  return {
    // canonical camelCase
    id: m.id,
    chatId: m.chat_id,
    direction,
    fromMe,
    type,
    text: m.text ?? null,
    mediaUrl,
    mimeType: m.media_mime ?? null,
    fileName: m.media_name ?? null,
    size: m.media_size ?? null,
    status: m.status ?? 'received',
    createdAt,

    // backward compatible snake_case
    chat_id: m.chat_id,
    message_type: m.message_type ?? type,
    media_url: mediaUrl,
    media_mime: m.media_mime ?? null,
    media_size: m.media_size ?? null,
    media_name: m.media_name ?? null,
    remote_message_id: m.remote_message_id ?? null,
    quoted_message_id: m.quoted_message_id ?? null,
    timestamp: m.timestamp ?? null,
    created_at: m.created_at ?? null,
    error: m.error ?? null,
  };
}

export async function listChats(req: Request, res: Response) {
  const parsed = crmChatsListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, status, productId, product_id, page, limit } = parsed.data;
  const skip = (page - 1) * limit;

  const where: any = {};

  if (status && status.trim().length > 0) {
    where.status = status.trim();
  }

  if (search && search.trim().length > 0) {
    const q = search.trim();
    where.OR = [
      { wa_id: { contains: q, mode: 'insensitive' } },
      { phone: { contains: q, mode: 'insensitive' } },
      { display_name: { contains: q, mode: 'insensitive' } },
      { last_message_preview: { contains: q, mode: 'insensitive' } },
    ];
  }

  const effectiveProductId = (productId ?? product_id ?? '').trim();
  if (effectiveProductId.length > 0) {
    let rows: { chat_id: string }[] = [];
    try {
      rows = await prisma.$queryRawUnsafe<{ chat_id: string }[]>(
        `SELECT chat_id FROM crm_chat_meta WHERE product_id = $1::text`,
        effectiveProductId,
      );
    } catch (e) {
      // If meta table doesn't exist, product filtering can't be applied.
      // Return empty instead of 500 for safety.
      if (isMissingTableError(e, 'crm_chat_meta')) {
        res.json({ items: [], total: 0, page, limit });
        return;
      }
      throw e;
    }
    const ids = rows.map((r) => String(r.chat_id));
    // If no matches, return empty quickly.
    if (ids.length === 0) {
      res.json({ items: [], total: 0, page, limit });
      return;
    }
    where.id = { in: ids };
  }

  const [items, total] = await Promise.all([
    prisma.crmChat.findMany({
      where,
      orderBy: [{ last_message_at: 'desc' }, { updated_at: 'desc' }],
      take: limit,
      skip,
    }),
    prisma.crmChat.count({ where }),
  ]);

  const metaByChatId = await fetchChatMeta(items.map((c) => c.id));
  const merged = items.map((c) => ({ ...c, ...(metaByChatId.get(c.id) ?? {}) }));
  const mapped = merged.map(toChatApiItem);
  res.json({ items: mapped, total, page, limit });
}

export async function patchChat(req: Request, res: Response) {
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  const parsed = crmChatPatchSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const {
    status,
    important,
    product_id,
    internal_note,
    assigned_user_id,
    isImportant,
    productId,
    note,
    assignedToUserId,
  } = parsed.data;

  const effectiveImportant = typeof isImportant !== 'undefined' ? isImportant : important;
  const effectiveProductId = typeof productId !== 'undefined' ? productId : product_id;
  const effectiveNote = typeof note !== 'undefined' ? note : internal_note;
  const effectiveAssigned =
    typeof assignedToUserId !== 'undefined' ? assignedToUserId : assigned_user_id;

  if (status && status.trim().length > 0) {
    await prisma.crmChat.update({
      where: { id: chatId },
      data: { status: status.trim() },
    });
  }

  // Only upsert meta if any meta fields are provided.
  const hasMeta =
    typeof effectiveImportant !== 'undefined' ||
    typeof effectiveProductId !== 'undefined' ||
    typeof effectiveNote !== 'undefined' ||
    typeof effectiveAssigned !== 'undefined';
  if (hasMeta) {
    await upsertChatMeta(chatId, {
      important: effectiveImportant,
      product_id: effectiveProductId,
      internal_note: effectiveNote,
      assigned_user_id: effectiveAssigned,
    });
  }

  const updated = await prisma.crmChat.findUnique({ where: { id: chatId } });
  const metaById = await fetchChatMeta([chatId]);
  const merged = { ...updated, ...(metaById.get(chatId) ?? {}) };

  emitCrmEvent({ type: 'chat.updated', chatId });

  res.json({ item: toChatApiItem(merged) });
}

export async function listChatStats(_req: Request, res: Response) {
  const [total, byStatusRows, unreadAgg] = await Promise.all([
    prisma.crmChat.count(),
    prisma.crmChat.groupBy({
      by: ['status'],
      _count: { _all: true },
    }),
    prisma.crmChat.aggregate({
      _sum: { unread_count: true },
    }),
  ]);

  // Important flag lives in crm_chat_meta.
  let importantCount = 0;
  try {
    const importantRows = await prisma.$queryRawUnsafe<{ count: number }[]>(
      `SELECT COUNT(*)::int as count FROM crm_chat_meta WHERE important = TRUE`,
    );
    importantCount = importantRows?.[0]?.count ?? 0;
  } catch (e) {
    if (!isMissingTableError(e, 'crm_chat_meta')) throw e;
  }

  const byStatus: Record<string, number> = {};
  for (const r of byStatusRows) {
    byStatus[String(r.status ?? 'unknown')] = (r._count?._all as number) ?? 0;
  }

  const unreadTotal = Number(unreadAgg._sum.unread_count ?? 0);

  res.json({
    total,
    byStatus,
    importantCount,
    unreadTotal,
  });
}

export async function listChatMessages(req: Request, res: Response) {
  const chatId = req.params.chatId;

  // Temporary debug logs for production verification.
  console.log('[CRM] listChatMessages called', { chatId });

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  const parsed = crmChatMessagesListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const before = parseBeforeDate(parsed.data.before);

  const where: any = { chat_id: chatId };
  if (before) where.timestamp = { lt: before };

  const itemsDesc = await prisma.crmChatMessage.findMany({
    where,
    orderBy: { timestamp: 'desc' },
    take: parsed.data.limit,
  });

  const items = itemsDesc.slice().reverse();
  const nextBefore = itemsDesc.length > 0 ? itemsDesc[itemsDesc.length - 1].timestamp : null;

  console.log('[CRM] listChatMessages result', { chatId, count: items.length });

  const mapped = items.map(toMessageApiItem);

  res.json({
    items: mapped,
    next_before: nextBefore,
    // also provide camelCase for new clients
    nextBefore,
  });
}

export async function postUpload(req: Request, res: Response) {
  // multer placed file in req.file
  const file = req.file;
  if (!file) throw new ApiError(400, 'Missing file field "file"');

  const publicUrl = toPublicUrlFromAbsoluteFile(file.path);

  res.status(201).json({
    url: publicUrl,
    mime: file.mimetype,
    size: file.size,
    name: file.originalname,
  });
}

export { uploadCrmFile };

export async function sendTextMessage(req: Request, res: Response) {
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  const parsed = crmSendTextSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const aiSuggestionId = parsed.data.aiSuggestionId ?? null;
  const aiSuggestedText = parsed.data.aiSuggestedText ?? null;
  const aiUsedKnowledge = parsed.data.aiUsedKnowledge ?? null;

  const createdAt = new Date();

  // Create message as pending so UI can show immediately.
  const pending = await prisma.crmChatMessage.create({
    data: {
      chat_id: chatId,
      direction: 'out',
      message_type: 'text',
      text: parsed.data.text.trim(),
      status: 'sent',
      timestamp: createdAt,
    },
  });

  const evo = new EvolutionClient();

  try {
    const send = await evo.sendText({
      toWaId: chat.wa_id,
      toPhone: chat.phone ?? undefined,
      text: parsed.data.text.trim(),
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: pending.id },
      data: {
        remote_message_id: send.messageId,
        status: 'sent',
      },
    });

    if (aiSuggestionId || aiSuggestedText || (aiUsedKnowledge && aiUsedKnowledge.length)) {
      const auditId = randomUUID();
      await prisma.$executeRawUnsafe(
        `
        INSERT INTO ai_message_audits (id, chat_id, message_id, suggestion_id, suggested_text, final_text, used_knowledge)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::text, $6::text, $7::jsonb)
        `,
        auditId,
        chatId,
        updated.id,
        aiSuggestionId,
        aiSuggestedText,
        parsed.data.text.trim(),
        JSON.stringify(aiUsedKnowledge ?? []),
      );
    }

    await prisma.crmChat.update({
      where: { id: chatId },
      data: {
        last_message_preview: parsed.data.text.trim().slice(0, 180),
        last_message_at: createdAt,
      },
    });

    emitCrmEvent({ type: 'message.new', chatId, messageId: updated.id });
    emitCrmEvent({ type: 'chat.updated', chatId });

    res.status(201).json({ item: updated });
  } catch (e: any) {
    // Log full context so we can diagnose Evolution connectivity/auth issues in EasyPanel logs.
    console.error('[CRM] sendTextMessage: Evolution send failed', {
      chatId,
      waId: chat.wa_id,
      phone: chat.phone,
      error: e?.message ?? String(e),
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: pending.id },
      data: {
        status: 'failed',
        error: e?.message ?? String(e),
      },
    });

    if (aiSuggestionId || aiSuggestedText || (aiUsedKnowledge && aiUsedKnowledge.length)) {
      const auditId = randomUUID();
      await prisma.$executeRawUnsafe(
        `
        INSERT INTO ai_message_audits (id, chat_id, message_id, suggestion_id, suggested_text, final_text, used_knowledge)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::text, $6::text, $7::jsonb)
        `,
        auditId,
        chatId,
        updated.id,
        aiSuggestionId,
        aiSuggestedText,
        parsed.data.text.trim(),
        JSON.stringify(aiUsedKnowledge ?? []),
      );
    }

    emitCrmEvent({ type: 'message.new', chatId, messageId: updated.id });

    // Return the failed message to the client so the UI can keep working.
    res.status(201).json({
      item: updated,
      warning: 'Evolution send failed',
    });
  }
}

export async function sendMediaMessage(req: Request, res: Response) {
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  const file = req.file;
  if (!file) throw new ApiError(400, 'Missing file field "file"');

  const parsed = crmSendMediaFieldsSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const publicUrl = toPublicUrlFromAbsoluteFile(file.path);
  const mediaType = parsed.data.type ?? detectMediaType(file.mimetype);
  const createdAt = new Date();

  const msg = await prisma.crmChatMessage.create({
    data: {
      chat_id: chatId,
      direction: 'out',
      message_type: mediaType,
      text: parsed.data.caption?.trim() || null,
      media_url: publicUrl,
      media_mime: file.mimetype,
      media_size: file.size,
      media_name: file.originalname,
      status: 'sent',
      timestamp: createdAt,
    },
  });

  const evo = new EvolutionClient();

  try {
    const send = await evo.sendMedia({
      toWaId: chat.wa_id,
      toPhone: chat.phone ?? undefined,
      mediaUrl: publicUrl,
      caption: parsed.data.caption?.trim() || undefined,
      mediaType,
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: msg.id },
      data: { remote_message_id: send.messageId, status: 'sent' },
    });

    await prisma.crmChat.update({
      where: { id: chatId },
      data: {
        last_message_preview: parsed.data.caption?.trim().slice(0, 180) || `[${mediaType}]`,
        last_message_at: createdAt,
      },
    });

    emitCrmEvent({ type: 'message.new', chatId, messageId: updated.id });
    emitCrmEvent({ type: 'chat.updated', chatId });

    res.status(201).json({ item: updated });
  } catch (e: any) {
    console.error('[CRM] sendMediaMessage: Evolution send failed', {
      chatId,
      waId: chat.wa_id,
      phone: chat.phone,
      error: e?.message ?? String(e),
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: msg.id },
      data: {
        status: 'failed',
        error: e?.message ?? String(e),
      },
    });

    emitCrmEvent({ type: 'message.new', chatId, messageId: updated.id });

    // Return the failed message to the client so the UI can keep working.
    res.status(201).json({
      item: updated,
      warning: 'Evolution send failed',
    });
  }
}

export async function markChatRead(req: Request, res: Response) {
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  await prisma.crmChat.update({
    where: { id: chatId },
    data: { unread_count: 0 },
  });

  emitCrmEvent({ type: 'chat.updated', chatId });

  res.json({ ok: true });
}

export async function sseStream(req: Request, res: Response) {
  // SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  // Send a first ping so proxies open the stream.
  res.write(`event: ping\ndata: ${JSON.stringify({ ok: true })}\n\n`);

  const { onCrmEvent } = await import('./crm_stream');
  const off = onCrmEvent((evt) => {
    res.write(`event: crm\ndata: ${JSON.stringify(evt)}\n\n`);
  });

  const ping = setInterval(() => {
    res.write(`event: ping\ndata: ${JSON.stringify({ t: Date.now() })}\n\n`);
  }, 25000);

  req.on('close', () => {
    clearInterval(ping);
    off();
  });
}
