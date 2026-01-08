import dotenv from 'dotenv';

dotenv.config();

function stripWrappingQuotes(value: string): string {
  const v = value.trim();
  if (v.length >= 2) {
    const first = v[0];
    const last = v[v.length - 1];
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      return v.slice(1, -1).trim();
    }
  }
  return v;
}

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required env var: ${key}`);
  }
  return value;
}

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 3000),
  CORS_ORIGIN: (process.env.CORS_ORIGIN ?? 'http://localhost:3000')
    .split(',')
    .map((s) => stripWrappingQuotes(s))
    .filter(Boolean),
  JWT_SECRET: requireEnv('JWT_SECRET'),
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN ?? '7d',
  DATABASE_URL: requireEnv('DATABASE_URL'),

  // Single-tenant convenience: if set, all /auth/register users attach to this Empresa.
  DEFAULT_EMPRESA_ID: process.env.DEFAULT_EMPRESA_ID ?? '',

  // Evolution WhatsApp API integration (optional)
  // Backward compatible aliases:
  // - Some envs use EVOLUTION_API_URL instead of EVOLUTION_BASE_URL
  // - Some envs use EVOLUTION_API_INSTANCE_NAME / EVOLUTION_INSTANCE instead of EVOLUTION_INSTANCE_ID
  EVOLUTION_BASE_URL: process.env.EVOLUTION_BASE_URL ?? process.env.EVOLUTION_API_URL ?? '',
  EVOLUTION_API_KEY: process.env.EVOLUTION_API_KEY ?? '',
  EVOLUTION_INSTANCE: process.env.EVOLUTION_INSTANCE ?? process.env.EVOLUTION_API_INSTANCE_NAME ?? '',
  // Legacy name still supported by code that hasn't been updated yet.
  EVOLUTION_INSTANCE_ID:
    process.env.EVOLUTION_INSTANCE_ID ??
    process.env.EVOLUTION_INSTANCE ??
    process.env.EVOLUTION_API_INSTANCE_NAME ??
    '',

  // Evolution destination formatting
  // For DR/US (NANP) numbers, a common requirement is to send 11 digits (e.g. 1 + 829xxxxxxx).
  EVOLUTION_DEFAULT_COUNTRY_CODE: (process.env.EVOLUTION_DEFAULT_COUNTRY_CODE ?? '1').trim(),
  // Some Evolution deployments accept JIDs as the destination in the "number" field.
  // Default to true to ensure @s.whatsapp.net is added to phone numbers
  EVOLUTION_NUMBER_AS_JID: process.env.EVOLUTION_NUMBER_AS_JID === '0' || process.env.EVOLUTION_NUMBER_AS_JID === 'false'
    ? false
    : true, // Default true

  // Public URL of this backend (used to build absolute media URLs).
  PUBLIC_BASE_URL:
    stripWrappingQuotes(process.env.PUBLIC_BASE_URL ?? '') ||
    `http://localhost:${Number(process.env.PORT ?? 3000)}`,

  // Webhook auth (if Evolution supports a secret).
  WEBHOOK_SECRET: process.env.WEBHOOK_SECRET ?? process.env.EVOLUTION_WEBHOOK_SECRET ?? '',

  // Uploads
  UPLOADS_DIR: process.env.UPLOADS_DIR ?? './uploads',
  MAX_UPLOAD_MB: Number(process.env.MAX_UPLOAD_MB ?? 25),
};
