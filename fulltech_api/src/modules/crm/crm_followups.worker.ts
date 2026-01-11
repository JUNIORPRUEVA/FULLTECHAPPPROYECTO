import os from 'os';

import { prisma } from '../../config/prisma';
import { EvolutionClient } from '../../services/evolution/evolution_client';

type FollowupPayload = {
  type: 'text' | 'image';
  text?: string | null;
  mediaUrl?: string | null;
};

type FollowupConstraints = {
  status?: string | null;
  productId?: string | null;
};

function safeJson(obj: unknown): string {
  try {
    return JSON.stringify(obj);
  } catch {
    return '{"_error":"json_stringify_failed"}';
  }
}

function normalizeText(v: unknown): string {
  return String(v ?? '').trim();
}

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

async function getEvolutionClientForInstanceId(instanciaId: string | null): Promise<EvolutionClient> {
  if (!instanciaId) return new EvolutionClient();

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `SELECT nombre_instancia, evolution_base_url, evolution_api_key
     FROM crm_instancias
     WHERE id = $1
     LIMIT 1`,
    instanciaId,
  );
  const inst = rows?.[0];
  const baseUrl = normalizeText(inst?.evolution_base_url);
  const apiKey = normalizeText(inst?.evolution_api_key);
  const instanceName = normalizeText(inst?.nombre_instancia);

  if (!baseUrl || !apiKey) {
    throw new Error('Missing Evolution instance config');
  }

  return new EvolutionClient({ baseUrl, apiKey, instanceName });
}

async function enqueueDueTasks(opts: { batchSize: number; workerId: string }): Promise<string[]> {
  const now = new Date();

  // Lock tasks by setting processing_at/processing_by in a single transaction.
  const ids = await prisma.$transaction(async (tx) => {
    const rows = await tx.$queryRawUnsafe<{ id: string }[]>(
      `
      SELECT id
      FROM crm_followup_tasks
      WHERE sent_at IS NULL
        AND skipped_at IS NULL
        AND processing_at IS NULL
        AND run_at <= $1::timestamptz
        AND attempts < 5
      ORDER BY run_at ASC
      LIMIT $2
      FOR UPDATE SKIP LOCKED
      `,
      now,
      opts.batchSize,
    );

    const ids = rows.map((r) => String(r.id));
    if (ids.length === 0) return ids;

    await tx.crmFollowupTask.updateMany({
      where: { id: { in: ids } },
      data: {
        processing_at: now,
        processing_by: opts.workerId,
      },
    });

    return ids;
  });

  return ids;
}

async function processTask(taskId: string, workerId: string): Promise<void> {
  const task = await prisma.crmFollowupTask.findUnique({
    where: { id: taskId },
  });
  if (!task) return;

  // If another worker touched it, bail.
  if (task.processing_by && task.processing_by !== workerId) return;

  const payload = (task.payload ?? {}) as any as FollowupPayload;
  const constraints = (task.constraints ?? null) as any as FollowupConstraints | null;

  const chat = await prisma.crmChat.findUnique({
    where: { id: task.chat_id },
    select: {
      id: true,
      empresa_id: true,
      wa_id: true,
      phone: true,
      status: true,
      instancia_id: true,
      last_message_at: true,
    },
  });
  if (!chat) {
    await prisma.crmFollowupTask.update({
      where: { id: taskId },
      data: {
        skipped_at: new Date(),
        skip_reason: 'chat_not_found',
        processing_at: null,
        processing_by: null,
      },
    });
    return;
  }

  // Product constraint uses meta table (optional).
  let productId: string | null = null;
  try {
    const meta = await prisma.$queryRawUnsafe<{ product_id: string | null }[]>(
      `SELECT product_id FROM crm_chat_meta WHERE chat_id = $1::uuid LIMIT 1`,
      chat.id,
    );
    productId = meta?.[0]?.product_id ? String(meta[0].product_id) : null;
  } catch (e) {
    if (!isUndefinedTableError(e, 'crm_chat_meta')) {
      // ignore meta errors
    }
  }

  const requiredStatus = normalizeText(constraints?.status);
  if (requiredStatus && normalizeText(chat.status).toLowerCase() !== requiredStatus.toLowerCase()) {
    await prisma.crmFollowupTask.update({
      where: { id: taskId },
      data: {
        skipped_at: new Date(),
        skip_reason: `status_mismatch:${requiredStatus}`,
        processing_at: null,
        processing_by: null,
      },
    });
    return;
  }

  const requiredProductId = normalizeText(constraints?.productId);
  if (requiredProductId && normalizeText(productId) !== requiredProductId) {
    await prisma.crmFollowupTask.update({
      where: { id: taskId },
      data: {
        skipped_at: new Date(),
        skip_reason: `product_mismatch:${requiredProductId}`,
        processing_at: null,
        processing_by: null,
      },
    });
    return;
  }

  const now = new Date();
  const evo = await getEvolutionClientForInstanceId(chat.instancia_id);

  let sendResult: { messageId: string | null } = { messageId: null };
  let messageType = 'text';
  let textToStore: string | null = null;
  let mediaUrlToStore: string | null = null;

  const pType = payload?.type ?? 'text';
  if (pType === 'image') {
    messageType = 'image';
    const url = normalizeText(payload.mediaUrl);
    if (!url) throw new Error('payload.mediaUrl is required');
    const caption = normalizeText(payload.text);
    sendResult = await evo.sendMedia({
      toWaId: chat.wa_id,
      toPhone: chat.phone ?? undefined,
      mediaUrl: url,
      caption: caption,
      mediaType: 'image',
    });
    textToStore = caption || null;
    mediaUrlToStore = url;
  } else {
    messageType = 'text';
    const text = normalizeText(payload.text);
    if (!text) throw new Error('payload.text is required');
    sendResult = await evo.sendText({
      toWaId: chat.wa_id,
      toPhone: chat.phone ?? undefined,
      text,
    });
    textToStore = text;
  }

  // Persist CRM message + update chat preview.
  await prisma.$transaction(async (tx) => {
    await tx.crmChatMessage.create({
      data: {
        empresa_id: chat.empresa_id,
        chat_id: chat.id,
        direction: 'out',
        message_type: messageType,
        text: textToStore,
        media_url: mediaUrlToStore,
        remote_message_id: sendResult.messageId,
        status: 'sent',
        timestamp: now,
        instancia_id: chat.instancia_id,
      } as any,
    });

    await tx.crmChat.update({
      where: { id: chat.id },
      data: {
        last_message_preview: (textToStore ?? (messageType === 'image' ? '[Imagen]' : '')).slice(0, 180),
        last_message_at: now,
      },
    });

    await tx.crmFollowupTask.update({
      where: { id: taskId },
      data: {
        sent_at: now,
        processing_at: null,
        processing_by: null,
        last_error: null,
      },
    });
  });
}

async function failTask(taskId: string, workerId: string, err: unknown): Promise<void> {
  const message = String((err as any)?.message ?? err ?? 'unknown');
  const now = new Date();
  const backoffMinutes = 2;

  await prisma.crmFollowupTask.update({
    where: { id: taskId },
    data: {
      attempts: { increment: 1 },
      last_error: message.slice(0, 2000),
      // retry later
      run_at: new Date(now.getTime() + backoffMinutes * 60_000),
      processing_at: null,
      processing_by: null,
    } as any,
  });
}

export function startCrmFollowupsWorker(): void {
  const workerId = `crm-followups:${os.hostname()}:${process.pid}`;
  let running = false;

  const tick = async () => {
    if (running) return;
    running = true;
    try {
      // If followups table doesn't exist, don't spam logs.
      try {
        await prisma.$queryRawUnsafe(`SELECT 1 FROM crm_followup_tasks LIMIT 1`);
      } catch (e) {
        if (isUndefinedTableError(e, 'crm_followup_tasks')) return;
        throw e;
      }

      const ids = await enqueueDueTasks({ batchSize: 15, workerId });
      for (const id of ids) {
        try {
          await processTask(id, workerId);
        } catch (e) {
          // eslint-disable-next-line no-console
          console.error('[CRM][FOLLOWUPS] send failed', { id, error: (e as any)?.message ?? String(e) });
          await failTask(id, workerId, e);
        }
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('[CRM][FOLLOWUPS] worker tick failed', safeJson({ error: (e as any)?.message ?? String(e) }));
    } finally {
      running = false;
    }
  };

  // Run quickly after boot, then poll.
  setTimeout(() => void tick(), 5000);
  setInterval(() => void tick(), 15_000);
}

