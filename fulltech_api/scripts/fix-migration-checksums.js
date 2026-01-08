#!/usr/bin/env node

/**
 * EMERGENCY FIX: Update checksums for already-applied migrations
 * 
 * USE ONLY WHEN:
 * - Migration files were edited AFTER being applied (bad practice, but it happened)
 * - The changes are already in the database
 * - You need to sync checksums to match current file state
 * 
 * This script:
 * 1. Reads all .sql files in sql/
 * 2. Calculates their current checksums
 * 3. Updates the _sql_migrations table with new checksums
 * 
 * WARNING: This hides migration history. Only use if absolutely necessary.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Client } = require('pg');

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('❌ DATABASE_URL environment variable is required');
    process.exit(1);
  }

  const sqlDir = path.resolve(__dirname, '../sql');
  if (!fs.existsSync(sqlDir)) {
    console.error(`❌ SQL directory not found: ${sqlDir}`);
    process.exit(1);
  }

  const files = fs
    .readdirSync(sqlDir)
    .filter((f) => f.toLowerCase().endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));

  if (files.length === 0) {
    console.log('No .sql files found');
    return;
  }

  console.log(`\n⚠️  WARNING: This will UPDATE checksums for ${files.length} migration files`);
  console.log('This should ONLY be used when:');
  console.log('  - Files were edited after being applied (bad practice!)');
  console.log('  - Changes are already in the database');
  console.log('  - You need to sync checksums to match current state\n');
  
  console.log('Files that will be updated:');
  files.forEach(f => console.log(`  - ${f}`));
  
  console.log('\nWaiting 5 seconds... Press Ctrl+C to cancel\n');
  await new Promise(resolve => setTimeout(resolve, 5000));

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    let updated = 0;
    let inserted = 0;
    let skipped = 0;

    for (const filename of files) {
      const fullPath = path.join(sqlDir, filename);
      const rawSql = fs.readFileSync(fullPath, 'utf8');
      const checksum = sha256(rawSql);

      const existing = await client.query(
        'SELECT filename, checksum FROM _sql_migrations WHERE filename = $1',
        [filename]
      );

      if (existing.rowCount === 0) {
        // Not in DB yet - insert it
        await client.query(
          'INSERT INTO _sql_migrations(filename, checksum) VALUES ($1, $2)',
          [filename, checksum]
        );
        console.log(`✅ INSERTED: ${filename} (${checksum.substring(0, 12)}...)`);
        inserted++;
      } else if (existing.rows[0].checksum !== checksum) {
        // Checksum mismatch - update it
        await client.query(
          'UPDATE _sql_migrations SET checksum = $1 WHERE filename = $2',
          [checksum, filename]
        );
        const oldSum = existing.rows[0].checksum.substring(0, 12);
        const newSum = checksum.substring(0, 12);
        console.log(`🔄 UPDATED: ${filename}`);
        console.log(`   Old: ${oldSum}...`);
        console.log(`   New: ${newSum}...`);
        updated++;
      } else {
        // Already matches
        skipped++;
      }
    }

    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`✅ SUMMARY:`);
    console.log(`   Updated:  ${updated}`);
    console.log(`   Inserted: ${inserted}`);
    console.log(`   Skipped:  ${skipped}`);
    console.log(`   Total:    ${files.length}`);
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

    if (updated > 0) {
      console.log('⚠️  REMINDER: Edited migrations are a code smell.');
      console.log('Next time, create NEW migration files instead of editing old ones.');
      console.log('See SQL_MIGRATIONS_BEST_PRACTICES.md for proper workflow.\n');
    }

  } finally {
    await client.end();
  }
}

main().catch(err => {
  console.error('❌ Error:', err);
  process.exit(1);
});
