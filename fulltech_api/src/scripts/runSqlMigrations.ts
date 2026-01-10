import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { Client } from 'pg';

/**
 * SQL Migrations Runner
 * 
 * Automatically applies .sql files from sql/ directory in alphabetical order.
 * Tracks applied migrations using checksums to prevent re-application and detect edits.
 * 
 * Environment Variables:
 * - SKIP_SQL_MIGRATIONS=true : Disable migrations completely
 * - SQL_MIGRATIONS_STRICT=true : Treat checksum mismatches as errors (recommended for prod/CI)
 * 
 * See SQL_MIGRATIONS_BEST_PRACTICES.md for detailed workflow documentation.
 */

function truthy(value: string | undefined): boolean {
  return ['1', 'true', 'yes', 'on'].includes(String(value ?? '').trim().toLowerCase());
}

function sha256(text: string): string {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function normalizeToLf(text: string): string {
  // Canonicalize line endings so checksums are stable across OSes.
  // This prevents false "edited migration" alarms caused only by CRLF/LF differences.
  return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function toCrlfFromLf(text: string): string {
  // Convert canonical LF text into CRLF (useful to match historical checksums
  // calculated on Windows when the same migration was originally applied).
  return text.replace(/\n/g, '\r\n');
}

export async function runSqlMigrations(options?: {
  migrationsDirAbs?: string;
  databaseUrl?: string;
  enabled?: boolean;
}): Promise<void> {
  const enabled = options?.enabled ?? !truthy(process.env.SKIP_SQL_MIGRATIONS);
  if (!enabled) return;

  const strict = truthy(process.env.SQL_MIGRATIONS_STRICT);

  const databaseUrl = options?.databaseUrl ?? process.env.DATABASE_URL;
  if (!databaseUrl) {
    // eslint-disable-next-line no-console
    console.warn('[SQL_MIGRATIONS] DATABASE_URL is missing; skipping');
    return;
  }

  const migrationsDirAbs =
    options?.migrationsDirAbs ?? path.resolve(process.cwd(), 'sql');

  if (!fs.existsSync(migrationsDirAbs)) {
    // eslint-disable-next-line no-console
    console.warn(`[SQL_MIGRATIONS] Folder not found: ${migrationsDirAbs}; skipping`);
    return;
  }

  const allSqlFiles = fs
    .readdirSync(migrationsDirAbs)
    .filter((f) => f.toLowerCase().endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));

  // Only apply real migrations with a stable, date-prefixed filename.
  // This prevents accidentally executing ad-hoc scripts like "verify_*.sql" on boot.
  const isMigrationFile = (f: string) => /^\d{4}-\d{2}-\d{2}_.+\.sql$/i.test(f);
  const files = allSqlFiles.filter(isMigrationFile);
  const skipped = allSqlFiles.filter((f) => !isMigrationFile(f));

  if (files.length === 0) return;

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    // Create migrations tracking table if it doesn't exist
    // This table stores: filename, checksum (SHA-256), and timestamp
    await client.query(`
      CREATE TABLE IF NOT EXISTS _sql_migrations (
        filename text PRIMARY KEY,
        checksum text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      );
    `);

    // eslint-disable-next-line no-console
    console.log(
      `[SQL_MIGRATIONS] Found ${files.length} migration .sql files` +
        (skipped.length > 0
          ? ` (${skipped.length} non-migration .sql skipped)`
          : ''),
    );

    if (skipped.length > 0) {
      // eslint-disable-next-line no-console
      console.log(
        `[SQL_MIGRATIONS] Skipped non-migration SQL files: ${skipped.join(', ')}`,
      );
    }

    for (const filename of files) {
      const fullPath = path.join(migrationsDirAbs, filename);
      const rawSql = fs.readFileSync(fullPath, 'utf8');
      const canonicalSql = normalizeToLf(rawSql);
      const checksum = sha256(canonicalSql);
      const checksumCrlf = sha256(toCrlfFromLf(canonicalSql));

      // Check if this migration was already applied
      const existing = await client.query(
        'SELECT filename, checksum FROM _sql_migrations WHERE filename = $1',
        [filename],
      );

      // Migration already applied and unchanged - skip silently
      if (existing.rowCount && existing.rows[0].checksum === checksum) {
        continue;
      }

      // If the only difference is line endings (CRLF vs LF), treat as unchanged.
      // Optionally repair the stored checksum to the canonical (LF-normalized) value
      // so future comparisons are stable.
      if (existing.rowCount && existing.rows[0].checksum === checksumCrlf) {
        await client.query(
          'UPDATE _sql_migrations SET checksum = $2 WHERE filename = $1',
          [filename, checksum],
        );

        // eslint-disable-next-line no-console
        console.log(
          `[SQL_MIGRATIONS] Normalized checksum (CRLF->LF) for ${filename}`,
        );
        continue;
      }

      // Migration was applied but file content changed - DANGER ZONE
      if (existing.rowCount && existing.rows[0].checksum !== checksum) {
        const oldChecksum = existing.rows[0].checksum.substring(0, 12);
        const newChecksum = checksum.substring(0, 12);
        
        const msg = [
          `\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`,
          `⚠️  MIGRATION CHECKSUM MISMATCH: ${filename}`,
          `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`,
          ``,
          `This file was edited AFTER it was already applied to the database.`,
          ``,
          `  Applied checksum:  ${oldChecksum}...`,
          `  Current checksum:  ${newChecksum}...`,
          ``,
          `❌ PROBLEM:`,
          `   Editing already-applied migrations can cause:`,
          `   - Schema drift between environments`,
          `   - Lost migration history`,
          `   - Inability to recreate database from scratch`,
          ``,
          `✅ SOLUTION:`,
          `   1. Revert changes to ${filename}`,
          `   2. Create a NEW migration file with today's date:`,
          `      sql/2026-01-${String(new Date().getDate()).padStart(2, '0')}_your_change_description.sql`,
          `   3. Put your schema changes in the new file`,
          ``,
          `💡 TIP: Never edit files in sql/ after they've been applied.`,
          ``,
          `Current behavior: SKIPPING this file (SQL_MIGRATIONS_STRICT=false)`,
          `To make this an error instead, set: SQL_MIGRATIONS_STRICT=true`,
          `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`,
        ].join('\n');

        if (strict) {
          throw new Error(msg);
        }

        // Keep the service booting in non-strict mode, but avoid noisy warnings.
        // If you want a hard failure, set SQL_MIGRATIONS_STRICT=true.
        // eslint-disable-next-line no-console
        console.log(
          `[SQL_MIGRATIONS] Checksum mismatch in ${filename}; skipping (set SQL_MIGRATIONS_STRICT=true to fail)`,
        );
        if (truthy(process.env.SQL_MIGRATIONS_MISMATCH_DETAILS)) {
          // eslint-disable-next-line no-console
          console.log(msg);
        }
        continue;
      }

      // eslint-disable-next-line no-console
      console.log(`[SQL_MIGRATIONS] Applying ${filename}...`);

      // Execute the SQL (no explicit transaction - let the file control it)
      // Many migration files already include BEGIN/COMMIT
      await client.query(rawSql);

      // Record successful application
      await client.query(
        'INSERT INTO _sql_migrations(filename, checksum) VALUES ($1, $2)',
        [filename, checksum],
      );

      // eslint-disable-next-line no-console
      console.log(`[SQL_MIGRATIONS] Applied ${filename}`);
    }
  } finally {
    await client.end();
  }
}
