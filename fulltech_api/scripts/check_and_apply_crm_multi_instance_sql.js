/* eslint-disable no-console */

// Verifies and (if needed) applies the CRM multi-instance SQL migration.
//
// Usage:
//   DATABASE_URL=... node scripts/check_and_apply_crm_multi_instance_sql.js
//
// Notes:
// - Uses the same _sql_migrations table as src/scripts/runSqlMigrations.ts
// - Safe to run multiple times.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Client } = require('pg');

const MIGRATION_FILENAME = '2026-01-10_add_crm_multi_instance.sql';
const MIGRATION_PATH = path.resolve(__dirname, '..', 'sql', MIGRATION_FILENAME);

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function normalizeToLf(text) {
  return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('[CRM_MULTI_INSTANCE] DATABASE_URL is missing');
    process.exit(2);
  }

  if (!fs.existsSync(MIGRATION_PATH)) {
    console.error(`[CRM_MULTI_INSTANCE] Migration file not found: ${MIGRATION_PATH}`);
    process.exit(2);
  }

  const rawSql = fs.readFileSync(MIGRATION_PATH, 'utf8');
  const canonicalSql = normalizeToLf(rawSql);
  const checksum = sha256(canonicalSql);

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS _sql_migrations (
        filename text PRIMARY KEY,
        checksum text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      );
    `);

    const tables = await client.query(
      `SELECT
        to_regclass('public.crm_instancias') as crm_instancias,
        to_regclass('public.crm_chat_transfer_events') as crm_chat_transfer_events
      `,
    );

    const existing = await client.query(
      'SELECT filename, checksum, applied_at FROM _sql_migrations WHERE filename = $1',
      [MIGRATION_FILENAME],
    );

    const row = existing.rows[0] || null;
    const alreadyApplied = !!row;

    const needsApply = !alreadyApplied;

    console.log(
      JSON.stringify(
        {
          migration: MIGRATION_FILENAME,
          needsApply,
          alreadyApplied,
          appliedAt: row?.applied_at ?? null,
          checksumMatches: alreadyApplied ? row.checksum === checksum : null,
          tables: tables.rows[0],
        },
        null,
        2,
      ),
    );

    if (!needsApply) return;

    console.log(`[CRM_MULTI_INSTANCE] Applying ${MIGRATION_FILENAME}...`);
    await client.query(canonicalSql);

    await client.query(
      'INSERT INTO _sql_migrations(filename, checksum) VALUES ($1, $2) ON CONFLICT (filename) DO UPDATE SET checksum = EXCLUDED.checksum, applied_at = now()',
      [MIGRATION_FILENAME, checksum],
    );

    console.log('[CRM_MULTI_INSTANCE] Migration applied successfully');
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('[CRM_MULTI_INSTANCE] Failed:', e?.message || e);
  process.exit(1);
});
