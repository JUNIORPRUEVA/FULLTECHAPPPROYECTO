#!/usr/bin/env node

/**
 * Helper script to create new SQL migration files with proper naming
 * 
 * Usage:
 *   npm run migrate:new add_user_status_column
 *   npm run migrate:new "create orders table"
 * 
 * Creates: sql/YYYY-MM-DD_description.sql
 */

const fs = require('fs');
const path = require('path');

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    console.log(`
Usage: npm run migrate:new <description>

Creates a new SQL migration file with the current date.

Examples:
  npm run migrate:new add_user_status_column
  npm run migrate:new "create orders table"
  npm run migrate:new fix_crm_indexes

The file will be created in: sql/YYYY-MM-DD_description.sql
`);
    process.exit(args[0] === '--help' || args[0] === '-h' ? 0 : 1);
  }

  const description = args.join('_').replace(/[^a-z0-9_]/gi, '_').toLowerCase();
  
  if (!description || description.length < 3) {
    console.error('Error: Description must be at least 3 characters');
    process.exit(1);
  }

  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  
  const filename = `${year}-${month}-${day}_${description}.sql`;
  const sqlDir = path.resolve(__dirname, '../sql');
  const filepath = path.join(sqlDir, filename);

  if (fs.existsSync(filepath)) {
    console.error(`Error: File already exists: ${filename}`);
    console.error('Choose a different description or check if you already created this migration.');
    process.exit(1);
  }

  // Ensure sql/ directory exists
  if (!fs.existsSync(sqlDir)) {
    fs.mkdirSync(sqlDir, { recursive: true });
  }

  const template = `-- ${filename}
-- Purpose: [Describe what this migration does]
-- Author: [Your name]
-- Date: ${year}-${month}-${day}

-- Example: Add a new column
-- ALTER TABLE users ADD COLUMN status text DEFAULT 'active';

-- Example: Create a new table
-- CREATE TABLE IF NOT EXISTS user_preferences (
--   user_id bigint PRIMARY KEY REFERENCES users(id),
--   theme text DEFAULT 'light',
--   language text DEFAULT 'es',
--   created_at timestamptz DEFAULT now()
-- );

-- Example: Create an index
-- CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- TODO: Write your migration SQL here

`;

  fs.writeFileSync(filepath, template, 'utf8');
  
  console.log(`✅ Created migration file: ${filename}`);
  console.log('');
  console.log(`Next steps:`);
  console.log(`  1. Edit the file: ${filepath}`);
  console.log(`  2. Write your SQL migration code`);
  console.log(`  3. Test locally: npm run dev`);
  console.log(`  4. Commit: git add ${path.relative(process.cwd(), filepath)}`);
  console.log('');
  console.log('💡 Remember: Once applied, NEVER edit this file. Create a new one instead.');
}

main();
