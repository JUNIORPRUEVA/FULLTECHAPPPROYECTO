import axios, { type AxiosInstance } from 'axios';
import { env } from '../../config/env';

export type EvolutionSendResult = {
  messageId: string | null;
  raw: any;
};

function normalizeDestNumber(opts: { toPhone?: string; toWaId?: string }): string {
  const wa = (opts.toWaId ?? '').trim();
  if (wa) {
    // Typical WhatsApp IDs: "809xxxxxxx@s.whatsapp.net" or "809xxxxxxx@c.us"
    const at = wa.indexOf('@');
    const base = at >= 0 ? wa.slice(0, at) : wa;
    return base.replace(/[^0-9]/g, '') || base;
  }

  const phone = (opts.toPhone ?? '').trim();
  if (!phone) throw new Error('Missing destination (toPhone or toWaId)');
  return phone.replace(/[^0-9]/g, '') || phone;
}

export class EvolutionClient {
  private readonly _http: AxiosInstance;

  constructor() {
    if (!env.EVOLUTION_BASE_URL || env.EVOLUTION_BASE_URL.trim().length === 0) {
      throw new Error('EVOLUTION_BASE_URL is not configured');
    }

    this._http = axios.create({
      baseURL: env.EVOLUTION_BASE_URL,
      timeout: 20000,
      headers: {
        ...(env.EVOLUTION_API_KEY && env.EVOLUTION_API_KEY.trim().length > 0
          ? { apikey: env.EVOLUTION_API_KEY.trim() }
          : null),
        'Content-Type': 'application/json',
      },
    });
  }

  private _instancePath(path: string): string {
    const inst = (env.EVOLUTION_INSTANCE ?? env.EVOLUTION_INSTANCE_ID ?? '').trim();
    if (!inst) return path;

    // Many Evolution API deployments use endpoints like /message/sendText/{instance}
    if (path.includes('{instance}')) return path.replace('{instance}', inst);
    if (path.endsWith('/')) return `${path}${inst}`;
    return `${path}/${inst}`;
  }

  async sendText({
    toPhone,
    toWaId,
    text,
  }: {
    toPhone?: string;
    toWaId?: string;
    text: string;
  }): Promise<EvolutionSendResult> {
    const url = this._instancePath('/message/sendText');

    const number = normalizeDestNumber({ toPhone, toWaId });

    const payload = {
      number,
      textMessage: {
        text,
      },
    };

    const res = await this._http.post(url, payload);
    const raw = res.data;

    const messageId =
      (raw && typeof raw === 'object' &&
      (raw.messageId || raw.message_id || raw.key?.id || raw.data?.key?.id))
        ? String(raw.messageId ?? raw.message_id ?? raw.key?.id ?? raw.data?.key?.id)
        : null;

    return { messageId, raw };
  }

  async sendMedia({
    toPhone,
    toWaId,
    mediaUrl,
    caption,
    mediaType,
  }: {
    toPhone?: string;
    toWaId?: string;
    mediaUrl: string;
    caption?: string;
    mediaType?: string;
  }): Promise<EvolutionSendResult> {
    const url = this._instancePath('/message/sendMedia');

    const number = normalizeDestNumber({ toPhone, toWaId });

    const payload = {
      number,
      mediaMessage: {
        mediatype: mediaType ?? 'image',
        media: mediaUrl,
        caption: caption ?? '',
      },
    };

    const res = await this._http.post(url, payload);
    const raw = res.data;

    const messageId =
      (raw && typeof raw === 'object' &&
      (raw.messageId || raw.message_id || raw.key?.id || raw.data?.key?.id))
        ? String(raw.messageId ?? raw.message_id ?? raw.key?.id ?? raw.data?.key?.id)
        : null;

    return { messageId, raw };
  }
}
