import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';

import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { parseEvolutionWebhook } from '../../services/evolution/evolution_event_parser';
import { emitCrmEvent } from '../crm/crm_stream';
import { normalizeWhatsAppIdentity } from '../../utils/whatsapp_identity';

function safeJson(obj: unknown): string {
  try {
    return JSON.stringify(obj);
  } catch {
    return '{"_error":"json_stringify_failed"}';
  }
}

// Normalize to E.164 digits (without '+').
function digitsOnlyPhone(v: string | null | undefined): string {
  return String(v ?? '').replace(/\D+/g, '');
}

function toPhoneE164(raw: string | null | undefined): string | null {
  const d = digitsOnlyPhone(raw);
  if (!d) return null;
  // If already 11+ digits, keep as-is (assume includes country code)
  if (d.length >= 11) return d;
  // If 10 digits, prefix default CC (NANP) and DR area codes support
  if (d.length === 10) {
    const cc = digitsOnlyPhone(env.EVOLUTION_DEFAULT_COUNTRY_CODE ?? '1') || '1';
    return `${cc}${d}`;
  }
  // Fallback: return digits
  return d;
}

function placeholderForType(type: string): string {
  const t = String(type ?? '').toLowerCase().trim();
  switch (t) {
    case 'image':
      return '[Imagen recibida]';
    case 'video':
      return '[Video recibido]';
    case 'audio':
    case 'ptt':
      return '[Audio recibido]';
    case 'document':
      return '[Documento recibido]';
    case 'sticker':
      return '[Sticker recibido]';
    case 'location':
      return '[Ubicación recibida]';
    case 'contact':
      return '[Contacto recibido]';
    default:
      return '[Archivo recibido]';
  }
}

export async function evolutionWebhook(req: Request, res: Response) {
  const now = new Date();
  const ipAddress =
    (req.get('x-forwarded-for') || '').split(',')[0].trim() || req.ip || req.socket.remoteAddress;
  const userAgent = req.get('user-agent') || null;
  const contentType = req.get('content-type') || null;
  const contentLength = req.get('content-length') || null;
  const bodyShape = req.body == null ? 'null' : Array.isArray(req.body) ? 'array' : typeof req.body;

  const parsedForType = parseEvolutionWebhook(req.body);
  const eventType = parsedForType.eventType;

  console.log('========================================');
  console.log('[WEBHOOK] HIT /webhooks/evolution');
  console.log('[WEBHOOK] Timestamp:', now.toISOString());
  console.log('[WEBHOOK] IP:', ipAddress);
  console.log('[WEBHOOK] User-Agent:', userAgent);
  console.log('[WEBHOOK] Content-Type:', contentType);
  console.log('[WEBHOOK] Content-Length:', contentLength);
  console.log('[WEBHOOK] Body Shape:', bodyShape);
  console.log('[WEBHOOK] Event Type:', eventType || 'unknown');

  const bodyPreview =
    typeof req.body === 'string'
      ? req.body.substring(0, 300)
      : safeJson(req.body).substring(0, 300);
  console.log('[WEBHOOK] Body Preview:', bodyPreview);
  console.log('========================================');

  // ========================================================
  // SAVE EVENT TO DATABASE - ALWAYS, NEVER THROW
  // ========================================================
  let eventId: string | null = null;
  try {
    const headers = {
      'content-type': contentType,
      'content-length': contentLength,
      'user-agent': userAgent,
      'x-forwarded-for': req.get('x-forwarded-for') || null,
      'x-real-ip': req.get('x-real-ip') || null,
    };

    const rawBody = typeof req.body === 'string' ? req.body : safeJson(req.body);

    const event = await prisma.crmWebhookEvent.create({
      data: {
        created_at: now,
        headers: headers as any,
        ip_address: ipAddress || null,
        user_agent: userAgent,
        payload: req.body as any,
        event_type: eventType,
        source: 'evolution',
        raw_body:
          rawBody.length > 10000 ? rawBody.substring(0, 10000) + '...[truncated]' : rawBody,
      } as any,
    });

    eventId = event.id;
    console.log('[WEBHOOK] Event saved to database:', eventId);
  } catch (e: any) {
    console.error('[WEBHOOK] CRITICAL: Could not save event to database:', e?.message || e);
  }

  // ========================================================
  // ALWAYS RESPOND 200 IMMEDIATELY
  // ========================================================
  res.status(200).json({
    ok: true,
    received: true,
    event_id: eventId,
    event_type: eventType,
    timestamp: now.toISOString(),
  });

  // ========================================================
  // PROCESS EVENT (best effort, non-blocking)
  // ========================================================
  setImmediate(async () => {
    try {
      await processWebhookEvent(req.body, eventId);
    } catch (e: any) {
      console.error('[WEBHOOK] Error processing event:', e?.message || e);

      if (eventId) {
        try {
          await prisma.crmWebhookEvent.update({
            where: { id: eventId },
            data: {
              processed: true,
              processed_at: new Date(),
              processing_error: e?.message || String(e),
            } as any,
          });
        } catch (dbError) {
          console.error('[WEBHOOK] Could not update event processing status:', dbError);
        }
      }
    }
  });
}

async function processWebhookEvent(body: any, eventId: string | null) {
  const now = new Date();
  const parsed = parseEvolutionWebhook(body);
  const empresaId = env.DEFAULT_EMPRESA_ID;

  // ========================================================
  // INSTANCE DETECTION - Extract instance name from payload
  // ========================================================
  // Evolution webhooks typically include "instance" field in the payload
  // Format: { instance: "junior01", ... }
  let instanceName: string | null = null;
  let instanciaId: string | null = null;
  let instanceOwnerId: string | null = null;

  if (body && typeof body === 'object') {
    instanceName = body.instance || body.instanceName || null;
  }

  // If instance name is provided, look up the instance
  if (instanceName && instanceName.trim()) {
    try {
      const instances = await prisma.$queryRawUnsafe<any[]>(
        `SELECT id, user_id FROM crm_instancias WHERE nombre_instancia = $1 AND is_active = TRUE LIMIT 1`,
        instanceName.trim()
      );
      
      if (instances.length > 0) {
        instanciaId = instances[0].id;
        instanceOwnerId = instances[0].user_id;
        console.log('[WEBHOOK] Instance matched:', { instanceName, instanciaId, instanceOwnerId });
      } else {
        console.warn('[WEBHOOK] Instance not found or inactive:', instanceName);
      }
    } catch (e: any) {
      console.error('[WEBHOOK] Error looking up instance:', e?.message || e);
    }
  } else {
    console.warn('[WEBHOOK] No instance name in payload - message will be orphaned');
  }

  if (parsed.kind === 'status') {
    if (!parsed.messageId || !parsed.status) {
      console.log('[WEBHOOK] Status update ignored - missing messageId or status');
      return;
    }

    const updated = await prisma.crmChatMessage.updateMany({
      where: { empresa_id: empresaId, remote_message_id: parsed.messageId },
      data: {
        status: parsed.status,
        ...(parsed.status === 'failed' ? { error: parsed.error ?? 'failed' } : null),
      },
    });

    console.log('[WEBHOOK] Status updated:', {
      messageId: parsed.messageId,
      status: parsed.status,
      count: updated.count,
    });

    if (updated.count > 0) {
      const msg = await prisma.crmChatMessage.findFirst({
        where: { empresa_id: empresaId, remote_message_id: parsed.messageId },
        select: { chat_id: true },
      });
      if (msg) {
        emitCrmEvent({
          type: 'message.status',
          chatId: msg.chat_id,
          remoteMessageId: parsed.messageId,
          status: parsed.status,
        });
      }
    }

    if (eventId) {
      await prisma.crmWebhookEvent.update({
        where: { id: eventId },
        data: { processed: true, processed_at: new Date() } as any,
      });
    }

    return;
  }

  if (parsed.kind !== 'message') {
    console.log('[WEBHOOK] Unknown payload shape - kind:', parsed.kind);

    if (eventId) {
      await prisma.crmWebhookEvent.update({
        where: { id: eventId },
        data: {
          processed: true,
          processed_at: new Date(),
          processing_error: `Unknown event kind: ${parsed.kind}`,
        } as any,
      });
    }

    return;
  }

  const waId = (parsed.waId ?? '').trim();
  const phoneRaw = parsed.phoneNumber ?? null;
  const normalized = normalizeWhatsAppIdentity({ waId, phone: phoneRaw });
  const phoneE164 = normalized.phoneE164Digits;
  const normalizedWaId = normalized.waId;

  if (!normalizedWaId && !phoneE164) {
    console.log('[WEBHOOK] Message ignored - missing waId and phone');

    if (eventId) {
      await prisma.crmWebhookEvent.update({
        where: { id: eventId },
        data: {
          processed: true,
          processed_at: new Date(),
          processing_error: 'Missing waId and phone',
        } as any,
      });
    }

    return;
  }

  if (!normalizedWaId) {
    console.log('[WEBHOOK] Message ignored - missing normalized waId');

    if (eventId) {
      await prisma.crmWebhookEvent.update({
        where: { id: eventId },
        data: {
          processed: true,
          processed_at: new Date(),
          processing_error: 'Missing normalized waId',
        } as any,
      });
    }

    return;
  }

  const createdAt = parsed.timestamp ?? now;

  const hasText = typeof parsed.body === 'string' && parsed.body.trim().length > 0;
  const hasMedia = typeof parsed.mediaUrl === 'string' && parsed.mediaUrl.trim().length > 0;

  const messageType = (() => {
    const t = (parsed.type ?? 'text').toLowerCase();
    if (
      ['text', 'image', 'video', 'audio', 'document', 'sticker', 'location', 'contact'].includes(
        t,
      )
    )
      return t;
    return hasMedia ? 'document' : 'text';
  })();

  const direction = parsed.fromMe ? 'out' : 'in';
  const status = parsed.fromMe ? 'sent' : 'received';

  const textToStore = hasText
    ? parsed.body!.trim()
    : hasMedia
      ? placeholderForType(messageType)
      : null;

  const preview = (textToStore ?? `[${messageType}]`).slice(0, 180);

  console.log('[WEBHOOK] Processing message:', {
    waId: normalizedWaId,
    direction,
    messageType,
    hasText,
    hasMedia,
    fromMe: parsed.fromMe,
  });

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    // DEDUPE FIRST: Evolution/Baileys can emit two events for the same message id
    // (e.g., one with "@s.whatsapp.net" and another with "@lid").
    // If we upsert the chat first, we may create a bogus "@lid" chat and then
    // ignore the real one. Always check for an existing message before touching chats.
    if (parsed.messageId && parsed.messageId.trim()) {
      const existing = await tx.crmChatMessage.findFirst({
        where: { empresa_id: empresaId, remote_message_id: parsed.messageId.trim() },
      });
      if (existing) {
        console.log('[WEBHOOK] Duplicate message ignored:', parsed.messageId);
        const existingChat = await tx.crmChat.findUnique({
          where: { id: existing.chat_id },
        });
        if (!existingChat) {
          throw new Error('Duplicate message references missing chat');
        }
        return { chat: existingChat, message: existing, deduped: true };
      }
    }

    // Find or create chat - with instance support
    let chat = await tx.crmChat.findFirst({
      where: instanciaId
        ? { instancia_id: instanciaId, wa_id: normalizedWaId }
        : { empresa_id: empresaId, wa_id: normalizedWaId },
    });

    if (!chat) {
      // Create new chat
      chat = await tx.crmChat.create({
        data: {
          wa_id: normalizedWaId,
          display_name: parsed.displayName?.trim() || null,
          phone: phoneE164 ?? null,
          last_message_preview: preview,
          last_message_at: createdAt,
          unread_count: direction === 'in' ? 1 : 0,
          status: 'primer_contacto',
          empresa_id: empresaId,
          // Assign to instance if detected
          instancia_id: instanciaId ?? null,
          owner_user_id: instanceOwnerId ?? null,
          asignado_a_user_id: instanceOwnerId ?? null,
        },
      });
    } else {
      // Update existing chat
      chat = await tx.crmChat.update({
        where: { id: chat.id },
        data: {
          ...(parsed.displayName?.trim() ? { display_name: parsed.displayName.trim() } : {}),
          ...(phoneE164 ? { phone: phoneE164 } : {}),
          last_message_preview: preview,
          last_message_at: createdAt,
          ...(direction === 'in' ? { unread_count: { increment: 1 } } : {}),
        },
      });
    }

    // Ensure empresa_id is set - fetch and update if NULL
    if (!chat.empresa_id) {
      await tx.crmChat.update({
        where: { id: chat.id },
        data: { empresa_id: empresaId },
      });
      chat.empresa_id = empresaId;
    }

    // Bought-client inbox: if a purchased client sends a new inbound message,
    // mark it for attention without moving it back into the normal CRM list.
    if (direction === 'in' && String(chat.status ?? '') === 'compro') {
      await tx.crmChat.update({
        where: { id: chat.id },
        data: { active_client_message_pending: true },
      });
    }

    const message = await tx.crmChatMessage.create({
      data: {
        empresa_id: chat.empresa_id,
        chat_id: chat.id,
        direction,
        message_type: messageType,
        text: textToStore,
        remote_message_id: parsed.messageId?.trim() || null,
        status,
        timestamp: createdAt,
        // Assign to instance for audit and filtering
        instancia_id: instanciaId ?? null,
      },
    });

    console.log('[WEBHOOK] Message saved:', { chatId: chat.id, messageId: message.id });

    return { chat, message, deduped: false };
  });

  emitCrmEvent({ type: 'message.new', chatId: result.chat.id, messageId: result.message.id });
  emitCrmEvent({ type: 'chat.updated', chatId: result.chat.id });

  if (eventId) {
    await prisma.crmWebhookEvent.update({
      where: { id: eventId },
      data: { processed: true, processed_at: new Date() } as any,
    });
  }

  console.log('[WEBHOOK] Processing complete');
}
