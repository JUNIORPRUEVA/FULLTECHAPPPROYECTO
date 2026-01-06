import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { prisma } from '../src/config/prisma';

dotenv.config();

function splitSqlStatements(sql: string): string[] {
  const withoutLineComments = sql
    .split(/\r?\n/)
    .filter((line) => !line.trim().startsWith('--'))
    .join('\n');

  return withoutLineComments
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

async function main() {
  const sqlFilePath = path.resolve(__dirname, '../sql/2026-01-03_ai_settings_and_suggestions.sql');
  const rawSql = fs.readFileSync(sqlFilePath, 'utf8');
  const statements = splitSqlStatements(rawSql);

  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL no está definido. Revisa tu .env.');
  }

  for (const stmt of statements) {
    try {
      await prisma.$executeRawUnsafe(stmt);
    } catch (err: any) {
      const msg = String(err?.message ?? err);

      // If quick_replies table doesn't exist yet, skip altering it.
      if (
        /ALTER\s+TABLE\s+quick_replies/i.test(stmt) &&
        /relation\s+"?quick_replies"?\s+does\s+not\s+exist/i.test(msg)
      ) {
        continue;
      }

      throw err;
    }
  }

  const [check] = await prisma.$queryRawUnsafe<
    Array<{
      ai_settings: boolean;
      ai_suggestions: boolean;
      ai_message_audits: boolean;
    }>
  >(
    `
    SELECT
      EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema='public' AND table_name='ai_settings'
      ) AS ai_settings,
      EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema='public' AND table_name='ai_suggestions'
      ) AS ai_suggestions,
      EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema='public' AND table_name='ai_message_audits'
      ) AS ai_message_audits;
    `
  );

  if (!check?.ai_settings || !check?.ai_suggestions || !check?.ai_message_audits) {
    throw new Error(
      `Migración incompleta. EXISTS: ai_settings=${check?.ai_settings}, ai_suggestions=${check?.ai_suggestions}, ai_message_audits=${check?.ai_message_audits}`
    );
  }

  console.log('OK: Tablas AI listas.');
}

main()
  .catch((e) => {
    console.error('ERROR ejecutando migración AI:', e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
