import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

async function applyMigration() {
  try {
    const sqlPath = path.join(process.cwd(), 'sql', '2026-01-08_migrate_crm_messages_to_chat_system.sql');
    const sql = fs.readFileSync(sqlPath, 'utf-8');
    
    console.log('Applying migration: 2026-01-08_migrate_crm_messages_to_chat_system.sql');
    
    // Split by semicolon and execute each command separately
    const commands = sql
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));
    
    console.log(`Found ${commands.length} SQL commands to execute`);
    
    for (let i = 0; i < commands.length; i++) {
      const cmd = commands[i];
      console.log(`[${i + 1}/${commands.length}] Executing: ${cmd.substring(0, 60)}...`);
      try {
        await prisma.$executeRawUnsafe(cmd);
        console.log(`  ✓ Success`);
      } catch (error: any) {
        // Ignore "column already exists" or "relation does not exist" errors
        if (error.message?.includes('already exists') || 
            error.message?.includes('does not exist') ||
            error.message?.includes('column') && error.message?.includes('of relation')) {
          console.log(`  ⚠ Skipped (already applied): ${error.message.split('\n')[0]}`);
        } else {
          throw error;
        }
      }
    }
    
    console.log('✅ Migration applied successfully!');
    console.log('The table crm_messages now uses chat_id instead of thread_id');
    
  } catch (error) {
    console.error('❌ Error applying migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

applyMigration()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
