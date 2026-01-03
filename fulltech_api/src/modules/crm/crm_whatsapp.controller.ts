import type { Request, Response } from 'express';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { EvolutionClient } from '../../services/evolution/evolution_client';
import {
  crmChatMessagesListQuerySchema,
  crmChatsListQuerySchema,
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

export async function listChats(req: Request, res: Response) {
  const parsed = crmChatsListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, status, page, limit } = parsed.data;
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

  const [items, total] = await Promise.all([
    prisma.crmChat.findMany({
      where,
      orderBy: [{ last_message_at: 'desc' }, { updated_at: 'desc' }],
      take: limit,
      skip,
    }),
    prisma.crmChat.count({ where }),
  ]);

  res.json({ items, total, page, limit });
}

export async function listChatMessages(req: Request, res: Response) {
  const chatId = req.params.chatId;

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

  res.json({ items, next_before: nextBefore });
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
    const updated = await prisma.crmChatMessage.update({
      where: { id: pending.id },
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
