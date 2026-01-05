type AnyObj = Record<string, any>;

export type ParsedEvolutionWebhook =
  | {
      kind: 'message';
      eventType: string | null;
      waId: string | null;
      phoneNumber: string | null;
      displayName: string | null;
      messageId: string | null;
      type: string;
      body: string | null;
      mediaUrl: string | null;
      mediaMime: string | null;
      timestamp: Date | null;
      fromMe: boolean;
    }
  | {
      kind: 'status';
      eventType: string | null;
      messageId: string | null;
      status: 'sent' | 'delivered' | 'read' | 'failed' | null;
      error: string | null;
      timestamp: Date | null;
    }
  | {
      kind: 'unknown';
      eventType: string | null;
    };

function asString(v: any): string | null {
  if (typeof v === 'string') return v;
  if (typeof v === 'number') return String(v);
  return null;
}

function normalizePhone(raw: string | null): string | null {
  if (!raw) return null;
  const s = raw.trim();
  if (!s) return null;

  // Common Evolution/Baileys formats:
  // - "809xxxxxxx"
  // - "809xxxxxxx@s.whatsapp.net"
  // - "809xxxxxxx@c.us"
  // - "+1(809)xxx-xxxx"
  const at = s.indexOf('@');
  const base = at >= 0 ? s.slice(0, at) : s;
  const digits = base.replace(/[^0-9]/g, '');
  return digits.length > 0 ? digits : null;
}

function parseEpochish(v: any): Date | null {
  if (v == null) return null;
  if (v instanceof Date) return v;
  if (typeof v === 'string') {
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof v === 'number') {
    // seconds vs ms
    const ms = v < 10_000_000_000 ? v * 1000 : v;
    const d = new Date(ms);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

function pickTextMessage(message: AnyObj | null): string | null {
  if (!message) return null;

  // Baileys/Evolution typical
  const conversation = asString(message.conversation);
  if (conversation) return conversation;

  const ext = message.extendedTextMessage;
  const extText = ext ? asString(ext.text) : null;
  if (extText) return extText;

  // Some webhooks might send { text: { body: "..." } }
  const text = message.text;
  const textBody = text ? asString(text.body ?? text.text) : null;
  if (textBody) return textBody;

  // Or { body: "..." }
  const body = asString(message.body);
  if (body) return body;

  return null;
}

function pickMediaUrl(message: AnyObj | null): { url: string | null; type: string | null } {
  if (!message) return { url: null, type: null };

  const candidates = [
    { key: 'imageMessage', type: 'image' },
    { key: 'videoMessage', type: 'video' },
    { key: 'audioMessage', type: 'audio' },
    { key: 'documentMessage', type: 'document' },
  ] as const;

  for (const c of candidates) {
    const node = message[c.key];
    if (!node || typeof node !== 'object') continue;

    const url = asString(node.url ?? node.directPath ?? node.mediaUrl);
    if (url) return { url, type: c.type };
  }

  // Some configs may emit media_url directly
  const mediaUrl = asString(message.media_url ?? message.mediaUrl);
  if (mediaUrl) return { url: mediaUrl, type: asString(message.type) };

  return { url: null, type: null };
}

function pickMediaMime(message: AnyObj | null): string | null {
  if (!message) return null;
  const candidates = ['imageMessage', 'videoMessage', 'audioMessage', 'documentMessage'];
  for (const key of candidates) {
    const node = message[key];
    if (!node || typeof node !== 'object') continue;
    const mime = asString(node.mimetype ?? node.mimeType ?? node.mimetype);
    if (mime) return mime;
  }
  return asString((message as any).mimetype ?? (message as any).mimeType);
}

function normalizeStatus(raw: string | null): 'sent' | 'delivered' | 'read' | 'failed' | null {
  if (!raw) return null;
  const s = raw.toLowerCase().trim();
  if (['sent', 'enviado'].includes(s)) return 'sent';
  if (['delivered', 'entregado', 'delivery'].includes(s)) return 'delivered';
  if (['read', 'leido', 'leído', 'seen'].includes(s)) return 'read';
  if (['failed', 'error', 'fail'].includes(s)) return 'failed';
  return null;
}

export function parseEvolutionWebhook(body: AnyObj): ParsedEvolutionWebhook {
  // Try to support multiple shapes without hard-coding a single event schema.
  const data = (body.data && typeof body.data === 'object') ? (body.data as AnyObj) : body;

  const eventType = asString(body.event ?? body.type ?? data.event ?? data.type);

  // Status-like events
  const statusRaw = asString(data.status ?? data.messageStatus ?? data.state);
  const status = normalizeStatus(statusRaw);
  const statusMessageId = asString(
    data.messageId ?? data.message_id ?? data.id ?? data.key?.id ?? data.data?.key?.id,
  );
  if (status && statusMessageId) {
    return {
      kind: 'status',
      eventType,
      messageId: statusMessageId,
      status,
      error: asString(data.error ?? data.reason ?? data.message),
      timestamp: parseEpochish(data.timestamp ?? data.time ?? data.created_at),
    };
  }

  const key = (data.key && typeof data.key === 'object') ? (data.key as AnyObj) : null;
  const message = (data.message && typeof data.message === 'object') ? (data.message as AnyObj) : null;

  const fromMe = Boolean(key?.fromMe ?? data.fromMe ?? data.from_me ?? false);

  // Evolution payloads often include both a JID (sometimes "@lid") and a clearer phone field.
  // Prefer sender/destination to derive a stable phone number so inbound/outbound messages
  // land in the same chat.
  const remoteJidRaw = asString(
    key?.remoteJid ??
      data.remoteJid ??
      data.from ??
      data.sender ??
      (body as any)?.from ??
      (body as any)?.sender ??
      data.phone_number ??
      (body as any)?.phone_number,
  );

  const pickPhoneFrom = (candidates: Array<any>): string | null => {
    for (const c of candidates) {
      const s = asString(c);
      if (!s) continue;
      // If the value itself is a LID JID, skip it as a "phone" hint.
      if (/@lid$/i.test(s.trim())) continue;
      const p = normalizePhone(s);
      if (p) return p;
    }
    return null;
  };

  const phoneNumber = fromMe
    ? (pickPhoneFrom([
        data.destination,
        (body as any)?.destination,
        data.to,
        (body as any)?.to,
      ]) ?? normalizePhone(remoteJidRaw))
    : (pickPhoneFrom([
        data.sender,
        (body as any)?.sender,
        data.from,
        (body as any)?.from,
      ]) ?? normalizePhone(remoteJidRaw));

  // Canonicalize waId: if Evolution sends "@lid" ids, but we do have a phone number,
  // use the stable WhatsApp JID format so the chat is consistent.
  const remoteJid = (() => {
    if (phoneNumber) {
      if (remoteJidRaw && /@lid$/i.test(remoteJidRaw)) return `${phoneNumber}@s.whatsapp.net`;
      if (!remoteJidRaw) return `${phoneNumber}@s.whatsapp.net`;
    }
    return remoteJidRaw;
  })();

  const displayName =
    asString(data.pushName ?? data.display_name ?? data.senderName ?? data.notifyName) ?? null;

  const messageId = asString(key?.id ?? data.message_id ?? data.messageId ?? data.id) ?? null;

  const textBody = pickTextMessage(message);
  const media = pickMediaUrl(message);
  const mediaMime = pickMediaMime(message);

  const type =
    asString(data.type) ??
    media.type ??
    (textBody ? 'text' : 'unknown');

  const timestamp = parseEpochish(
    data.messageTimestamp ?? data.timestamp ?? data.time ?? data.created_at,
  );

  // If it doesn't look like a message, mark unknown.
  if (!remoteJid && !messageId && !textBody && !media.url) {
    return { kind: 'unknown', eventType };
  }

  return {
    kind: 'message',
    eventType,
    waId: remoteJid,
    phoneNumber,
    displayName,
    messageId,
    type,
    body: textBody,
    mediaUrl: media.url,
    mediaMime,
    timestamp,
    fromMe,
  };
}
