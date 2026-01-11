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
  crmPostSaleStateSchema,
  crmChatStatusSchema,
  crmDeleteChatMessageSchema,
  crmEditChatMessageSchema,
  crmOutboundSendTextSchema,
  crmSendTextSchema,
} from './crm_whatsapp.schema';
import { emitCrmEvent } from './crm_stream';

// Outbound is text-only.
const CRM_MEDIA_DISABLED_ERROR = 'Outbound media is disabled. Send text only.';

export function actorEmpresaId(req: Request): string {
  const empresaId = (req as any)?.user?.empresaId as string | undefined;
  if (!empresaId) throw new ApiError(401, 'Missing empresaId');
  return empresaId;
}

export function actorUserId(req: Request): string {
  const userId = (req as any)?.user?.userId as string | undefined;
  if (!userId) throw new ApiError(401, 'Missing userId');
  return userId;
}

function isUndefinedTableError(err: unknown, tableName: string): boolean {
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

async function getUserInstanceIdForLists(userId: string): Promise<string | null> {
  // Prefer explicit "active instance" setting.
  const active = await getUserActiveInstanceId(userId);
  if (active) return active;

  // Fallback for legacy data: derive from chats.
  try {
    const instance = await prisma.crmChat.findFirst({
      where: {
        owner_user_id: userId,
        instancia_id: { not: null },
      },
      select: { instancia_id: true },
      orderBy: [{ updated_at: 'desc' }, { created_at: 'desc' }],
    });

    return instance?.instancia_id ? String(instance.instancia_id) : null;
  } catch {
    return null;
  }
}

async function requireChatAccess(opts: {
  empresaId: string;
  userId: string;
  chatId: string;
}): Promise<{
  id: string;
  wa_id: string;
  phone: string | null;
  last_message_at: Date | null;
  instancia_id: string | null;
  owner_user_id: string | null;
  asignado_a_user_id: string | null;
}> {
  const chat = await prisma.crmChat.findFirst({
    where: { id: opts.chatId, empresa_id: opts.empresaId },
    select: {
      id: true,
      wa_id: true,
      phone: true,
      last_message_at: true,
      instancia_id: true,
      owner_user_id: true,
      asignado_a_user_id: true,
    },
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
    return chat;
  }

  // Legacy chats without instancia_id: require explicit ownership/assignment.
  if (chat.owner_user_id !== opts.userId && chat.asignado_a_user_id !== opts.userId) {
    throw new ApiError(403, 'You do not have access to this chat');
  }

  return chat;
}

async function getEvolutionClientForChat(chatId: string): Promise<EvolutionClient> {
  const chat = await prisma.crmChat.findUnique({
    where: { id: chatId },
    select: { instancia_id: true },
  });

  const instanciaId = chat?.instancia_id ? String(chat.instancia_id) : '';
  if (!instanciaId) {
    // Backwards compatibility for environments that still use env-based Evolution config.
    return new EvolutionClient();
  }

  try {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT nombre_instancia, evolution_base_url, evolution_api_key
       FROM crm_instancias
       WHERE id = $1
       LIMIT 1`,
      instanciaId,
    );

    const inst = rows[0];
    if (!inst?.evolution_base_url || !inst?.evolution_api_key) {
      throw new ApiError(409, 'Evolution no est\u00e1 configurado para esta instancia');
    }

    return new EvolutionClient({
      baseUrl: String(inst.evolution_base_url),
      apiKey: String(inst.evolution_api_key),
      instanceName: String(inst.nombre_instancia ?? ''),
    });
  } catch (e) {
    if (isUndefinedTableError(e, 'crm_instancias')) {
      throw new ApiError(409, 'CRM multi-instancia no est\u00e1 instalado (falta crm_instancias). Ejecuta las migraciones SQL.');
    }
    throw e;
  }
}

async function isChatLockedByOperations(chatId: string): Promise<boolean> {
  try {
    const active = await prisma.operationsJob.findFirst({
      where: {
        crm_chat_id: chatId,
        deleted_at: null,
        status: { notIn: ['completed', 'closed', 'cancelled'] as any },
      } as any,
      select: { id: true },
    });
    return Boolean(active?.id);
  } catch {
    // If operations tables are missing or Prisma model isn't available, don't lock.
    return false;
  }
}

let aiMessageAuditsExistsCache: boolean | null = null;
let aiMessageAuditsExistsAtMs = 0;
async function aiMessageAuditsTableExists(): Promise<boolean> {
  const now = Date.now();
  if (aiMessageAuditsExistsCache != null && now - aiMessageAuditsExistsAtMs < 60_000) {
    return aiMessageAuditsExistsCache;
  }

  try {
    const rows = await prisma.$queryRawUnsafe<{ regclass: string | null }[]>(
      'SELECT to_regclass($1) as regclass',
      'public.ai_message_audits',
    );
    const exists = Boolean(rows?.[0]?.regclass);
    aiMessageAuditsExistsCache = exists;
    aiMessageAuditsExistsAtMs = now;
    return exists;
  } catch {
    aiMessageAuditsExistsCache = false;
    aiMessageAuditsExistsAtMs = now;
    return false;
  }
}

const opsTableExistsCache = new Map<string, { exists: boolean; atMs: number }>();
async function tableExists(tableName: string): Promise<boolean> {
  const now = Date.now();
  const cached = opsTableExistsCache.get(tableName);
  if (cached && now - cached.atMs < 60_000) return cached.exists;

  try {
    const rows = await prisma.$queryRawUnsafe<{ regclass: string | null }[]>(
      'SELECT to_regclass($1) as regclass',
      `public.${tableName}`,
    );
    const exists = Boolean(rows?.[0]?.regclass);
    opsTableExistsCache.set(tableName, { exists, atMs: now });
    return exists;
  } catch {
    opsTableExistsCache.set(tableName, { exists: false, atMs: now });
    return false;
  }
}

function parseBeforeDate(raw?: string): Date | null {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

function digitsOnly(v: string): string {
  return v.replace(/[^0-9]/g, '');
}

async function fetchCustomerNamesByPhones(opts: {
  empresaId: string;
  phoneDigits: string[];
}): Promise<Map<string, string>> {
  const unique = Array.from(new Set(opts.phoneDigits.map((p) => String(p ?? '').trim()).filter(Boolean)));
  if (unique.length === 0) return new Map();

  // Match customers by digits-only phone. This tolerates values stored as "+1..." or "(809)...".
  const rows = await prisma.$queryRawUnsafe<{ telefono_digits: string; nombre: string }[]>(
    `
    SELECT regexp_replace(telefono, '\\D', '', 'g') AS telefono_digits, nombre
    FROM customers_legacy
    WHERE empresa_id = $1::uuid
      AND regexp_replace(telefono, '\\D', '', 'g') = ANY($2::text[])
    `,
    opts.empresaId,
    unique,
  );

  const map = new Map<string, string>();
  for (const r of rows) {
    const k = String((r as any).telefono_digits ?? '').trim();
    const v = String((r as any).nombre ?? '').trim();
    if (k && v && !map.has(k)) map.set(k, v);
  }
  return map;
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

function applyDefaultCountryCode(digits: string): string {
  const d = String(digits ?? '').replace(/\D+/g, '');
  if (!d) return d;

  if (d.length === 10) {
    const cc = String(env.EVOLUTION_DEFAULT_COUNTRY_CODE ?? '1').replace(/\D+/g, '') || '1';
    return `${cc}${d}`;
  }
  return d;
}

function normalizeOutboundPhone(raw: string): { phoneE164: string; waId: string } {
  const digits = digitsOnly(String(raw ?? ''));
  const normalized = applyDefaultCountryCode(digits);
  if (!normalized) throw new ApiError(400, 'Invalid phone');
  // Store WhatsApp id in the canonical JID format.
  return { phoneE164: normalized, waId: `${normalized}@s.whatsapp.net` };
}

async function createAndSendTextForChat(opts: {
  chatId: string;
  waId: string;
  phoneE164: string | null;
  text: string;
  skipEvolution: boolean;
  remoteMessageId: string | null;
  aiSuggestionId: string | null;
  aiSuggestedText: string | null;
  aiUsedKnowledge: string[] | null;
  empresaId: string;
}): Promise<any> {
  const createdAt = new Date();

  // ========================================================
  // GET INSTANCE CONFIG FOR THIS CHAT
  // ========================================================
  let instanciaId: string | null = null;
  let evolutionConfig: { baseUrl: string; apiKey: string; instanceName: string } | null = null;

  try {
    const chat = await prisma.crmChat.findUnique({
      where: { id: opts.chatId },
      select: { instancia_id: true },
    });

    if (chat?.instancia_id) {
      instanciaId = chat.instancia_id;
      const instances = await prisma.$queryRawUnsafe<any[]>(
        `SELECT nombre_instancia, evolution_base_url, evolution_api_key 
         FROM crm_instancias 
         WHERE id = $1 
         LIMIT 1`,
        instanciaId
      );

      if (instances.length > 0) {
        const inst = instances[0];
        evolutionConfig = {
          baseUrl: inst.evolution_base_url,
          apiKey: inst.evolution_api_key,
          instanceName: inst.nombre_instancia,
        };
      }
    }
  } catch (e: any) {
    console.error('[CRM] Error fetching instance config:', e?.message || e);
  }

  const pending = await prisma.crmChatMessage.create({
    data: {
      empresa_id: opts.empresaId,
      chat_id: opts.chatId,
      direction: 'out',
      message_type: 'text',
      text: opts.text.trim(),
      status: 'sent',
      timestamp: createdAt,
      // Link message to instance for audit
      instancia_id: instanciaId ?? null,
    },
  });

  try {
    if (opts.skipEvolution) {
      if (!opts.remoteMessageId || opts.remoteMessageId.trim().length === 0) {
        throw new ApiError(400, 'remoteMessageId is required when skipEvolution=true');
      }

      const updated = await prisma.crmChatMessage.update({
        where: { id: pending.id },
        data: {
          remote_message_id: opts.remoteMessageId.trim(),
          status: 'sent',
        },
      });

      await prisma.crmChat.update({
        where: { id: opts.chatId },
        data: {
          last_message_preview: opts.text.trim().slice(0, 180),
          last_message_at: createdAt,
        },
      });

      emitCrmEvent({ type: 'message.new', chatId: opts.chatId, messageId: updated.id });
      emitCrmEvent({ type: 'chat.updated', chatId: opts.chatId });

      return updated;
    }

    if (instanciaId && !evolutionConfig) {
      throw new ApiError(
        409,
        'No se encontr\u00f3 la configuraci\u00f3n de Evolution para la instancia de este chat.',
      );
    }

    const evo = evolutionConfig
      ? new EvolutionClient({
          baseUrl: evolutionConfig.baseUrl,
          apiKey: evolutionConfig.apiKey,
          instanceName: evolutionConfig.instanceName,
        })
      : new EvolutionClient();

    const send = await evo.sendText({
      toWaId: opts.waId,
      toPhone: opts.phoneE164 ?? undefined,
      text: opts.text.trim(),
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: pending.id },
      data: {
        remote_message_id: send.messageId,
        status: 'sent',
      },
    });

    if (
      opts.aiSuggestionId ||
      opts.aiSuggestedText ||
      (opts.aiUsedKnowledge && opts.aiUsedKnowledge.length)
    ) {
      if (await aiMessageAuditsTableExists()) {
        const auditId = randomUUID();
        await prisma.$executeRawUnsafe(
          `
          INSERT INTO ai_message_audits (id, chat_id, message_id, suggestion_id, suggested_text, final_text, used_knowledge)
          VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::text, $6::text, $7::jsonb)
          `,
          auditId,
          opts.chatId,
          updated.id,
          opts.aiSuggestionId,
          opts.aiSuggestedText,
          opts.text.trim(),
          JSON.stringify(opts.aiUsedKnowledge ?? []),
        );
      }
    }

    await prisma.crmChat.update({
      where: { id: opts.chatId },
      data: {
        last_message_preview: opts.text.trim().slice(0, 180),
        last_message_at: createdAt,
      },
    });

    emitCrmEvent({ type: 'message.new', chatId: opts.chatId, messageId: updated.id });
    emitCrmEvent({ type: 'chat.updated', chatId: opts.chatId });

    return updated;
  } catch (e: any) {
    console.error('[CRM] createAndSendTextForChat: Evolution send failed', {
      chatId: opts.chatId,
      waId: opts.waId,
      phone: opts.phoneE164,
      error: e?.message ?? String(e),
    });

    const updated = await prisma.crmChatMessage.update({
      where: { id: pending.id },
      data: {
        status: 'failed',
        error: e?.message ?? String(e),
      },
    });

    if (
      opts.aiSuggestionId ||
      opts.aiSuggestedText ||
      (opts.aiUsedKnowledge && opts.aiUsedKnowledge.length)
    ) {
      if (await aiMessageAuditsTableExists()) {
        const auditId = randomUUID();
        await prisma.$executeRawUnsafe(
          `
          INSERT INTO ai_message_audits (id, chat_id, message_id, suggestion_id, suggested_text, final_text, used_knowledge)
          VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::text, $6::text, $7::jsonb)
          `,
          auditId,
          opts.chatId,
          updated.id,
          opts.aiSuggestionId,
          opts.aiSuggestedText,
          opts.text.trim(),
          JSON.stringify(opts.aiUsedKnowledge ?? []),
        );
      }
    }

    emitCrmEvent({ type: 'message.new', chatId: opts.chatId, messageId: updated.id });

    return updated;
  }
}

function toChatApiItem(chat: any) {
  const waId = String(chat.wa_id ?? chat.waId ?? '');
  const phoneCandidate = chat.phone ?? phoneFromWaId(waId);
  const phoneE164 = toPhoneE164(phoneCandidate);

  const preferredName =
    (chat.customer_name && String(chat.customer_name).trim().length > 0
      ? String(chat.customer_name).trim()
      : null) ??
    (chat.display_name && String(chat.display_name).trim().length > 0
      ? String(chat.display_name).trim()
      : null);

  const important = Boolean(chat.important ?? chat.is_important ?? false);
  const followUp = Boolean(chat.follow_up ?? chat.followUp ?? false);
  const productId = chat.product_id ?? chat.productId ?? null;
  const internalNote = chat.internal_note ?? chat.note ?? null;
  const assignedUserId = chat.assigned_user_id ?? chat.assigned_to_user_id ?? null;

  const scheduledAt = chat.scheduled_at ?? chat.scheduledAt ?? null;
  const locationText = chat.location_text ?? chat.locationText ?? null;
  const assignedTechId = chat.assigned_tech_id ?? chat.assignedTechId ?? null;
  const serviceId = chat.service_id ?? chat.serviceId ?? null;
  const purchasedAt = chat.purchased_at ?? chat.purchasedAt ?? null;
  const activeClientMessagePending = Boolean(
    chat.active_client_message_pending ?? chat.activeClientMessagePending ?? false,
  );
  const postSaleState = chat.post_sale_state ?? chat.postSaleState ?? null;
  const vip = Boolean(chat.vip ?? false);
  const purchasesCount = typeof chat.purchases_count === 'number' ? chat.purchases_count : chat.purchasesCount ?? null;
  const totalSpent = typeof chat.total_spent !== 'undefined' ? chat.total_spent : chat.totalSpent ?? null;

  return {
    // canonical camelCase
    id: chat.id,
    waId,
    phoneE164,
    displayName: preferredName,
    lastMessageText: chat.last_message_preview ?? null,
    lastMessageAt: chat.last_message_at ?? null,
    unreadCount: chat.unread_count ?? 0,
    status: chat.status ?? 'primer_contacto',
    // preferred names per spec
    isImportant: important,
    followUp,
    productId,
    note: internalNote,
    assignedToUserId: assignedUserId,

    // buyflow/scheduling fields (camelCase)
    scheduledAt,
    locationText,
    assignedTechId,
    serviceId,
    purchasedAt,
    activeClientMessagePending,
    postSaleState,
    vip,
    purchasesCount,
    totalSpent,

    // backward compatible
    important,
    internalNote,

    // backward compatible snake_case
    wa_id: waId,
    phone: phoneE164,
    display_name: preferredName,
    last_message_preview: chat.last_message_preview ?? null,
    last_message_at: chat.last_message_at ?? null,
    unread_count: chat.unread_count ?? 0,
    created_at: chat.created_at ?? null,
    updated_at: chat.updated_at ?? null,
    product_id: productId,
    internal_note: internalNote,
    assigned_user_id: assignedUserId,
    is_important: important,
    follow_up: followUp,
    assigned_to_user_id: assignedUserId,
    scheduled_at: scheduledAt,
    location_text: locationText,
    assigned_tech_id: assignedTechId,
    service_id: serviceId,
    purchased_at: purchasedAt,
    active_client_message_pending: activeClientMessagePending,
    post_sale_state: postSaleState,
    purchases_count: purchasesCount,
    total_spent: totalSpent,
  };
}

function digitsOnlyPhone(value: string | null | undefined): string | null {
  if (!value) return null;
  const digits = String(value).replace(/\D/g, '');
  return digits.length >= 6 ? digits : null;
}

async function fetchVipStatsByPhoneDigits(params: {
  empresaId: string;
  phoneDigits: string[];
}): Promise<Map<string, { purchasesCount: number; totalSpent: number; vip: boolean }>> {
  const unique = Array.from(new Set(params.phoneDigits.filter(Boolean)));
  if (unique.length === 0) return new Map();

  const rows = await prisma.$queryRawUnsafe<
    { phone_digits: string; purchases_count: number; total_spent: string }[]
  >(
    `
    SELECT
      regexp_replace(customer_phone, '\\\\D', '', 'g') AS phone_digits,
      COUNT(*)::int AS purchases_count,
      COALESCE(SUM(amount), 0)::text AS total_spent
    FROM sales
    WHERE
      empresa_id = $1::uuid
      AND deleted = FALSE
      AND customer_phone IS NOT NULL
      AND regexp_replace(customer_phone, '\\\\D', '', 'g') = ANY($2::text[])
    GROUP BY 1
    `,
    params.empresaId,
    unique,
  );

  const map = new Map<string, { purchasesCount: number; totalSpent: number; vip: boolean }>();
  for (const r of rows) {
    const purchasesCount = Number(r.purchases_count ?? 0);
    const totalSpent = Number(r.total_spent ?? 0);
    const vip = purchasesCount > 3 || totalSpent >= 60000;
    map.set(String(r.phone_digits), { purchasesCount, totalSpent, vip });
  }
  return map;
}

export async function getChat(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findFirst({ where: { id: chatId, empresa_id } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  // Enrich with meta if available.
  let merged: any = chat;
  try {
    const metaMap = await fetchChatMeta([chatId]);
    const meta = metaMap.get(chatId);
    if (meta) merged = { ...chat, ...meta };
  } catch {
    // ignore meta errors
  }

  try {
    const waId = String(merged.wa_id ?? '');
    const candidate = merged.phone ?? phoneFromWaId(waId);
    const phoneE164 = candidate ? toPhoneE164(candidate) : null;
    if (phoneE164) {
      const map = await fetchCustomerNamesByPhones({ empresaId: empresa_id, phoneDigits: [phoneE164] });
      merged = { ...merged, customer_name: map.get(phoneE164) ?? null };
    }
  } catch {
    // ignore customer lookup errors
  }

  res.json({ item: toChatApiItem(merged) });
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

let crmChatMetaExistsCache: boolean | null = null;
let crmChatMetaExistsAtMs = 0;
async function crmChatMetaExists(): Promise<boolean> {
  const now = Date.now();
  if (crmChatMetaExistsCache != null && now - crmChatMetaExistsAtMs < 60_000) {
    return crmChatMetaExistsCache;
  }

  try {
    // Avoid `to_regclass()` because Prisma can fail to deserialize Postgres `regclass`.
    const rows = await prisma.$queryRawUnsafe<{ count: number }[]>(
      `
        SELECT COUNT(*)::int as count
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
      `,
      'crm_chat_meta',
    );

    const exists = (rows?.[0]?.count ?? 0) > 0;
    crmChatMetaExistsCache = exists;
    crmChatMetaExistsAtMs = now;
    return exists;
  } catch {
    // If the existence probe fails, be optimistic and let later queries decide.
    // (Missing-table errors are handled where relevant.)
    crmChatMetaExistsCache = true;
    crmChatMetaExistsAtMs = now;
    return true;
  }
}

async function fetchChatMeta(chatIds: string[]): Promise<Map<string, any>> {
  const map = new Map<string, any>();
  if (chatIds.length === 0) return map;

  if (!(await crmChatMetaExists())) return map;

  // Safe, parameterized query.
  let rows: any[] = [];
  try {
    rows = await prisma.$queryRawUnsafe<any[]>(
      `
        SELECT chat_id, important, follow_up, product_id, internal_note, assigned_user_id
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
    follow_up?: boolean;
    product_id?: string | null;
    internal_note?: string | null;
    assigned_user_id?: string | null;
  },
): Promise<void> {
  if (!(await crmChatMetaExists())) return;

  const hasImportant = typeof data.important !== 'undefined';
  const hasFollowUp = typeof data.follow_up !== 'undefined';
  const hasProduct = typeof data.product_id !== 'undefined';
  const hasNote = typeof data.internal_note !== 'undefined';
  const hasAssigned = typeof data.assigned_user_id !== 'undefined';

  const important = hasImportant ? (data.important as boolean) : null;
  const followUp = hasFollowUp ? (data.follow_up as boolean) : null;
  const productId = hasProduct ? (data.product_id as any) : null;
  const internalNote = hasNote ? (data.internal_note as any) : null;
  const assignedUserId = hasAssigned ? (data.assigned_user_id as any) : null;

  try {
    await prisma.$executeRawUnsafe(
      `
        INSERT INTO crm_chat_meta (chat_id, important, follow_up, product_id, internal_note, assigned_user_id, updated_at)
        VALUES (
          $1::uuid,
          COALESCE($2::boolean, FALSE),
          COALESCE($3::boolean, FALSE),
          CASE WHEN $4::boolean THEN $5::text ELSE NULL END,
          CASE WHEN $6::boolean THEN $7::text ELSE NULL END,
          CASE WHEN $8::boolean THEN $9::uuid ELSE NULL END,
          now()
        )
        ON CONFLICT (chat_id)
        DO UPDATE SET
          important = COALESCE($2::boolean, crm_chat_meta.important),
          follow_up = COALESCE($3::boolean, crm_chat_meta.follow_up),
          product_id = CASE WHEN $4::boolean THEN $5::text ELSE crm_chat_meta.product_id END,
          internal_note = CASE WHEN $6::boolean THEN $7::text ELSE crm_chat_meta.internal_note END,
          assigned_user_id = CASE WHEN $8::boolean THEN $9::uuid ELSE crm_chat_meta.assigned_user_id END,
          updated_at = now()
      `,
      chatId,
      important,
      followUp,
      hasProduct,
      productId,
      hasNote,
      internalNote,
      hasAssigned,
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

  return {
    // canonical camelCase
    id: m.id,
    chatId: m.chat_id,
    direction,
    fromMe,
    type,
    messageType: type,
    text: m.text ?? null,
    mediaUrl: m.media_url ?? null,
    status: m.status ?? 'received',
    createdAt,

    // backward compatible snake_case
    chat_id: m.chat_id,
    message_type: m.message_type ?? type,
    media_url: m.media_url ?? null,
    remote_message_id: m.remote_message_id ?? null,
    quoted_message_id: m.quoted_message_id ?? null,
    timestamp: m.timestamp ?? null,
    created_at: m.created_at ?? null,
    error: m.error ?? null,
  };
}

export async function deleteChatMessage(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = String(req.params.chatId ?? '').trim();
  const messageId = String(req.params.messageId ?? '').trim();

  if (!chatId) throw new ApiError(400, 'chatId is required');
  if (!messageId) throw new ApiError(400, 'messageId is required');

  const parsed = crmDeleteChatMessageSchema.safeParse(req.body ?? {});
  if (!parsed.success) throw new ApiError(400, 'Invalid body', parsed.error.flatten());

  const msg = await prisma.crmChatMessage.findFirst({
    where: { id: messageId, chat_id: chatId },
  });
  if (!msg) throw new ApiError(404, 'Message not found');

  if (String(msg.direction ?? 'in') !== 'out') {
    throw new ApiError(403, 'Only outbound messages can be deleted');
  }

  const status = String(msg.status ?? '').trim().toLowerCase();
  if (status === 'deleted') {
    res.status(200).json({ item: toMessageApiItem(msg) });
    return;
  }

  const chat = await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const remoteMessageId = (msg.remote_message_id ?? '').trim();
  if (!remoteMessageId) {
    throw new ApiError(409, 'Message has no remote_message_id; cannot delete on WhatsApp');
  }

  const evo = await getEvolutionClientForChat(chatId);
  try {
    await evo.deleteMessage({
      remoteMessageId,
      toWaId: String(chat.wa_id ?? ''),
      toPhone: chat.phone ?? undefined,
    });
  } catch (e: any) {
    console.error('[CRM] deleteChatMessage: Evolution delete failed', {
      chatId,
      messageId,
      remoteMessageId,
      error: e?.message ?? String(e),
    });
    throw new ApiError(502, 'Evolution delete failed', { error: e?.message ?? String(e) });
  }

  const updated = await prisma.crmChatMessage.update({
    where: { id: msg.id },
    data: {
      status: 'deleted',
      text: null,
      error: null,
    },
  });

  // If the deleted message was the last preview, keep the UI consistent.
  if (chat.last_message_at && updated.timestamp && chat.last_message_at.getTime() === updated.timestamp.getTime()) {
    await prisma.crmChat.update({
      where: { id: chatId },
      data: { last_message_preview: 'Mensaje eliminado' },
    });
  }

  emitCrmEvent({ type: 'message.updated', chatId, messageId: updated.id });
  emitCrmEvent({ type: 'chat.updated', chatId });

  res.status(200).json({ item: toMessageApiItem(updated) });
}

export async function editChatMessage(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = String(req.params.chatId ?? '').trim();
  const messageId = String(req.params.messageId ?? '').trim();

  if (!chatId) throw new ApiError(400, 'chatId is required');
  if (!messageId) throw new ApiError(400, 'messageId is required');

  const parsed = crmEditChatMessageSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid body', parsed.error.flatten());
  const newText = parsed.data.text.trim();

  const msg = await prisma.crmChatMessage.findFirst({
    where: { id: messageId, chat_id: chatId },
  });
  if (!msg) throw new ApiError(404, 'Message not found');

  if (String(msg.direction ?? 'in') !== 'out') {
    throw new ApiError(403, 'Only outbound messages can be edited');
  }

  const type = String(msg.message_type ?? 'text').toLowerCase();
  if (type !== 'text') {
    throw new ApiError(400, 'Only text messages can be edited');
  }

  const status = String(msg.status ?? '').trim().toLowerCase();
  if (status === 'deleted') {
    throw new ApiError(409, 'Deleted messages cannot be edited');
  }

  const chat = await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const remoteMessageId = (msg.remote_message_id ?? '').trim();
  if (!remoteMessageId) {
    throw new ApiError(409, 'Message has no remote_message_id; cannot edit on WhatsApp');
  }

  const evo = await getEvolutionClientForChat(chatId);
  try {
    await evo.editTextMessage({
      remoteMessageId,
      toWaId: String(chat.wa_id ?? ''),
      toPhone: chat.phone ?? undefined,
      text: newText,
    });
  } catch (e: any) {
    console.error('[CRM] editChatMessage: Evolution edit failed', {
      chatId,
      messageId,
      remoteMessageId,
      error: e?.message ?? String(e),
    });
    throw new ApiError(502, 'Evolution edit failed', { error: e?.message ?? String(e) });
  }

  const updated = await prisma.crmChatMessage.update({
    where: { id: msg.id },
    data: { text: newText },
  });

  // If it was the last preview, update preview text.
  if (chat.last_message_at && updated.timestamp && chat.last_message_at.getTime() === updated.timestamp.getTime()) {
    await prisma.crmChat.update({
      where: { id: chatId },
      data: { last_message_preview: newText.slice(0, 180) },
    });
  }

  emitCrmEvent({ type: 'message.updated', chatId, messageId: updated.id });
  emitCrmEvent({ type: 'chat.updated', chatId });

  res.status(200).json({ item: toMessageApiItem(updated) });
}

export async function listChats(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const parsed = crmChatsListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, status, productId, product_id, page, limit } = parsed.data;
  const skip = (page - 1) * limit;

  // ========================================================
  // INSTANCE FILTERING - Get user's active instance
  // ========================================================
  const userInstanceId = await getUserInstanceIdForLists(userId);

  // If user has no active instance, return empty list
  if (!userInstanceId) {
    res.json({ items: [], total: 0, page, limit });
    return;
  }

  // "COMPRO" (purchased) and "eliminado" are excluded from the normal CRM list.
  const where: any = {
    empresa_id,
    status: { notIn: ['compro', 'eliminado'] },
    // CRITICAL: Only show chats from user's instance
    instancia_id: userInstanceId,
  };

  if (status && status.trim().length > 0) {
    const s = status.trim();
    // UX: treat "pendiente" as including "primer_contacto".
    // This prevents users from seeing an empty list when most chats are still in first-contact.
    if (s === 'pendiente') {
      where.AND = [...(where.AND ?? []), { status: { in: ['pendiente', 'primer_contacto'] } }];
    } else if (s === 'garantia' || s === 'en_garantia') {
      // Backward compatibility: some records use en_garantia.
      where.AND = [
        ...(where.AND ?? []),
        { status: { in: ['garantia', 'en_garantia'] } },
      ];
    } else {
      // Never allow purchased/deleted chats into the normal list even if requested.
      where.AND = [...(where.AND ?? []), { status: s }];
    }
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
    // If meta table doesn't exist, product filtering can't be applied.
    // Don't hard-empty the list; just ignore the product filter.
    if (!(await crmChatMetaExists())) {
      // proceed without adding where.id constraint
    } else {

      let rows: { chat_id: string }[] = [];
      try {
        rows = await prisma.$queryRawUnsafe<{ chat_id: string }[]>(
          `SELECT chat_id FROM crm_chat_meta WHERE product_id = $1::text`,
          effectiveProductId,
        );
      } catch (e) {
        // If meta table doesn't exist, treat as no product filter instead of empty.
        if (isMissingTableError(e, 'crm_chat_meta')) {
          rows = [];
        } else {
          throw e;
        }
      }
      const ids = rows.map((r) => String(r.chat_id));
      // If no matches, return empty quickly.
      if (ids.length === 0) {
        res.json({ items: [], total: 0, page, limit });
        return;
      }
      where.id = { in: ids };
    }
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

  const phoneDigits = items
    .map((c: any) => {
      const waId = String(c.wa_id ?? '');
      const candidate = c.phone ?? phoneFromWaId(waId);
      return candidate ? toPhoneE164(candidate) : null;
    })
    .filter((p: any) => typeof p === 'string' && p.length > 0) as string[];

  const customerNameByPhone = await fetchCustomerNamesByPhones({
    empresaId: empresa_id,
    phoneDigits,
  });

  const metaByChatId = await fetchChatMeta(items.map((c: any) => c.id));
  const merged = items.map((c: any) => {
    const waId = String(c.wa_id ?? '');
    const candidate = c.phone ?? phoneFromWaId(waId);
    const phoneE164 = candidate ? toPhoneE164(candidate) : null;
    const customer_name = phoneE164 ? customerNameByPhone.get(phoneE164) ?? null : null;
    return { ...c, customer_name, ...(metaByChatId.get(c.id) ?? {}) };
  });
  const mapped = merged.map(toChatApiItem);
  res.json({ items: mapped, total, page, limit });
}

/**
 * NEW ENDPOINT: List purchased clients (CRM chats with status = "compro")
 * This replaces the old "customers" logic - now "Clients" screen shows only CRM chats with "compro" status
 */
export async function listPurchasedClients(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const parsed = crmChatsListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, page, limit } = parsed.data;
  const skip = (page - 1) * limit;

  const userInstanceId = await getUserInstanceIdForLists(userId);
  if (!userInstanceId) {
    res.json({ items: [], total: 0, page, limit });
    return;
  }

  // STRICT FILTER: Only chats with status = "compro"
  const where: any = {
    empresa_id,
    status: 'compro',
    instancia_id: userInstanceId,
  };

  if (search && search.trim().length > 0) {
    const q = search.trim();
    where.OR = [
      { wa_id: { contains: q, mode: 'insensitive' } },
      { phone: { contains: q, mode: 'insensitive' } },
      { display_name: { contains: q, mode: 'insensitive' } },
      { last_message_preview: { contains: q, mode: 'insensitive' } },
    ];
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

  const phoneDigitsForCustomers = items
    .map((c: any) => {
      const waId = String(c.wa_id ?? '');
      const candidate = c.phone ?? phoneFromWaId(waId);
      return candidate ? toPhoneE164(candidate) : null;
    })
    .filter((p: any) => typeof p === 'string' && p.length > 0) as string[];
  const customerNameByPhone = await fetchCustomerNamesByPhones({
    empresaId: empresa_id,
    phoneDigits: phoneDigitsForCustomers,
  });

  // Enrich with meta if available
  const metaByChatId = await fetchChatMeta(items.map((c: any) => c.id));
  const merged = items.map((c: any) => {
    const waId = String(c.wa_id ?? '');
    const candidate = c.phone ?? phoneFromWaId(waId);
    const phoneE164 = candidate ? toPhoneE164(candidate) : null;
    const customer_name = phoneE164 ? customerNameByPhone.get(phoneE164) ?? null : null;
    return { ...c, customer_name, ...(metaByChatId.get(c.id) ?? {}) };
  });
  
  // Map to client format (same as chat format but clearly for "purchased clients")
  const mappedBase = merged.map(toChatApiItem);
  const phoneDigits = mappedBase
    .map((i: any) => digitsOnlyPhone(i.phoneE164))
    .filter((v: any): v is string => Boolean(v));
  const vipStats = await fetchVipStatsByPhoneDigits({ empresaId: empresa_id, phoneDigits });

  const mapped = mappedBase.map((i: any) => {
    const d = digitsOnlyPhone(i.phoneE164);
    const stats = d ? vipStats.get(d) : null;
    const vip = stats?.vip ?? false;
    const purchasesCount = stats?.purchasesCount ?? 0;
    const totalSpent = stats?.totalSpent ?? 0;
    const effectivePostSaleState = vip ? 'VIP' : (i.postSaleState ?? 'NORMAL');

    return {
      ...i,
      vip,
      purchasesCount,
      totalSpent,
      postSaleState: effectivePostSaleState,
      purchases_count: purchasesCount,
      total_spent: totalSpent,
      post_sale_state: effectivePostSaleState,
    };
  });
  
  res.json({ 
    items: mapped, 
    total, 
    page, 
    limit,
    message: total === 0 ? "No purchased clients yet. Mark a CRM chat as 'Compró' to see it here." : null
  });
}

// ===========
// Bought flow
// ===========

// GET /api/crm/chats/bought
export async function listBoughtChats(req: Request, res: Response) {
  return listPurchasedClients(req, res);
}

// GET /api/crm/chats/bought/inbox
export async function listBoughtInbox(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const parsed = crmChatsListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, page, limit } = parsed.data;
  const skip = (page - 1) * limit;

  const userInstanceId = await getUserInstanceIdForLists(userId);
  if (!userInstanceId) {
    res.json({ items: [], total: 0, page, limit });
    return;
  }

  const where: any = {
    empresa_id,
    status: 'compro',
    active_client_message_pending: true,
    instancia_id: userInstanceId,
  };

  if (search && search.trim().length > 0) {
    const q = search.trim();
    where.OR = [
      { wa_id: { contains: q, mode: 'insensitive' } },
      { phone: { contains: q, mode: 'insensitive' } },
      { display_name: { contains: q, mode: 'insensitive' } },
      { last_message_preview: { contains: q, mode: 'insensitive' } },
    ];
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

  const phoneDigitsForCustomers = items
    .map((c: any) => {
      const waId = String(c.wa_id ?? '');
      const candidate = c.phone ?? phoneFromWaId(waId);
      return candidate ? toPhoneE164(candidate) : null;
    })
    .filter((p: any) => typeof p === 'string' && p.length > 0) as string[];
  const customerNameByPhone = await fetchCustomerNamesByPhones({
    empresaId: empresa_id,
    phoneDigits: phoneDigitsForCustomers,
  });

  const metaByChatId = await fetchChatMeta(items.map((c: any) => c.id));
  const merged = items.map((c: any) => {
    const waId = String(c.wa_id ?? '');
    const candidate = c.phone ?? phoneFromWaId(waId);
    const phoneE164 = candidate ? toPhoneE164(candidate) : null;
    const customer_name = phoneE164 ? customerNameByPhone.get(phoneE164) ?? null : null;
    return { ...c, customer_name, ...(metaByChatId.get(c.id) ?? {}) };
  });

  const mappedBase = merged.map(toChatApiItem);
  const phoneDigits = mappedBase
    .map((i: any) => digitsOnlyPhone(i.phoneE164))
    .filter((v: any): v is string => Boolean(v));
  const vipStats = await fetchVipStatsByPhoneDigits({ empresaId: empresa_id, phoneDigits });

  const mapped = mappedBase.map((i: any) => {
    const d = digitsOnlyPhone(i.phoneE164);
    const stats = d ? vipStats.get(d) : null;
    const vip = stats?.vip ?? false;
    const purchasesCount = stats?.purchasesCount ?? 0;
    const totalSpent = stats?.totalSpent ?? 0;
    const effectivePostSaleState = vip ? 'VIP' : (i.postSaleState ?? 'NORMAL');

    return {
      ...i,
      vip,
      purchasesCount,
      totalSpent,
      postSaleState: effectivePostSaleState,
      purchases_count: purchasesCount,
      total_spent: totalSpent,
      post_sale_state: effectivePostSaleState,
    };
  });

  res.json({ items: mapped, total, page, limit });
}

// PATCH /api/crm/chats/:chatId/bought/inbox/clear
export async function clearBoughtInboxFlag(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const chat = await prisma.crmChat.findFirst({
    where: { id: chatId, empresa_id, status: 'compro' },
    select: { id: true },
  });
  if (!chat) throw new ApiError(404, 'Purchased chat not found');

  const updated = await prisma.crmChat.update({
    where: { id: chatId },
    data: { active_client_message_pending: false },
  });

  emitCrmEvent({ type: 'chat.updated', chatId });
  res.json({ item: toChatApiItem(updated) });
}

// PATCH /api/crm/chats/:chatId/post-sale-state
export async function patchPostSaleState(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  const parsed = crmPostSaleStateSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const chat = await prisma.crmChat.findFirst({
    where: { id: chatId, empresa_id },
    select: { id: true, status: true },
  });
  if (!chat) throw new ApiError(404, 'Chat not found');

  if (chat.status !== 'compro') {
    throw new ApiError(422, 'post_sale_state can only be updated for purchased clients (status=compro)');
  }

  const updated = await prisma.crmChat.update({
    where: { id: chatId },
    data: { post_sale_state: parsed.data.state as any },
  });

  emitCrmEvent({ type: 'chat.updated', chatId });
  res.json({ item: toChatApiItem(updated) });
}

/**
 * Get single purchased client details (CRM chat with status = "compro")
 */
export async function getPurchasedClient(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const clientId = req.params.clientId;

  const chat = await prisma.crmChat.findFirst({ 
    where: { 
      id: clientId,
      empresa_id,
      status: 'compro'  // STRICT: Only purchased clients
    } 
  });
  
  if (!chat) {
    throw new ApiError(404, 'Purchased client not found or not marked as "compro"');
  }

  // Enrich with meta if available
  let merged: any = chat;
  try {
    const metaMap = await fetchChatMeta([clientId]);
    const meta = metaMap.get(clientId);
    if (meta) merged = { ...chat, ...meta };
  } catch {
    // ignore meta errors
  }

  res.json({ item: toChatApiItem(merged) });
}

/**
 * Update purchased client (CRM chat with status = "compro")
 * Allows editing: display_name, phone, internal_note, assigned_user_id, product_id
 */
export async function updatePurchasedClient(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const clientId = req.params.clientId;
  
  // Verify it's a purchased client
  const existing = await prisma.crmChat.findFirst({
    where: { 
      id: clientId,
      empresa_id,
      status: 'compro'  // STRICT: Only purchased clients
    }
  });

  if (!existing) {
    throw new ApiError(404, 'Purchased client not found or not marked as "compro"');
  }

  const updates: any = {};
  const metaUpdates: any = {};

  // Extract editable fields from request body
  if (req.body.displayName !== undefined) {
    updates.display_name = String(req.body.displayName || '').trim() || null;
  }
  if (req.body.display_name !== undefined) {
    updates.display_name = String(req.body.display_name || '').trim() || null;
  }
  if (req.body.phone !== undefined) {
    updates.phone = String(req.body.phone || '').trim() || null;
  }
  if (req.body.note !== undefined || req.body.internal_note !== undefined) {
    metaUpdates.internal_note = String(req.body.note || req.body.internal_note || '').trim() || null;
  }
  if (req.body.assignedUserId !== undefined || req.body.assigned_user_id !== undefined) {
    metaUpdates.assigned_user_id = String(req.body.assignedUserId || req.body.assigned_user_id || '').trim() || null;
  }
  if (req.body.productId !== undefined || req.body.product_id !== undefined) {
    metaUpdates.product_id = String(req.body.productId || req.body.product_id || '').trim() || null;
  }

  // Update main chat record
  if (Object.keys(updates).length > 0) {
    await prisma.crmChat.update({
      where: { id: clientId },
      data: updates
    });
  }

  // Update meta if needed
  if (Object.keys(metaUpdates).length > 0) {
    await upsertChatMeta(clientId, metaUpdates);
  }

  // Return updated record
  const updated = await prisma.crmChat.findUnique({ where: { id: clientId } });
  let merged: any = updated;
  try {
    const metaMap = await fetchChatMeta([clientId]);
    const meta = metaMap.get(clientId);
    if (meta) merged = { ...updated, ...meta };
  } catch {
    // ignore meta errors
  }

  emitCrmEvent({ type: 'chat.updated', chatId: clientId });

  res.json({ item: toChatApiItem(merged) });
}

/**
 * Delete purchased client (soft delete or hard delete)
 * This changes status from "compro" to "eliminado" (soft delete)
 * Or actually deletes the record if hardDelete=true
 */
export async function deletePurchasedClient(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const clientId = req.params.clientId;
  const hardDelete = req.query.hardDelete === 'true';

  // Verify it's a purchased client
  const existing = await prisma.crmChat.findFirst({
    where: { 
      id: clientId,
      empresa_id,
      status: 'compro'  // STRICT: Only purchased clients
    }
  });

  if (!existing) {
    throw new ApiError(404, 'Purchased client not found or not marked as "compro"');
  }

  if (hardDelete) {
    // HARD DELETE: Actually remove the record and all messages
    // Warning: This will break foreign key relationships with messages
    await prisma.crmChatMessage.deleteMany({ where: { chat_id: clientId } });
    
    // Also delete meta if exists
    try {
      if (await crmChatMetaExists()) {
        await prisma.$executeRawUnsafe(
          `DELETE FROM crm_chat_meta WHERE chat_id = $1::uuid`,
          clientId
        );
      }
    } catch {
      // ignore meta errors
    }

    await prisma.crmChat.delete({ where: { id: clientId } });
    
    emitCrmEvent({ type: 'chat.deleted', chatId: clientId });
    
    res.json({ message: 'Client permanently deleted' });
  } else {
    // SOFT DELETE: Change status to "eliminado" 
    const updated = await prisma.crmChat.update({
      where: { id: clientId },
      data: { status: 'eliminado' }
    });

    emitCrmEvent({ type: 'chat.updated', chatId: clientId });

    res.json({ 
      item: toChatApiItem(updated),
      message: 'Client marked as deleted (soft delete). It will no longer appear in purchased clients list.'
    });
  }
}

/**
 * Delete CRM chat (admin-only via route middleware).
 * Default behavior is HARD DELETE (removes chat + messages; unlinks operations jobs).
 *
 * Query:
 *  - hardDelete=false => soft delete by setting status=eliminado
 */
export async function deleteChat(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const chatId = req.params.chatId;
  const hardDelete = req.query.hardDelete !== 'false';

  const existing = await prisma.crmChat.findFirst({
    where: { id: chatId, empresa_id },
  });
  if (!existing) {
    throw new ApiError(404, 'Chat not found');
  }

  if (!hardDelete) {
    const updated = await prisma.crmChat.update({
      where: { id: chatId },
      data: { status: 'eliminado' },
    });
    emitCrmEvent({ type: 'chat.updated', chatId });
    res.json({ item: toChatApiItem(updated), message: 'Chat marked as deleted (soft delete).' });
    return;
  }

  await prisma.$transaction(async (tx) => {
    await tx.crmChatMessage.deleteMany({ where: { chat_id: chatId } });

    // Unlink operational jobs (DB relation is SetNull, but make it explicit).
    await tx.operationsJob.updateMany({
      where: { crm_chat_id: chatId },
      data: { crm_chat_id: null },
    });

    // Best-effort delete of meta row (if table exists).
    try {
      if (await crmChatMetaExists()) {
        await tx.$executeRawUnsafe(`DELETE FROM crm_chat_meta WHERE chat_id = $1::uuid`, chatId);
      }
    } catch {
      // ignore meta errors
    }

    await tx.crmChat.delete({ where: { id: chatId } });
  });

  emitCrmEvent({ type: 'chat.deleted', chatId });
  res.json({ ok: true });
}

export async function patchChat(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');
  if (chat.empresa_id !== empresa_id) throw new ApiError(403, 'Forbidden');

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  if (await isChatLockedByOperations(chatId)) {
    throw new ApiError(
      422,
      'Este chat ya fue pasado a Operaciones. En CRM solo puedes enviar mensajes al cliente.',
    );
  }

  const parsed = crmChatPatchSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const {
    display_name,
    displayName,
    status,
    important,
    follow_up,
    product_id,
    internal_note,
    assigned_user_id,
    isImportant,
    followUp,
    productId,
    note,
    assignedToUserId,
  } = parsed.data;

  const effectiveDisplayName =
    typeof displayName !== 'undefined' ? displayName : display_name;
  const effectiveImportant = typeof isImportant !== 'undefined' ? isImportant : important;
  const effectiveFollowUp = typeof followUp !== 'undefined' ? followUp : follow_up;
  const effectiveProductId = typeof productId !== 'undefined' ? productId : product_id;
  const effectiveNote = typeof note !== 'undefined' ? note : internal_note;
  const effectiveAssigned =
    typeof assignedToUserId !== 'undefined' ? assignedToUserId : assigned_user_id;

  const chatUpdates: Record<string, unknown> = {};
  if (status && status.trim().length > 0) {
    const nextStatus = normalizeCrmChatStatus(status.trim());
    if (String(chat.status ?? '').trim() === 'compro' && nextStatus !== 'compro') {
      throw new ApiError(422, 'COMPRO is irreversible and cannot be reverted');
    }
    chatUpdates.status = nextStatus;
    if (nextStatus === 'compro' && String(chat.status ?? '').trim() !== 'compro') {
      chatUpdates.purchased_at = new Date();
      chatUpdates.active_client_message_pending = false;
    }
  }
  if (typeof effectiveDisplayName !== 'undefined') {
    const v = (effectiveDisplayName ?? '').toString().trim();
    chatUpdates.display_name = v.length === 0 ? null : v;
  }
  if (Object.keys(chatUpdates).length > 0) {
    await prisma.crmChat.update({
      where: { id: chatId },
      data: chatUpdates,
    });
  }

  // Only upsert meta if any meta fields are provided.
  const hasMeta =
    typeof effectiveImportant !== 'undefined' ||
    typeof effectiveFollowUp !== 'undefined' ||
    typeof effectiveProductId !== 'undefined' ||
    typeof effectiveNote !== 'undefined' ||
    typeof effectiveAssigned !== 'undefined';
  if (hasMeta) {
    await upsertChatMeta(chatId, {
      important: effectiveImportant,
      follow_up: effectiveFollowUp,
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

function normalizePriority(raw?: string | null): 'low' | 'normal' | 'high' | null {
  if (!raw) return null;
  const v = String(raw).trim();
  if (!v) return null;
  if (v === 'BAJA') return 'low';
  if (v === 'MEDIA') return 'normal';
  if (v === 'ALTA') return 'high';
  if (v === 'low' || v === 'normal' || v === 'high') return v;
  return null;
}

function normalizeCrmChatStatus(raw: string): string {
  const s = String(raw ?? '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '');
  if (!s) return s;
  // Accept aliases: users might send "agendado"/"reservado" for scheduling.
  if (s === 'agendado' || s === 'reservado') return 'servicio_reservado';
  if (s === 'instalacion') return 'instalacion';
  if (s === 'mantenimiento') return 'mantenimiento';
  return s;
}

function parseNumberOrNull(value: unknown): number | null {
  if (value === null || typeof value === 'undefined') return null;
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  const s = String(value).trim();
  if (!s) return null;
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

function needsOperationsTask(status: string): boolean {
  return (
    status === 'reserva' ||
    status === 'por_levantamiento' ||
    status === 'servicio_reservado' ||
    status === 'instalacion' ||
    status === 'mantenimiento' ||
    status === 'solucion_garantia' ||
    status === 'en_garantia' ||
    status === 'garantia' ||
    status === 'con_problema'
  );
}

function mapCrmStatusToTaskType(
  status: string,
): { taskType: 'LEVANTAMIENTO' | 'SERVICIO_RESERVADO' | 'GARANTIA' | 'INSTALACION'; initialJobStatus: string; serviceTypeLabel?: string } | null {
  if (status === 'reserva') {
    // Treat RESERVA as an operational scheduled service so it appears in Operaciones/Agenda.
    return { taskType: 'SERVICIO_RESERVADO', initialJobStatus: 'scheduled' };
  }
  if (status === 'por_levantamiento') {
    return { taskType: 'LEVANTAMIENTO', initialJobStatus: 'pending_survey' };
  }
  if (status === 'servicio_reservado') {
    return { taskType: 'SERVICIO_RESERVADO', initialJobStatus: 'scheduled' };
  }
  if (status === 'instalacion') {
    return { taskType: 'INSTALACION', initialJobStatus: 'scheduled', serviceTypeLabel: 'Instalación' };
  }
  if (status === 'mantenimiento') {
    // Keep DB enum unchanged by mapping to SERVICIO_RESERVADO,
    // but label the job so the app can show it under the Mantenimiento tab.
    return { taskType: 'SERVICIO_RESERVADO', initialJobStatus: 'scheduled', serviceTypeLabel: 'Mantenimiento' };
  }
  if (
    status === 'solucion_garantia' ||
    status === 'en_garantia' ||
    status === 'garantia' ||
    status === 'con_problema'
  ) {
    return { taskType: 'GARANTIA', initialJobStatus: 'warranty_pending' };
  }
  return null;
}

function parseScheduledAt(value: string | null): Date | null {
  if (!value) return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function formatTimeHHmm(d: Date): string {
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${hh}:${mm}`;
}

function dateOnlyUtc(d: Date): Date {
  return new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0));
}

async function ensureCustomerForChat(params: {
  tx: any;
  empresaId: string;
  chat: { id: string; wa_id: string; phone: string | null; display_name: string | null };
  phoneOverride?: string | null;
  addressText?: string | null;
}): Promise<{ id: string; nombre: string; telefono: string; direccion: string | null; ubicacion_mapa: string | null }> {
  const { tx, empresaId, chat, phoneOverride, addressText } = params;

  const phoneCandidate = chat.phone ?? phoneOverride ?? phoneFromWaId(String(chat.wa_id ?? ''));
  const telefono = toPhoneE164(phoneCandidate);
  if (!telefono) throw new ApiError(400, 'Chat has no valid phone; cannot create operations task', undefined, 'INVALID_PHONE');

  const name =
    chat.display_name && chat.display_name.trim().length > 0
      ? chat.display_name.trim()
      : `Cliente WhatsApp ${telefono}`;

  const existing = await tx.customer.findFirst({
    where: { empresa_id: empresaId, telefono, deleted_at: null },
  });
  if (existing) {
    const addr = String(addressText ?? '').trim();
    if (addr) {
      const hasAddress =
        (existing.direccion && String(existing.direccion).trim().length > 0) ||
        (existing.ubicacion_mapa && String(existing.ubicacion_mapa).trim().length > 0);

      if (!hasAddress) {
        return await tx.customer.update({
          where: { id: existing.id },
          data: { direccion: addr },
        });
      }
    }
    return existing;
  }

  const created = await tx.customer.create({
    data: {
      empresa_id: empresaId,
      nombre: name,
      telefono,
      origen: 'whatsapp',
      ...(addressText && String(addressText).trim().length > 0 ? { direccion: String(addressText).trim() } : {}),
    },
  });
  return created;
}

export async function postChatStatus(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const user_id = actorUserId(req);
  const chatId = req.params.chatId;

  const chat = await prisma.crmChat.findUnique({ where: { id: chatId } });
  if (!chat) throw new ApiError(404, 'Chat not found');
  if (chat.empresa_id !== empresa_id) throw new ApiError(403, 'Forbidden');

  await requireChatAccess({ empresaId: empresa_id, userId: user_id, chatId });

  // Once a job exists in Operaciones, CRM becomes read-only (except messaging).
  if (await isChatLockedByOperations(chatId)) {
    throw new ApiError(
      422,
      'Este chat ya fue pasado a Operaciones. En CRM solo puedes enviar mensajes al cliente.',
    );
  }

  const parsed = crmChatStatusSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;
  const nextStatus = normalizeCrmChatStatus(body.status);

  const phoneOverride =
    typeof (body as any).phone !== 'undefined'
      ? (body as any).phone
      : typeof (body as any).phone_e164 !== 'undefined'
        ? (body as any).phone_e164
        : typeof (body as any).phoneE164 !== 'undefined'
          ? (body as any).phoneE164
          : null;

  const scheduledAt =
    typeof body.scheduledAt !== 'undefined'
      ? body.scheduledAt
      : typeof body.scheduled_at !== 'undefined'
        ? body.scheduled_at
        : null;
  const address =
    typeof (body as any).address !== 'undefined'
      ? (body as any).address
      : typeof (body as any).direccion !== 'undefined'
        ? (body as any).direccion
        : null;
  const locationText =
    typeof (body as any).locationText !== 'undefined'
      ? (body as any).locationText
      : typeof (body as any).location_text !== 'undefined'
        ? (body as any).location_text
        : null;
  const note =
    typeof body.note !== 'undefined'
      ? body.note
      : typeof body.notes !== 'undefined'
        ? body.notes
        : null;
  const productId =
    typeof body.productId !== 'undefined'
      ? body.productId
      : typeof body.product_id !== 'undefined'
        ? body.product_id
        : null;
  const serviceId =
    typeof body.serviceId !== 'undefined'
      ? body.serviceId
      : typeof body.service_id !== 'undefined'
        ? body.service_id
        : null;
  const assignedTechnicianId =
    typeof body.assignedTechnicianId !== 'undefined'
      ? body.assignedTechnicianId
      : typeof body.assigned_technician_id !== 'undefined'
        ? body.assigned_technician_id
        : null;
  const priority = normalizePriority(body.priority ?? null);
  const problemDescription =
    typeof body.problemDescription !== 'undefined'
      ? body.problemDescription
      : typeof body.problem_description !== 'undefined'
        ? body.problem_description
        : null;
  const cancelReason =
    typeof body.cancelReason !== 'undefined'
      ? body.cancelReason
      : typeof body.cancel_reason !== 'undefined'
        ? body.cancel_reason
        : null;

  // COMPRO is irreversible once set.
  if (String(chat.status ?? '').trim() === 'compro' && nextStatus !== 'compro') {
    throw new ApiError(422, 'COMPRO is irreversible and cannot be reverted');
  }

  // Business validations
  // For servicio_reservado and por_levantamiento, scheduling fields are mandatory.
  // For reserva, keep backward compatibility: only require scheduling fields when the client provides any of them.
  const locationResolved = String(locationText ?? address ?? '').trim();

  const wantsSchedulingPayload =
    nextStatus === 'servicio_reservado' ||
    nextStatus === 'por_levantamiento' ||
    nextStatus === 'instalacion' ||
    nextStatus === 'mantenimiento' ||
    (nextStatus === 'reserva' &&
      (scheduledAt !== null ||
        address !== null ||
        locationText !== null ||
        assignedTechnicianId !== null ||
        serviceId !== null));

  if (wantsSchedulingPayload) {
    const d = parseScheduledAt(scheduledAt ?? null);
    if (!d) throw new ApiError(422, 'scheduled_at is required for this status');

    if (!locationResolved) {
      throw new ApiError(422, 'location_text (direccion) is required for this status');
    }
    if (!assignedTechnicianId) {
      throw new ApiError(422, 'assigned_tech_id is required for this status');
    }
    if (!serviceId) {
      throw new ApiError(422, 'service_id is required for this status');
    }
  }

  if (nextStatus === 'con_problema' || nextStatus === 'garantia' || nextStatus === 'en_garantia' || nextStatus === 'solucion_garantia') {
    if (!problemDescription || problemDescription.trim().length === 0) {
      throw new ApiError(400, 'problemDescription is required for garantia/con_problema');
    }
  }

  if (nextStatus === 'cancelado') {
    if (!cancelReason || cancelReason.trim().length === 0) {
      throw new ApiError(400, 'cancelReason is required for cancelado');
    }
  }

  const mapping = nextStatus === 'reserva' && !wantsSchedulingPayload ? null : mapCrmStatusToTaskType(nextStatus);

  const result = await prisma.$transaction(async (tx) => {
    const chatPatch: any = { status: nextStatus };
    if (wantsSchedulingPayload) {
      chatPatch.scheduled_at = parseScheduledAt(scheduledAt ?? null);
      chatPatch.location_text = locationResolved.length > 0 ? locationResolved : null;
      chatPatch.assigned_tech_id = assignedTechnicianId;
      chatPatch.service_id = serviceId;
    }
    if (nextStatus === 'compro' && String(chat.status ?? '').trim() !== 'compro') {
      chatPatch.purchased_at = new Date();
      chatPatch.active_client_message_pending = false;
    }

    // Always update CRM first (and scheduling fields when applicable)
    await tx.crmChat.update({ where: { id: chatId }, data: chatPatch });

    // Upsert CRM meta as best-effort (note/product interest)
    const metaPatch: any = {};
    if (typeof note !== 'undefined' && note !== null) metaPatch.internal_note = note;
    if (typeof productId !== 'undefined' && productId !== null) metaPatch.product_id = productId;
    if (Object.keys(metaPatch).length > 0) {
      await upsertChatMeta(chatId, metaPatch);
    }

    if (!mapping) {
      // Not an operational status: just return updated chat.
      const updated = await tx.crmChat.findUnique({ where: { id: chatId } });
      const metaById = await fetchChatMeta([chatId]);
      const merged = { ...updated, ...(metaById.get(chatId) ?? {}) };
      return { merged, operationsJobId: null };
    }

    // Create customer if needed (Operations schema requires it)
    const customer = await ensureCustomerForChat({
      tx,
      empresaId: empresa_id,
      chat: {
        id: chat.id,
        wa_id: chat.wa_id,
        phone: chat.phone ?? null,
        display_name: chat.display_name ?? null,
      },
      phoneOverride: phoneOverride ?? null,
      addressText: locationResolved.length > 0 ? locationResolved : null,
    });

    if (wantsSchedulingPayload) {
      const svc = await tx.service.findFirst({
        where: { id: serviceId ?? undefined, empresa_id, is_active: true },
        select: { id: true },
      });
      if (!svc) throw new ApiError(422, 'service_id is invalid or inactive');

      const tech = await tx.usuario.findFirst({
        where: { id: assignedTechnicianId ?? undefined, empresa_id },
        select: { id: true },
      });
      if (!tech) throw new ApiError(422, 'assigned_tech_id is invalid');
    }

    // Cancel other active jobs for this chat when switching operational types (prevents duplicates)
    const otherActive = await tx.operationsJob.findMany({
      where: {
        empresa_id,
        deleted_at: null,
        crm_chat_id: chatId,
        crm_task_type: { not: mapping.taskType as any },
        status: { notIn: ['completed', 'closed', 'cancelled'] as any },
      },
      orderBy: { updated_at: 'desc' },
      take: 10,
    });

    for (const otherJob of otherActive as any[]) {
      const prev = otherJob.status;
      const updated = await tx.operationsJob.update({
        where: { id: otherJob.id },
        data: {
          status: 'cancelled' as any,
          cancel_reason: `Actualizado desde CRM: ${nextStatus}`,
          last_update_by_user_id: user_id,
        } as any,
      });
      await tx.operationsJobHistory.create({
        data: {
          job_id: updated.id,
          action_type: 'crm_status_switch',
          old_status: String(prev),
          new_status: String(updated.status),
          note: `CRM cambió a ${nextStatus}; se canceló la tarea previa (${String(otherJob.crm_task_type ?? '')}).`,
          created_by_user_id: user_id,
        } as any,
      });
    }

    const existing = await tx.operationsJob.findFirst({
      where: {
        empresa_id,
        deleted_at: null,
        crm_chat_id: chatId,
        crm_task_type: mapping.taskType as any,
        status: { notIn: ['completed', 'closed', 'cancelled'] as any },
      },
      orderBy: { updated_at: 'desc' },
    });

    const serviceTypeLabel =
      mapping.serviceTypeLabel ??
      (mapping.taskType === 'LEVANTAMIENTO'
        ? 'Levantamiento'
        : mapping.taskType === 'GARANTIA'
          ? 'Garantía'
          : mapping.taskType === 'INSTALACION'
            ? 'Instalación'
            : 'Servicio reservado');

    const baseJobData: any = {
      empresa_id,
      crm_customer_id: customer.id,
      customer_name: customer.nombre,
      customer_phone: customer.telefono,
      customer_address: customer.direccion ?? customer.ubicacion_mapa ?? null,
      service_type: serviceTypeLabel,
      priority: priority ?? undefined,
      notes: note ?? undefined,
      assigned_tech_id: typeof assignedTechnicianId === 'undefined' ? undefined : assignedTechnicianId,
      crm_chat_id: chatId,
      crm_task_type: mapping.taskType,
      product_id: productId ?? undefined,
      service_id: serviceId ?? undefined,
      scheduled_at: wantsSchedulingPayload ? parseScheduledAt(scheduledAt ?? null) : undefined,
      location_text: wantsSchedulingPayload ? (locationResolved.length > 0 ? locationResolved : null) : undefined,
      last_update_by_user_id: user_id,
    };

    let job: any;
    let oldStatus: string | null = null;

    if (existing) {
      oldStatus = String(existing.status ?? '');
      // Do not regress status if technician already started.
      const safeStatuses = new Set(['pending_survey', 'pending_scheduling', 'scheduled', 'warranty_pending']);
      const nextJobStatus =
        safeStatuses.has(String(existing.status)) ? mapping.initialJobStatus : String(existing.status);

      job = await tx.operationsJob.update({
        where: { id: existing.id },
        data: {
          ...baseJobData,
          status: nextJobStatus as any,
        },
      });
    } else {
      job = await tx.operationsJob.create({
        data: {
          ...baseJobData,
          created_by_user_id: user_id,
          status: mapping.initialJobStatus as any,
        },
      });
    }

    // Upsert schedule / warranty ticket based on type
    // NOTE: Levantamientos also need to show up in Agenda immediately.
    if (
      mapping.taskType === 'SERVICIO_RESERVADO' ||
      mapping.taskType === 'LEVANTAMIENTO' ||
      mapping.taskType === 'INSTALACION'
    ) {
      const d = parseScheduledAt(scheduledAt ?? null);
      if (!d) throw new ApiError(400, 'scheduledAt is required for servicio_reservado');

      // Some deployments only have operations_jobs (no operations_schedule table yet).
      // Keep CRM→Operations working by treating operations_jobs.scheduled_at as the source of truth.
      if (await tableExists('operations_schedule')) {
        await tx.operationsSchedule.upsert({
          where: { job_id: job.id },
          create: {
            job_id: job.id,
            scheduled_date: dateOnlyUtc(d),
            preferred_time: formatTimeHHmm(d),
            assigned_tech_id: assignedTechnicianId ?? null,
            additional_tech_ids: [],
            customer_availability_notes: note ?? null,
          } as any,
          update: {
            scheduled_date: dateOnlyUtc(d),
            preferred_time: formatTimeHHmm(d),
            assigned_tech_id:
              typeof assignedTechnicianId === 'undefined' ? undefined : (assignedTechnicianId ?? null),
            customer_availability_notes: note ?? null,
          } as any,
        });
      }
    }

    if (mapping.taskType === 'GARANTIA') {
      const reason = (problemDescription ?? '').trim();
      if (!reason) throw new ApiError(400, 'problemDescription is required for garantia');

      // Best-effort: some deployments may not have warranty tables yet.
      if (await tableExists('operations_warranty_tickets')) {
        const existingTicket = await tx.operationsWarrantyTicket.findFirst({
          where: { job_id: job.id, status: { in: ['pending', 'in_progress'] as any } },
          orderBy: { reported_at: 'desc' },
        });

        if (!existingTicket) {
          await tx.operationsWarrantyTicket.create({
            data: {
              job_id: job.id,
              reason,
              assigned_tech_id: assignedTechnicianId ?? null,
              status: 'pending',
            } as any,
          });
        } else {
          await tx.operationsWarrantyTicket.update({
            where: { id: existingTicket.id },
            data: {
              ...(existingTicket.status === 'pending' ? { reason } : {}),
              assigned_tech_id:
                typeof assignedTechnicianId === 'undefined' ? undefined : (assignedTechnicianId ?? null),
            } as any,
          });
        }
      }
    }

    // History entry (always)
    await tx.operationsJobHistory.create({
      data: {
        job_id: job.id,
        action_type: 'crm_status',
        old_status: oldStatus,
        new_status: String(job.status),
        note:
          mapping.taskType === 'SERVICIO_RESERVADO'
            ? `CRM -> ${nextStatus} (programado ${scheduledAt ?? ''})`
            : mapping.taskType === 'GARANTIA'
              ? `CRM -> ${nextStatus}: ${(problemDescription ?? '').trim()}`
              : `CRM -> ${nextStatus}`,
        created_by_user_id: user_id,
      } as any,
    });

    const updatedChat = await tx.crmChat.findUnique({ where: { id: chatId } });
    const metaById = await fetchChatMeta([chatId]);
    const merged = { ...updatedChat, ...(metaById.get(chatId) ?? {}) };

    return { merged, operationsJobId: job.id };
  });

  emitCrmEvent({ type: 'chat.updated', chatId });

  res.json({
    item: toChatApiItem(result.merged),
    operations: result.operationsJobId ? { jobId: result.operationsJobId } : null,
  });
}

export async function convertChatToCustomer(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  // Extract status from query to set appropriate tags
  const crmStatusRaw = (req.query.status as string) || 'primer_contacto';

  function normalizeCustomerTag(raw: string): string {
    const v = String(raw || '').trim();
    if (!v) return 'primer_contacto';
    if (v === 'activo' || v === 'inactivo' || v === 'pendiente') return 'primer_contacto';
    if (v === 'noInteresado') return 'no_interesado';
    if (v === 'en_garantia') return 'garantia';
    return v;
  }

  const crmStatus = normalizeCustomerTag(crmStatusRaw);

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const chat = await prisma.crmChat.findFirst({ where: { id: chatId, empresa_id } });
  if (!chat) throw new ApiError(404, 'Chat not found');

  const phoneCandidate = chat.phone ?? phoneFromWaId(String(chat.wa_id ?? ''));
  const telefono = toPhoneE164(phoneCandidate);
  if (!telefono) {
    throw new ApiError(400, 'Chat has no valid phone; cannot create customer', undefined, 'INVALID_PHONE');
  }

  const name =
    chat.display_name && chat.display_name.trim().length > 0
      ? chat.display_name.trim()
      : `Cliente WhatsApp ${telefono}`;

  // Map CRM status to customer tags for proper filtering (keep legacy aliases).
  const tags: string[] = [];
  if (crmStatus === 'compra_finalizada') {
    tags.push('compra_finalizada', 'compro', 'finalizado');
  } else if (crmStatus === 'garantia' || crmStatus === 'solucion_garantia') {
    tags.push(crmStatus, 'garantia');
  } else {
    tags.push(crmStatus);
  }

  console.log(
    `[CRM] Converting chat ${chatId} to customer with status=${crmStatus}, tags=${tags.join(',')}`,
  );

  const existing = await prisma.customer.findFirst({
    where: { empresa_id, telefono, deleted_at: null },
  });

  if (existing) {
    // Update existing customer with new tags (merge, not replace)
    const mergedTags = Array.from(new Set([...existing.tags, ...tags]));
    const updated = await prisma.customer.update({
      where: { id: existing.id },
      data: {
        tags: mergedTags,
        updated_at: new Date(),
      },
    });
    console.log(`[CRM] Updated existing customer ${existing.id} with merged tags: ${mergedTags.join(',')}`);
    res.json({ customer: updated, created: false, updated: true });
    return;
  }

  const created = await prisma.customer.create({
    data: {
      empresa_id,
      nombre: name,
      telefono,
      tags,
      origen: 'whatsapp',
    },
  });

  console.log(`[CRM] Created new customer ${created.id} with tags: ${tags.join(',')}`);
  res.json({ customer: created, created: true });
}

export async function listChatStats(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);

  const userInstanceId = await getUserInstanceIdForLists(userId);
  if (!userInstanceId) {
    res.json({
      total: 0,
      boughtTotal: 0,
      byStatus: {},
      importantCount: 0,
      unreadTotal: 0,
    });
    return;
  }

  const whereNormal: any = {
    empresa_id,
    status: { notIn: ['compro', 'eliminado'] },
    instancia_id: userInstanceId,
  };

  const [total, boughtTotal, byStatusRows, unreadAgg] = await Promise.all([
    prisma.crmChat.count({ where: whereNormal }),
    prisma.crmChat.count({ where: { empresa_id, status: 'compro', instancia_id: userInstanceId } }),
    prisma.crmChat.groupBy({
      by: ['status'],
      where: whereNormal,
      _count: { _all: true },
    }),
    prisma.crmChat.aggregate({
      where: whereNormal,
      _sum: { unread_count: true },
    }),
  ]);

  // Important flag lives in crm_chat_meta.
  let importantCount = 0;
  if (await crmChatMetaExists()) {
    const importantRows = await prisma.$queryRawUnsafe<{ count: number }[]>(
      `
      SELECT COUNT(*)::int as count
      FROM crm_chat_meta m
      JOIN crm_chats c ON c.id = m.chat_id
      WHERE c.empresa_id = $1::uuid
        AND c.status NOT IN ('compro','eliminado')
        AND c.instancia_id = $2::uuid
        AND m.important = TRUE
      `,
      empresa_id,
      userInstanceId,
    );
    importantCount = importantRows?.[0]?.count ?? 0;
  }

  const byStatus: Record<string, number> = {};
  for (const r of byStatusRows) {
    byStatus[String(r.status ?? 'unknown')] = (r._count?._all as number) ?? 0;
  }

  const unreadTotal = Number(unreadAgg._sum.unread_count ?? 0);

  res.json({
    total,
    boughtTotal,
    byStatus,
    importantCount,
    unreadTotal,
  });
}

export async function listChatMessages(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

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

  const mapped = items.map(toMessageApiItem);

  res.json({
    items: mapped,
    next_before: nextBefore,
    // also provide camelCase for new clients
    nextBefore,
  });
}

export async function postUpload(req: Request, res: Response) {
  throw new ApiError(410, CRM_MEDIA_DISABLED_ERROR);
}


export async function sendTextMessage(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  const chat = await requireChatAccess({ empresaId: empresa_id, userId, chatId });

  const parsed = crmSendTextSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const aiSuggestionId = parsed.data.aiSuggestionId ?? null;
  const aiSuggestedText = parsed.data.aiSuggestedText ?? null;
  const aiUsedKnowledge = parsed.data.aiUsedKnowledge ?? null;

  const skipEvolution = Boolean((parsed.data as any).skipEvolution ?? false);
  const remoteMessageId = ((parsed.data as any).remoteMessageId ?? null) as string | null;

  const updated = await createAndSendTextForChat({
    chatId,
    waId: chat.wa_id,
    phoneE164: chat.phone ?? null,
    text: parsed.data.text,
    skipEvolution,
    remoteMessageId,
    aiSuggestionId,
    aiSuggestedText,
    aiUsedKnowledge,
    empresaId: empresa_id,
  });

  res.status(201).json({
    item: updated,
    ...(skipEvolution ? { note: 'Recorded only (skipEvolution)' } : null),
    ...(updated?.status === 'failed' ? { warning: 'Evolution send failed' } : null),
  });
}

export async function sendOutboundTextMessage(req: Request, res: Response) {
  const empresaId = actorEmpresaId(req);
  const userId = actorUserId(req);
  const parsed = crmOutboundSendTextSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const statusRaw = String(parsed.data.status ?? '').trim();
  const status = statusRaw.length > 0 ? statusRaw : null;
  const displayNameRaw = String(parsed.data.displayName ?? '').trim();
  const displayName = displayNameRaw.length > 0 ? displayNameRaw : null;

  const normalized = normalizeOutboundPhone(parsed.data.phone);

  const activeInstanceId = await getUserActiveInstanceId(userId);
  if (!activeInstanceId) {
    throw new ApiError(
      409,
      'No tienes una instancia activa configurada. Configura tu Instancia Evolution antes de enviar mensajes.',
    );
  }

  // Allow user to message a number even if it was not in the list yet, but keep instance isolation.
  const existing = await prisma.crmChat.findUnique({
    where: ({ empresa_id_wa_id: { empresa_id: empresaId, wa_id: normalized.waId } } as any),
    select: {
      id: true,
      instancia_id: true,
      owner_user_id: true,
      asignado_a_user_id: true,
    },
  });

  if (existing?.id) {
    // Ensure current user can access the chat and it belongs to the same instance.
    await requireChatAccess({ empresaId, userId, chatId: existing.id });

    if (existing.instancia_id && String(existing.instancia_id) !== activeInstanceId) {
      throw new ApiError(
        409,
        'Este chat pertenece a otra instancia. Transfi\u00e9relo para poder gestionarlo desde tu instancia.',
      );
    }
  }

  const chat = existing?.id
    ? await prisma.crmChat.update({
        where: { id: existing.id },
        data: {
          phone: normalized.phoneE164,
          ...(displayName ? { display_name: displayName } : {}),
          ...(status ? { status } : {}),
          ...(existing.instancia_id ? {} : {
            instancia_id: activeInstanceId,
            owner_user_id: userId,
            asignado_a_user_id: userId,
          }),
        },
      })
    : await prisma.crmChat.create({
        data: {
          wa_id: normalized.waId,
          phone: normalized.phoneE164,
          status: status ?? 'primer_contacto',
          display_name: displayName,
          instancia_id: activeInstanceId,
          owner_user_id: userId,
          asignado_a_user_id: userId,
          empresa: { connect: { id: empresaId } },
        },
      });

  const skipEvolution = Boolean((parsed.data as any).skipEvolution ?? false);
  const remoteMessageId = ((parsed.data as any).remoteMessageId ?? null) as string | null;

  const updated = await createAndSendTextForChat({
    chatId: chat.id,
    waId: chat.wa_id,
    phoneE164: chat.phone ?? normalized.phoneE164,
    text: parsed.data.text,
    skipEvolution,
    remoteMessageId,
    aiSuggestionId: parsed.data.aiSuggestionId ?? null,
    aiSuggestedText: parsed.data.aiSuggestedText ?? null,
    aiUsedKnowledge: (parsed.data.aiUsedKnowledge ?? null) as any,
    empresaId: empresaId,
  });

  res.status(201).json({
    chatId: chat.id,
    chat: toChatApiItem(chat),
    item: updated,
    ...(skipEvolution ? { note: 'Recorded only (skipEvolution)' } : null),
    ...(updated?.status === 'failed' ? { warning: 'Evolution send failed' } : null),
  });
}

export async function sendMediaMessage(req: Request, res: Response) {
  throw new ApiError(410, CRM_MEDIA_DISABLED_ERROR);
}

export async function recordMediaMessage(req: Request, res: Response) {
  throw new ApiError(410, CRM_MEDIA_DISABLED_ERROR);
}

export async function markChatRead(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const userId = actorUserId(req);
  const chatId = req.params.chatId;

  await requireChatAccess({ empresaId: empresa_id, userId, chatId });

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
