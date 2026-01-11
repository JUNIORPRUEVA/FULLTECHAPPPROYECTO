import { Client } from 'pg';

const requiredTables = [
  'product_maintenances',
  'warranty_cases',
  'inventory_audits',
  'inventory_audit_items',
] as const;

const requiredEnums = [
  'MaintenanceType',
  'ProductHealthStatus',
  'IssueCategory',
  'WarrantyStatus',
  'AuditStatus',
  'AuditReason',
  'AuditAction',
] as const;

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('[MAINTENANCE:VERIFY] DATABASE_URL is missing');
    process.exit(1);
  }

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    console.log('[MAINTENANCE:VERIFY] Checking required enums...');
    const enumRows = await client.query(
      `SELECT typname FROM pg_type WHERE typname = ANY($1::text[]) ORDER BY typname ASC;`,
      [requiredEnums as unknown as string[]],
    );

    const enumsFound = new Set<string>(enumRows.rows.map((r) => r.typname));
    const enumsMissing = requiredEnums.filter((t) => !enumsFound.has(t));

    console.log(
      `[MAINTENANCE:VERIFY] Enums: found=${enumsFound.size} missing=${enumsMissing.length}`,
    );
    if (enumsMissing.length) {
      console.log(`[MAINTENANCE:VERIFY] Missing enums: ${enumsMissing.join(', ')}`);
    }

    console.log('[MAINTENANCE:VERIFY] Checking required tables...');
    const tableRows = await client.query(
      `SELECT to_regclass(t)::text AS name FROM unnest($1::text[]) AS t;`,
      [requiredTables as unknown as string[]],
    );

    const tablesMissing = tableRows.rows
      .filter((r) => !r.name)
      .map((_, idx) => requiredTables[idx]);

    console.log(
      `[MAINTENANCE:VERIFY] Tables: missing=${tablesMissing.length}/${requiredTables.length}`,
    );
    if (tablesMissing.length) {
      console.log(`[MAINTENANCE:VERIFY] Missing tables: ${tablesMissing.join(', ')}`);
    }

    // Basic smoke queries (fail fast if Prisma will explode later)
    if (tablesMissing.length === 0) {
      console.log('[MAINTENANCE:VERIFY] Running smoke queries...');
      await client.query('SELECT 1 FROM product_maintenances LIMIT 1;');
      await client.query('SELECT 1 FROM warranty_cases LIMIT 1;');
      await client.query('SELECT 1 FROM inventory_audits LIMIT 1;');
      await client.query('SELECT 1 FROM inventory_audit_items LIMIT 1;');
      console.log('[MAINTENANCE:VERIFY] Smoke queries OK');
    }

    if (enumsMissing.length || tablesMissing.length) {
      console.error(
        '[MAINTENANCE:VERIFY] Schema is NOT ready. Run SQL migrations and re-verify.',
      );
      process.exit(2);
    }

    console.log('[MAINTENANCE:VERIFY] Schema OK');
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('[MAINTENANCE:VERIFY] Failed:', e);
  process.exit(1);
});
