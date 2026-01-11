const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Client } = require('pg');

function normalizeToLf(text) {
  return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

async function main() {
  // Load env the same way other scripts do
  try {
    require('dotenv').config();
  } catch (_) {
    // ignore
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('DATABASE_URL missing; cannot verify/apply migrations.');
    process.exit(2);
  }

  const migrationFile = '2026-01-04_letters.sql';
  const migrationPath = path.join(__dirname, '..', 'sql', migrationFile);

  if (!fs.existsSync(migrationPath)) {
    console.error(`SQL migration file not found: ${migrationPath}`);
    process.exit(3);
  }

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    const migTable = await client.query(
      "SELECT to_regclass('public._sql_migrations') AS reg",
    );
    const letters = await client.query(
      "SELECT to_regclass('public.letters') AS reg",
    );
    const exports = await client.query(
      "SELECT to_regclass('public.letter_exports') AS reg",
    );

    const migrationsTableExists = !!migTable.rows[0]?.reg;
    const lettersExists = !!letters.rows[0]?.reg;
    const exportsExists = !!exports.rows[0]?.reg;

    let migrationRow = null;
    if (migrationsTableExists) {
      const r = await client.query(
        'SELECT filename, checksum, applied_at FROM _sql_migrations WHERE filename = $1',
        [migrationFile],
      );
      migrationRow = r.rows[0] || null;
    }

    const needsApply = !lettersExists || !exportsExists || !migrationRow;

    console.log(
      JSON.stringify(
        {
          migrationsTable: migrationsTableExists,
          lettersTable: lettersExists,
          letterExportsTable: exportsExists,
          migrationRow,
          needsApply,
        },
        null,
        2,
      ),
    );

    if (!needsApply) {
      console.log('✅ Letters migration already applied.');
      return;
    }

    console.log('🔄 Applying letters migration...');

    // Ensure tracking table exists (matches runSqlMigrations.ts)
    await client.query(`
      CREATE TABLE IF NOT EXISTS _sql_migrations (
        filename text PRIMARY KEY,
        checksum text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      );
    `);

    const rawSql = fs.readFileSync(migrationPath, 'utf8');
    await client.query(rawSql);

    const checksum = sha256(normalizeToLf(rawSql));

    // Upsert record
    await client.query(
      `INSERT INTO _sql_migrations (filename, checksum)
       VALUES ($1, $2)
       ON CONFLICT (filename) DO UPDATE SET checksum = EXCLUDED.checksum`,
      [migrationFile, checksum],
    );

    console.log('✅ Letters migration applied and recorded in _sql_migrations.');
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('❌ Failed:', e);
  process.exit(1);
});
