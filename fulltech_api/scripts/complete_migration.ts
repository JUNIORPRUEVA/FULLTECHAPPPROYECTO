import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function completeMigration() {
  try {
    console.log('Completing migration from thread_id to chat_id...');
    
    // 1. Copy thread_id to chat_id if null
    console.log('[1/9] Copying thread_id to chat_id where null...');
    await prisma.$executeRawUnsafe('UPDATE crm_messages SET chat_id = thread_id WHERE chat_id IS NULL');
    
    // 2. Make chat_id NOT NULL
    console.log('[2/9] Making chat_id NOT NULL...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ALTER COLUMN chat_id SET NOT NULL');
    
    // 3. Copy from_me to direction if null
    console.log('[3/9] Copying from_me to direction where null...');
    await prisma.$executeRawUnsafe("UPDATE crm_messages SET direction = CASE WHEN from_me THEN 'out' ELSE 'in' END WHERE direction IS NULL");
    
    // 4. Make direction NOT NULL
    console.log('[4/9] Making direction NOT NULL...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ALTER COLUMN direction SET NOT NULL');
    
    // 5. Copy type to message_type if null
    console.log('[5/9] Copying type to message_type where null...');
    await prisma.$executeRawUnsafe('UPDATE crm_messages SET message_type = type WHERE message_type IS NULL');
    
    // 6. Make message_type NOT NULL
    console.log('[6/9] Making message_type NOT NULL...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ALTER COLUMN message_type SET NOT NULL');
    
    // 7. Copy body to text if null
    console.log('[7/9] Copying body to text where null...');
    await prisma.$executeRawUnsafe('UPDATE crm_messages SET text = body WHERE text IS NULL AND body IS NOT NULL');
    
    // 8. Drop old columns
    console.log('[8/9] Dropping old columns (thread_id, from_me, type, body)...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP COLUMN IF EXISTS thread_id');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP COLUMN IF EXISTS from_me');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP COLUMN IF EXISTS type');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP COLUMN IF EXISTS body');
    
    // 9. Update foreign key
    console.log('[9/9] Updating foreign key constraint...');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP CONSTRAINT IF EXISTS crm_messages_thread_id_fkey');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages DROP CONSTRAINT IF EXISTS crm_messages_chat_id_fkey');
    await prisma.$executeRawUnsafe('ALTER TABLE crm_messages ADD CONSTRAINT crm_messages_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES crm_chats(id) ON DELETE CASCADE');
    
    console.log('\n✅ Migration completed successfully!');
    console.log('The table crm_messages now uses:');
    console.log('  - chat_id (thread_id removed)');
    console.log('  - direction (from_me removed)');
    console.log('  - message_type (type removed)');
    console.log('  - text (body removed)');
    
  } catch (error: any) {
    console.error('❌ Error during migration:', error.message);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

completeMigration()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
