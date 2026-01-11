import axios, { type AxiosInstance } from 'axios';
import { env } from '../../config/env';

export type EvolutionSendResult = {
  messageId: string | null;
  raw: any;
};

export type EvolutionActionResult = {
  ok: boolean;
  raw: any;
};

function applyDefaultCountryCode(digitsOnly: string, defaultCountryCode: string): string {
  const d = String(digitsOnly ?? '').replace(/\D+/g, '');
  if (!d) return d;
  // If it already looks like E.164 without '+', keep it.
  // For NANP destinations, if we have 10 digits, prefix with default country code.
  if (d.length === 10) {
    const cc = String(defaultCountryCode ?? '1').replace(/\D+/g, '') || '1';
    return `${cc}${d}`;
  }
  return d;
}

function normalizeDestNumber(
  opts: { toPhone?: string; toWaId?: string },
  config: { defaultCountryCode: string; numberAsJid: boolean },
): string {
  const phone = (opts.toPhone ?? '').trim();
  const wa = (opts.toWaId ?? '').trim();

  // IMPORTANT: "@lid" is not a stable/routeable destination for most Evolution deployments.
  // If we have a phone number, prefer it over the LID value.
  if (wa && /@lid$/i.test(wa) && phone) {
    const digits = phone.replace(/[^0-9]/g, '') || phone;
    const normalized = applyDefaultCountryCode(digits, config.defaultCountryCode);
    return config.numberAsJid ? `${normalized}@s.whatsapp.net` : normalized;
  }

  if (wa) {
    // Typical WhatsApp IDs: "809xxxxxxx@s.whatsapp.net" or "809xxxxxxx@c.us" or "1203...@g.us"
    const at = wa.indexOf('@');
    const base = at >= 0 ? wa.slice(0, at) : wa;
    const digits = base.replace(/[^0-9]/g, '') || base;
    const normalized = applyDefaultCountryCode(digits, config.defaultCountryCode);
    return config.numberAsJid ? `${normalized}@s.whatsapp.net` : normalized;
  }

  if (!phone) throw new Error('Missing destination (toPhone or toWaId)');
  const digits = phone.replace(/[^0-9]/g, '') || phone;
  const normalized = applyDefaultCountryCode(digits, config.defaultCountryCode);
  return config.numberAsJid ? `${normalized}@s.whatsapp.net` : normalized;
}

export class EvolutionClient {
  private readonly _http: AxiosInstance;
  private readonly _instanceName: string;
  private readonly _defaultCountryCode: string;
  private readonly _numberAsJid: boolean;

  private _instance(): string {
    return this._instanceName;
  }

  constructor(options?: {
    baseUrl?: string;
    apiKey?: string;
    instanceName?: string;
    defaultCountryCode?: string;
    numberAsJid?: boolean;
  }) {
    const baseUrl = String(options?.baseUrl ?? env.EVOLUTION_BASE_URL ?? '').trim();
    if (!baseUrl) {
      throw new Error('EVOLUTION_BASE_URL is not configured');
    }

    this._instanceName = String(options?.instanceName ?? env.EVOLUTION_INSTANCE ?? env.EVOLUTION_INSTANCE_ID ?? '').trim();
    this._defaultCountryCode = String(options?.defaultCountryCode ?? env.EVOLUTION_DEFAULT_COUNTRY_CODE ?? '1').trim();
    this._numberAsJid = Boolean(options?.numberAsJid ?? env.EVOLUTION_NUMBER_AS_JID);

    const apiKey = String(options?.apiKey ?? env.EVOLUTION_API_KEY ?? '').trim();
    this._http = axios.create({
      baseURL: baseUrl,
      timeout: 20000,
      headers: {
        ...(apiKey
          ? { apikey: apiKey }
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

  private async _postCandidates(paths: string[], payloads: any[]): Promise<any> {
    let lastErr: unknown;
    for (const path of paths) {
      for (const payload of payloads) {
        try {
          return await this._postWithInstanceFallback(path, payload);
        } catch (e) {
          lastErr = e;
          // Try next candidate
        }
      }
    }
    throw lastErr ?? new Error('Evolution request failed');
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

    const number = normalizeDestNumber(
      { toPhone, toWaId },
      { defaultCountryCode: this._defaultCountryCode, numberAsJid: this._numberAsJid },
    );

    const trimmed = String(text ?? '').trim();
    if (!trimmed) throw new Error('Text message is empty');

    const payload = {
      number,
      // Evolution deployments commonly expect a root-level "text".
      text: trimmed,
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

    const number = normalizeDestNumber(
      { toPhone, toWaId },
      { defaultCountryCode: this._defaultCountryCode, numberAsJid: this._numberAsJid },
    );

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

  async sendDocumentBase64({
    toPhone,
    toWaId,
    base64,
    fileName,
    caption,
    mimeType,
  }: {
    toPhone?: string;
    toWaId?: string;
    base64: string;
    fileName: string;
    caption?: string;
    mimeType?: string;
  }): Promise<EvolutionSendResult> {
    const trimmedB64 = String(base64 ?? '').trim();
    if (!trimmedB64) throw new Error('base64 is required');

    const name = String(fileName ?? '').trim() || 'document.pdf';
    const mt = String(mimeType ?? '').trim() || 'application/pdf';
    const number = normalizeDestNumber(
      { toPhone, toWaId },
      { defaultCountryCode: this._defaultCountryCode, numberAsJid: this._numberAsJid },
    );

    // Many Evolution deployments accept either raw base64, or a data URL.
    const dataUrl = trimmedB64.startsWith('data:')
      ? trimmedB64
      : `data:${mt};base64,${trimmedB64}`;

    // Try common endpoints and payload formats.
    const paths = [
      '/message/sendMedia',
      '/message/sendDocument',
      '/message/sendFile',
      '/message/sendBase64',
      '/message/sendDocumentBase64',
    ];

    const payloads = [
      {
        number,
        mediaMessage: {
          mediatype: 'document',
          media: dataUrl,
          caption: caption ?? '',
          fileName: name,
          mimetype: mt,
        },
      },
      {
        number,
        mediaMessage: {
          mediatype: 'document',
          media: trimmedB64,
          caption: caption ?? '',
          fileName: name,
          mimetype: mt,
        },
      },
      {
        number,
        mediatype: 'document',
        media: dataUrl,
        caption: caption ?? '',
        fileName: name,
        mimetype: mt,
      },
      {
        number,
        mediatype: 'document',
        media: trimmedB64,
        caption: caption ?? '',
        fileName: name,
        mimetype: mt,
      },
      {
        number,
        base64: trimmedB64,
        fileName: name,
        mimetype: mt,
        caption: caption ?? '',
      },
      {
        number,
        document: trimmedB64,
        fileName: name,
        mimetype: mt,
        caption: caption ?? '',
      },
      {
        number,
        data: trimmedB64,
        fileName: name,
        mimetype: mt,
        caption: caption ?? '',
      },
    ];

    const res = await this._postCandidates(paths, payloads);
    const raw = res.data;

    const messageId =
      (raw && typeof raw === 'object' &&
      (raw.messageId || raw.message_id || raw.key?.id || raw.data?.key?.id))
        ? String(raw.messageId ?? raw.message_id ?? raw.key?.id ?? raw.data?.key?.id)
        : null;

    return { messageId, raw };
  }

  async deleteMessage({
    remoteMessageId,
    toPhone,
    toWaId,
  }: {
    remoteMessageId: string;
    toPhone?: string;
    toWaId?: string;
  }): Promise<EvolutionActionResult> {
    const id = String(remoteMessageId ?? '').trim();
    if (!id) throw new Error('remoteMessageId is required');

    // Some Evolution deployments need the chat JID/number for delete operations.
    // We'll provide both "number" (normalized destination) and "remoteJid".
    const number = normalizeDestNumber(
      { toPhone, toWaId },
      { defaultCountryCode: this._defaultCountryCode, numberAsJid: this._numberAsJid },
    );
    const remoteJid = (toWaId ?? '').trim();

    const paths = [
      '/message/delete',
      '/message/deleteMessage',
      '/message/revoke',
      '/chat/deleteMessage',
      '/chat/revokeMessage',
    ];

    const payloads = [
      { id, number },
      { messageId: id, number },
      { remoteMessageId: id, number },
      { id, remoteJid: remoteJid || undefined },
      { messageId: id, remoteJid: remoteJid || undefined },
      { key: { id, remoteJid: remoteJid || undefined }, number },
      { message: { key: { id, remoteJid: remoteJid || undefined } }, number },
    ];

    const res = await this._postCandidates(paths, payloads);
    return { ok: true, raw: res.data };
  }

  async editTextMessage({
    remoteMessageId,
    toPhone,
    toWaId,
    text,
  }: {
    remoteMessageId: string;
    toPhone?: string;
    toWaId?: string;
    text: string;
  }): Promise<EvolutionActionResult> {
    const id = String(remoteMessageId ?? '').trim();
    if (!id) throw new Error('remoteMessageId is required');
    const trimmed = String(text ?? '').trim();
    if (!trimmed) throw new Error('Text is empty');

    const number = normalizeDestNumber(
      { toPhone, toWaId },
      { defaultCountryCode: this._defaultCountryCode, numberAsJid: this._numberAsJid },
    );
    const remoteJid = (toWaId ?? '').trim();

    const paths = [
      '/message/edit',
      '/message/editText',
      '/message/updateText',
      '/message/updateMessage',
    ];

    const payloads = [
      { id, number, text: trimmed },
      { messageId: id, number, text: trimmed },
      { remoteMessageId: id, number, text: trimmed },
      { id, remoteJid: remoteJid || undefined, text: trimmed },
      { messageId: id, remoteJid: remoteJid || undefined, text: trimmed },
      { key: { id, remoteJid: remoteJid || undefined }, number, text: trimmed },
      { message: { key: { id, remoteJid: remoteJid || undefined } }, number, text: trimmed },
    ];

    const res = await this._postCandidates(paths, payloads);
    return { ok: true, raw: res.data };
  }
}
