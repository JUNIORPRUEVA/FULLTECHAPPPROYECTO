import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import axios from 'axios';

import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { parseEvolutionWebhook } from '../../services/evolution/evolution_event_parser';
import { emitCrmEvent } from '../crm/crm_stream';

function safeJson(obj: unknown): string {
  try {
    return JSON.stringify(obj);
  } catch {
    return '{"_error":"json_stringify_failed"}';
  }
}

function computeEventId(req: Request): string {
  const headerId =
    (req.header('x-event-id') ?? req.header('x-evolution-event-id') ?? '').trim();
  if (headerId) return headerId;

  const raw = safeJson(req.body);
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function checkWebhookSecret(req: Request) {
  const secret = (env.WEBHOOK_SECRET ?? '').trim();
  if (!secret) return;

  const got = (req.header('x-evolution-webhook-secret') ?? req.header('x-webhook-secret') ?? '').trim();
  if (!got || got !== secret) {
    // IMPORTANT: still respond 200 to avoid infinite retries; just ignore.
    throw new Error('Invalid webhook secret');
  }
}

function monthFolder(d: Date) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

function uploadsCrmDir(): string {
  const root = path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
  const dir = path.join(root, 'crm', monthFolder(new Date()));
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function publicUrlForSavedFile(absPath: string): string {
  const root = path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
  const rel = path.relative(root, absPath).split(path.sep).join('/');
  return `${env.PUBLIC_BASE_URL.replace(/\/$/, '')}/uploads/${rel}`;
}

async function maybeDownloadMedia(url: string, mimeHint?: string | null): Promise<{
  mediaUrl: string;
  mediaMime: string | null;
  mediaSize: number | null;
  mediaName: string | null;
} | null> {
  try {
    if (!/^https?:\/\//i.test(url)) return null;

    // If already pointing to our own uploads, keep it.
    if (env.PUBLIC_BASE_URL && url.startsWith(env.PUBLIC_BASE_URL.replace(/\/$/, '') + '/uploads/')) {
      return { mediaUrl: url, mediaMime: mimeHint ?? null, mediaSize: null, mediaName: null };
    }

    const res = await axios.get<ArrayBuffer>(url, {
      responseType: 'arraybuffer',
      timeout: 20000,
      maxContentLength: Math.max(1, Number(env.MAX_UPLOAD_MB ?? 25)) * 1024 * 1024,
    });

    const contentType = (res.headers?.['content-type'] as string | undefined) ?? mimeHint ?? null;

    const extFromType = (() => {
      if (!contentType) return '';
      if (contentType.includes('image/jpeg')) return '.jpg';
      if (contentType.includes('image/png')) return '.png';
      if (contentType.includes('image/webp')) return '.webp';
      if (contentType.includes('video/mp4')) return '.mp4';
      if (contentType.includes('audio/mpeg')) return '.mp3';
      if (contentType.includes('audio/ogg')) return '.ogg';
      if (contentType.includes('application/pdf')) return '.pdf';
      return '';
    })();

    const id = crypto.randomUUID();
    const fileName = `${id}${extFromType}`;
    const abs = path.join(uploadsCrmDir(), fileName);

    fs.writeFileSync(abs, Buffer.from(res.data));

    return {
      mediaUrl: publicUrlForSavedFile(abs),
      mediaMime: contentType,
      mediaSize: Buffer.byteLength(Buffer.from(res.data)),
      mediaName: null,
    };
  } catch {
    return null;
  }
}

export async function evolutionWebhook(req: Request, res: Response) {
  const eventId = computeEventId(req);
  const now = new Date();

  // Always log receipt so deployment logs clearly show whether Evolution is hitting us.
  try {
    const contentType = (req.header('content-type') ?? '').trim();
    const contentLength = (req.header('content-length') ?? '').trim();
    const bodyShape =
      typeof req.body === 'string'
        ? `string:${req.body.length}`
        : req.body && typeof req.body === 'object'
          ? `object_keys:${Object.keys(req.body as any).slice(0, 12).join(',')}`
          : typeof req.body;
    // eslint-disable-next-line no-console
    console.log('[webhook:evolution] received', { eventId, contentType, contentLength, bodyShape });
  } catch {
    // ignore logging failures
  }

  // Always 200 to avoid retries loops. We still do best-effort processing.
  try {
    checkWebhookSecret(req);
  } catch (e) {
    console.warn('[webhook:evolution] ignored (secret mismatch)', { eventId });
    res.json({ ok: true, ignored: true });
    return;
  }

  // Idempotency: store raw event (or ignore duplicates)
  try {
    await prisma.crmWebhookEvent.create({
      data: {
        event_id: eventId,
        payload: req.body as any,
      },
    });
  } catch (e: any) {
    if (e?.code === 'P2002') {
      res.json({ ok: true, deduped: true, event_id: eventId });
      return;
    }
    // non-fatal
    console.warn('[webhook:evolution] could not store event', { eventId, err: e?.message });
  }

  const parsed = parseEvolutionWebhook(req.body as any);

  if (parsed.kind === 'status') {
    // Update message status if present
    if (!parsed.messageId || !parsed.status) {
      res.json({ ok: true, ignored: true, event_id: eventId });
      return;
    }

    const updated = await prisma.crmChatMessage.updateMany({
      where: { remote_message_id: parsed.messageId },
      data: {
        status: parsed.status,
        ...(parsed.status === 'failed' ? { error: parsed.error ?? 'failed' } : null),
      },
    });

    // Best-effort: emit status update to clients.
    if (updated.count > 0) {
      // Find chat id for emitting.
      const msg = await prisma.crmChatMessage.findFirst({
        where: { remote_message_id: parsed.messageId },
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

    res.json({ ok: true, event_id: eventId, status_updated: updated.count });
    return;
  }

  if (parsed.kind !== 'message') {
    console.warn('[webhook:evolution] unknown payload shape', { eventId });
    res.json({ ok: true, ignored: true, event_id: eventId });
    return;
  }

  const waId = (parsed.waId ?? '').trim();
  const phone = parsed.phoneNumber ?? null;

  if (!waId && !phone) {
    console.warn('[webhook:evolution] missing waId/phone', { eventId });
    res.json({ ok: true, ignored: true, event_id: eventId });
    return;
  }

  const normalizedWaId = waId || `${phone}@s.whatsapp.net`;
  const createdAt = parsed.timestamp ?? now;

  const hasText = typeof parsed.body === 'string' && parsed.body.trim().length > 0;
  const hasMedia = typeof parsed.mediaUrl === 'string' && parsed.mediaUrl.trim().length > 0;

  let storedMedia: {
    mediaUrl: string;
    mediaMime: string | null;
    mediaSize: number | null;
    mediaName: string | null;
  } | null = null;

  if (hasMedia) {
    storedMedia = await maybeDownloadMedia(parsed.mediaUrl!.trim(), parsed.mediaMime);
  }

  const messageType = (() => {
    const t = (parsed.type ?? 'text').toLowerCase();
    if (['text', 'image', 'video', 'audio', 'document', 'sticker', 'location', 'contact'].includes(t)) return t;
    return hasMedia ? 'document' : 'text';
  })();

  const direction = parsed.fromMe ? 'out' : 'in';
  const status = parsed.fromMe ? 'sent' : 'received';

  const preview = hasText
    ? parsed.body!.trim().slice(0, 180)
    : hasMedia
      ? `[${messageType}]`
      : '[message]';

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const chat = await tx.crmChat.upsert({
      where: { wa_id: normalizedWaId },
      create: {
        wa_id: normalizedWaId,
        display_name: parsed.displayName?.trim() || null,
        phone,
        last_message_preview: preview,
        last_message_at: createdAt,
        unread_count: direction === 'in' ? 1 : 0,
      },
      update: {
        ...(parsed.displayName?.trim() ? { display_name: parsed.displayName.trim() } : null),
        ...(phone ? { phone } : null),
        last_message_preview: preview,
        last_message_at: createdAt,
        ...(direction === 'in' ? { unread_count: { increment: 1 } } : null),
      },
    });

    // Dedup by remote_message_id (WhatsApp message id) if present
    if (parsed.messageId && parsed.messageId.trim()) {
      const existing = await tx.crmChatMessage.findFirst({
        where: { remote_message_id: parsed.messageId.trim() },
      });
      if (existing) {
        return { chat, message: existing, deduped: true };
      }
    }

    const message = await tx.crmChatMessage.create({
      data: {
        chat_id: chat.id,
        direction,
        message_type: messageType,
        text: hasText ? parsed.body!.trim() : null,
        media_url: storedMedia?.mediaUrl ?? (hasMedia ? parsed.mediaUrl!.trim() : null),
        media_mime: storedMedia?.mediaMime ?? parsed.mediaMime ?? null,
        media_size: storedMedia?.mediaSize ?? null,
        media_name: storedMedia?.mediaName ?? null,
        remote_message_id: parsed.messageId?.trim() || null,
        status,
        timestamp: createdAt,
      },
    });

    return { chat, message, deduped: false };
  });

  emitCrmEvent({ type: 'message.new', chatId: result.chat.id, messageId: result.message.id });
  emitCrmEvent({ type: 'chat.updated', chatId: result.chat.id });

  res.json({ ok: true, event_id: eventId, deduped: result.deduped });
}
