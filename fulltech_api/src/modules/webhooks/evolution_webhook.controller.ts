import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import axios from 'axios';
import { spawn } from 'child_process';
import ffmpegPath from 'ffmpeg-static';

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

async function tryTranscodeToMp3(
  inputAbsPath: string,
): Promise<{ absPath: string; mime: string } | null> {
  // WhatsApp PTTs are commonly OGG/OPUS which is not reliably playable on
  // Windows Media Foundation. Transcode to MP3 for maximum client compatibility.
  const ffmpeg = ffmpegPath;
  if (!ffmpeg) return null;

  const outAbsPath = inputAbsPath.replace(/\.ogg$/i, '.mp3').replace(/\.opus$/i, '.mp3');
  if (outAbsPath === inputAbsPath) return null;

  return await new Promise((resolve) => {
    const args = [
      '-y',
      '-i',
      inputAbsPath,
      '-vn',
      // Prefer MP3 for broad client support.
      '-c:a',
      'libmp3lame',
      '-q:a',
      '4',
      outAbsPath,
    ];

    const proc = spawn(ffmpeg, args, { stdio: 'ignore', windowsHide: true });
    proc.on('error', () => resolve(null));
    proc.on('exit', (code) => {
      if (code === 0 && fs.existsSync(outAbsPath)) {
        resolve({ absPath: outAbsPath, mime: 'audio/mpeg' });
      } else {
        resolve(null);
      }
    });
  });
}

async function maybeDownloadMedia(
  url: string,
  mimeHint?: string | null,
): Promise<{
  mediaUrl: string;
  mediaMime: string | null;
  mediaSize: number | null;
  mediaName: string | null;
} | null> {
  try {
    if (!/^https?:\/\//i.test(url)) return null;

    if (
      env.PUBLIC_BASE_URL &&
      url.startsWith(env.PUBLIC_BASE_URL.replace(/\/$/, '') + '/uploads/')
    ) {
      return { mediaUrl: url, mediaMime: mimeHint ?? null, mediaSize: null, mediaName: null };
    }

    const res = await axios.get<ArrayBuffer>(url, {
      responseType: 'arraybuffer',
      timeout: 20000,
      maxContentLength: Math.max(1, Number(env.MAX_UPLOAD_MB ?? 25)) * 1024 * 1024,
    });

    const contentType =
      (res.headers?.['content-type'] as string | undefined) ?? mimeHint ?? null;

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

    const extFromUrl = (() => {
      try {
        const u = new URL(url);
        return path.extname(u.pathname).toLowerCase();
      } catch {
        return '';
      }
    })();

    const id = crypto.randomUUID();
    const fileExt = extFromType || extFromUrl || '';
    const fileName = `${id}${fileExt}`;
    const abs = path.join(uploadsCrmDir(), fileName);

    fs.writeFileSync(abs, Buffer.from(res.data));

    // If this is an OGG/OPUS voice note, transcode to MP3 for client playback.
    const transcode =
      (fileExt === '.ogg' || fileExt === '.opus' || contentType?.includes('audio/ogg'))
        ? await tryTranscodeToMp3(abs)
        : null;

    const finalAbs = transcode?.absPath ?? abs;
    const finalMime = transcode?.mime ?? contentType;

    return {
      mediaUrl: publicUrlForSavedFile(finalAbs),
      mediaMime: finalMime,
      mediaSize: fs.existsSync(finalAbs) ? fs.statSync(finalAbs).size : Buffer.byteLength(Buffer.from(res.data)),
      mediaName: null,
    };
  } catch {
    return null;
  }
}

function detectEventType(body: any): string | null {
  try {
    if (body && typeof body === 'object') {
      const eventType = body.event || body.type || body.event_type || null;

      if (!eventType) {
        if (body.key?.remoteJid || body.remoteJid) {
          return body.key?.fromMe || body.fromMe ? 'message.sent' : 'message.received';
        } else if (body.status || body.ack) {
          return 'message.status';
        } else if (body.action === 'update' || body.action === 'upsert') {
          return `message.${body.action}`;
        }
      }

      return eventType;
    }
  } catch {
    // ignore
  }
  return null;
}

export async function evolutionWebhook(req: Request, res: Response) {
  const now = new Date();
  const ipAddress = (req.ip || req.socket.remoteAddress || 'unknown').replace('::ffff:', '');
  const userAgent = req.get('user-agent') || 'unknown';

  // ========================================================
  // STRONG LOGGING - Always log webhook receipt
  // ========================================================
  const contentType = req.get('content-type') || 'none';
  const contentLength = req.get('content-length') || 'none';
  const bodyShape =
    typeof req.body === 'string'
      ? `string:${req.body.length}`
      : req.body && typeof req.body === 'object'
        ? `object_keys:[${Object.keys(req.body as any).slice(0, 8).join(',')}]`
        : typeof req.body;

  const eventType = detectEventType(req.body);

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
        ip_address: ipAddress,
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

  if (parsed.kind === 'status') {
    if (!parsed.messageId || !parsed.status) {
      console.log('[WEBHOOK] Status update ignored - missing messageId or status');
      return;
    }

    const updated = await prisma.crmChatMessage.updateMany({
      where: { remote_message_id: parsed.messageId },
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
  const phone = parsed.phoneNumber ?? null;

  if (!waId && !phone) {
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
    console.log('[WEBHOOK] Downloading media:', parsed.mediaUrl);
    storedMedia = await maybeDownloadMedia(parsed.mediaUrl!.trim(), parsed.mediaMime);
    if (storedMedia) {
      console.log('[WEBHOOK] Media downloaded:', storedMedia.mediaUrl);
    } else {
      console.warn('[WEBHOOK] Media download failed');
    }
  }

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

  const preview = hasText
    ? parsed.body!.trim().slice(0, 180)
    : hasMedia
      ? `[${messageType}]`
      : '[message]';

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
        where: { remote_message_id: parsed.messageId.trim() },
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

    const chat = await tx.crmChat.upsert({
      where: { wa_id: normalizedWaId },
      create: {
        wa_id: normalizedWaId,
        display_name: parsed.displayName?.trim() || null,
        phone,
        last_message_preview: preview,
        last_message_at: createdAt,
        unread_count: direction === 'in' ? 1 : 0,
        status: 'primer_contacto',
        empresa: {
          connect: { id: env.DEFAULT_EMPRESA_ID },
        },
      },
      update: {
        ...(parsed.displayName?.trim() ? { display_name: parsed.displayName.trim() } : null),
        ...(phone ? { phone } : null),
        last_message_preview: preview,
        last_message_at: createdAt,
        ...(direction === 'in' ? { unread_count: { increment: 1 } } : null),
      },
    });

    // Ensure empresa_id is set - fetch and update if NULL
    if (!chat.empresa_id) {
      await tx.crmChat.update({
        where: { id: chat.id },
        data: { empresa_id: env.DEFAULT_EMPRESA_ID },
      });
      chat.empresa_id = env.DEFAULT_EMPRESA_ID;
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
