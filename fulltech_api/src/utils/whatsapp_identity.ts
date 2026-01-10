import { env } from '../config/env';

function digitsOnly(v: string | null | undefined): string {
  return String(v ?? '').replace(/\D+/g, '');
}

function applyDefaultCountryCode(digits: string): string {
  const d = digitsOnly(digits);
  if (!d) return d;
  if (d.length === 10) {
    const cc = digitsOnly(env.EVOLUTION_DEFAULT_COUNTRY_CODE ?? '1') || '1';
    return `${cc}${d}`;
  }
  return d;
}

export function phoneDigitsFromWaId(waId: string): string | null {
  const raw = String(waId ?? '').trim();
  if (!raw) return null;
  const at = raw.indexOf('@');
  const base = at >= 0 ? raw.slice(0, at) : raw;
  const digits = digitsOnly(base);
  return digits ? digits : null;
}

export function normalizePhoneToE164Digits(raw: string | null | undefined): string | null {
  const d = digitsOnly(raw);
  if (!d) return null;
  return applyDefaultCountryCode(d);
}

/**
 * Canonicalize any WA identity (waId or phone) to:
 * - waId: `${e164Digits}@s.whatsapp.net` when digits are available
 * - phoneE164Digits: e164Digits (no '+')
 */
export function normalizeWhatsAppIdentity(input: {
  waId?: string | null;
  phone?: string | null;
}): { waId: string | null; phoneE164Digits: string | null } {
  const waRaw = String(input.waId ?? '').trim();
  const phoneRaw = String(input.phone ?? '').trim();

  // Prefer waId if present.
  if (waRaw) {
    const phoneDigits = phoneDigitsFromWaId(waRaw);
    if (phoneDigits) {
      const e164 = applyDefaultCountryCode(phoneDigits);
      return { waId: `${e164}@s.whatsapp.net`, phoneE164Digits: e164 };
    }
    // Non-numeric JIDs (e.g. some @lid variants): keep raw.
    return { waId: waRaw, phoneE164Digits: normalizePhoneToE164Digits(phoneRaw) };
  }

  const e164 = normalizePhoneToE164Digits(phoneRaw);
  if (!e164) return { waId: null, phoneE164Digits: null };
  return { waId: `${e164}@s.whatsapp.net`, phoneE164Digits: e164 };
}
