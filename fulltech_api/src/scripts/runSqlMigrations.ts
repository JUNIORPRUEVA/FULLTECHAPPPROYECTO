import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { Client } from 'pg';

function truthy(value: string | undefined): boolean {
  return ['1', 'true', 'yes', 'on'].includes(String(value ?? '').trim().toLowerCase());
}

function sha256(text: string): string {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

export async function runSqlMigrations(options?: {
  migrationsDirAbs?: string;
  databaseUrl?: string;
  enabled?: boolean;
}): Promise<void> {
  const enabled = options?.enabled ?? !truthy(process.env.SKIP_SQL_MIGRATIONS);
  if (!enabled) return;

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

  const files = fs
    .readdirSync(migrationsDirAbs)
    .filter((f) => f.toLowerCase().endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));

  if (files.length === 0) return;

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

    // eslint-disable-next-line no-console
    console.log(`[SQL_MIGRATIONS] Found ${files.length} .sql files`);

    for (const filename of files) {
      const fullPath = path.join(migrationsDirAbs, filename);
      const rawSql = fs.readFileSync(fullPath, 'utf8');
      const checksum = sha256(rawSql);

      const existing = await client.query(
        'SELECT filename, checksum FROM _sql_migrations WHERE filename = $1',
        [filename],
      );

      if (existing.rowCount && existing.rows[0].checksum === checksum) {
        continue;
      }

      if (existing.rowCount && existing.rows[0].checksum !== checksum) {
        throw new Error(
          `[SQL_MIGRATIONS] Checksum changed for ${filename}. ` +
            'Refusing to run automatically; rename the file or revert changes.',
        );
      }

      // eslint-disable-next-line no-console
      console.log(`[SQL_MIGRATIONS] Applying ${filename}...`);

      // Important: do NOT wrap in a transaction here. Some scripts already include BEGIN/COMMIT.
      await client.query(rawSql);

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
