import dotenv from 'dotenv';

dotenv.config();

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
    .map((s) => s.trim())
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

  // Public URL of this backend (used to build absolute media URLs).
  PUBLIC_BASE_URL:
    (process.env.PUBLIC_BASE_URL ?? '').trim() ||
    `http://localhost:${Number(process.env.PORT ?? 3000)}`,

  // Webhook auth (if Evolution supports a secret).
  WEBHOOK_SECRET: process.env.WEBHOOK_SECRET ?? process.env.EVOLUTION_WEBHOOK_SECRET ?? '',

  // Uploads
  UPLOADS_DIR: process.env.UPLOADS_DIR ?? './uploads',
  MAX_UPLOAD_MB: Number(process.env.MAX_UPLOAD_MB ?? 25),
};
