import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrate() {
  try {
    console.log('Starting migration from thread_id to chat_id...');
    
    // 1. Check if thread_id exists
    const checkColumn = await prisma.$queryRaw<any[]>`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'crm_messages' 
        AND column_name = 'thread_id'
    `;
    
    if (checkColumn.length === 0) {
      console.log('✓ Migration already applied (thread_id column does not exist)');
      return;
    }
    
    console.log('thread_id column found, proceeding with migration...');
    
    // 2. Rename thread_id to chat_id
    console.log('[1/9] Renaming thread_id to chat_id...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages RENAME COLUMN thread_id TO chat_id');
    
    // 3. Add direction column
    console.log('[2/9] Adding direction column...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD COLUMN direction TEXT');
    
    // 4. Populate direction from from_me
    console.log('[3/9] Populating direction from from_me...');
    await prisma.$executeRawUnsafe("UPDATE crm_messages SET direction = CASE WHEN from_me THEN 'out' ELSE 'in' END");
    
    // 5. Make direction NOT NULL
    console.log('[4/9] Making direction NOT NULL...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ALTER COLUMN direction SET NOT NULL');
    
    // 6. Rename type to message_type
    console.log('[5/9] Renaming type to message_type...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages RENAME COLUMN type TO message_type');
    
    // 7. Rename body to text
    console.log('[6/9] Renaming body to text...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages RENAME COLUMN body TO text');
    
    // 8. Add media columns
    console.log('[7/9] Adding media columns...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_mime TEXT');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_size INT');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_url TEXT');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_filename TEXT');
    
    // 9. Drop from_me column
    console.log('[8/9] Dropping from_me column...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP COLUMN IF EXISTS from_me');
    
    // 10. Update foreign key constraint
    console.log('[9/9] Updating foreign key constraint...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP CONSTRAINT IF EXISTS crm_messages_thread_id_fkey');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD CONSTRAINT crm_messages_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES crm_chats(id) ON DELETE CASCADE');
    
    console.log('✅ Migration completed successfully!');
    console.log('The table crm_messages now uses:');
    console.log('  - chat_id (instead of thread_id)');
    console.log('  - direction (instead of from_me)');
    console.log('  - message_type (instead of type)');
    console.log('  - text (instead of body)');
    console.log('  - media_mime, media_size, media_url, media_filename (new)');
    
  } catch (error: any) {
    console.error('❌ Error during migration:', error.message);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

migrate()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
