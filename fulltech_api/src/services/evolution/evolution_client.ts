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

  private _instance(): string {
    return (env.EVOLUTION_INSTANCE ?? env.EVOLUTION_INSTANCE_ID ?? '').trim();
  }

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
    const inst = this._instance();
    if (!inst) return path;

    // Many Evolution API deployments use endpoints like /message/sendText/{instance}
    if (path.includes('{instance}')) return path.replace('{instance}', inst);
    if (path.endsWith('/')) return `${path}${inst}`;
    return `${path}/${inst}`;
  }

  private _formatAxiosError(err: unknown): string {
    if (!axios.isAxiosError(err)) return String((err as any)?.message ?? err);
    const status = err.response?.status;
    const data = err.response?.data;
    let dataPreview = '';
    try {
      if (typeof data === 'string') dataPreview = data.slice(0, 500);
      else if (data != null) dataPreview = JSON.stringify(data).slice(0, 500);
    } catch {
      // ignore
    }
    return `Evolution API error${status ? ` (${status})` : ''}: ${err.message}${dataPreview ? ` | ${dataPreview}` : ''}`;
  }

  private async _postWithInstanceFallback(path: string, payload: any): Promise<any> {
    const inst = this._instance();
    const candidates = inst
      ? [this._instancePath(path), path]
      : [path];

    let lastErr: unknown;
    for (let i = 0; i < candidates.length; i++) {
      const url = candidates[i];
      try {
        const res = await this._http.post(url, payload);
        return res;
      } catch (e) {
        lastErr = e;
        // If the instance-appended route 404s, retry without instance.
        const status = axios.isAxiosError(e) ? e.response?.status : undefined;
        if (status === 404 && i < candidates.length - 1) continue;
        break;
      }
    }

    throw new Error(this._formatAxiosError(lastErr));
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
    const url = '/message/sendText';

    const number = normalizeDestNumber({ toPhone, toWaId });

    const payload = {
      number,
      textMessage: {
        text,
      },
    };

    const res = await this._postWithInstanceFallback(url, payload);
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
    const url = '/message/sendMedia';

    const number = normalizeDestNumber({ toPhone, toWaId });

    const payload = {
      number,
      mediaMessage: {
        mediatype: mediaType ?? 'image',
        media: mediaUrl,
        caption: caption ?? '',
      },
    };

    const res = await this._postWithInstanceFallback(url, payload);
    const raw = res.data;

    const messageId =
      (raw && typeof raw === 'object' &&
      (raw.messageId || raw.message_id || raw.key?.id || raw.data?.key?.id))
        ? String(raw.messageId ?? raw.message_id ?? raw.key?.id ?? raw.data?.key?.id)
        : null;

    return { messageId, raw };
  }
}
