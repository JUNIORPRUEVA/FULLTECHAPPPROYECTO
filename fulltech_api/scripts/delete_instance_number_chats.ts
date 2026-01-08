import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Script to delete CRM chats that have the INSTANCE number instead of CLIENT numbers.
 * 
 * When the webhook parser had a bug, it was saving the instance's own number
 * (e.g., 18295344286) for ALL chats instead of the client's number.
 * 
 * This script identifies and deletes those corrupted chats so that when clients
 * message again, new chats will be created with the correct numbers.
 */

async function main() {
  console.log('[DELETE_INSTANCE_CHATS] Starting cleanup...');

  // CHANGE THIS to your instance's phone number
  const INSTANCE_NUMBERS = [
    '18295344286',           // Your instance number
    '263101257658401',       // Another instance number from logs
    // Add more if needed
  ];

  console.log('[DELETE_INSTANCE_CHATS] Instance numbers to clean:', INSTANCE_NUMBERS);

  // Find chats with instance numbers
  const corruptedChats = await prisma.crmChat.findMany({
    where: {
      OR: INSTANCE_NUMBERS.map((num) => ({
        OR: [
          { phone: num },
          { wa_id: `${num}@s.whatsapp.net` },
          { wa_id: num },
        ],
      })),
    },
    select: {
      id: true,
      wa_id: true,
      phone: true,
      display_name: true,
      last_message_at: true,
      _count: {
        select: {
          messages: true,
        },
      },
    },
  });

  console.log(`\n[DELETE_INSTANCE_CHATS] Found ${corruptedChats.length} corrupted chats:\n`);

  if (corruptedChats.length === 0) {
    console.log('[DELETE_INSTANCE_CHATS] No corrupted chats found. Exiting.');
    return;
  }

  // Display what will be deleted
  corruptedChats.forEach((chat, index) => {
    console.log(`${index + 1}. Chat ID: ${chat.id}`);
    console.log(`   Name: ${chat.display_name || 'Unknown'}`);
    console.log(`   WaId: ${chat.wa_id}`);
    console.log(`   Phone: ${chat.phone || 'N/A'}`);
    console.log(`   Messages: ${chat._count.messages}`);
    console.log(`   Last message: ${chat.last_message_at ? chat.last_message_at.toISOString() : 'N/A'}`);
    console.log('');
  });

  // Ask for confirmation (simulate with timeout for script)
  console.log('\n⚠️  WARNING: This will DELETE these chats and all their messages!');
  console.log('⚠️  Make sure you have backed up your database first!');
  console.log('\n🔄 Proceeding with deletion in 5 seconds... Press Ctrl+C to cancel.\n');

  await new Promise((resolve) => setTimeout(resolve, 5000));

  // Delete chats (this will cascade delete messages due to foreign key constraints)
  let deletedCount = 0;
  
  for (const chat of corruptedChats) {
    try {
      // First delete messages explicitly (in case cascade isn't set up)
      const deletedMessages = await prisma.crmChatMessage.deleteMany({
        where: { chat_id: chat.id },
      });

      // Then delete chat metadata if exists
      await prisma.crmChatMeta.deleteMany({
        where: { chat_id: chat.id },
      }).catch(() => {
        // Ignore if table doesn't exist
      });

      // Finally delete the chat
      await prisma.crmChat.delete({
        where: { id: chat.id },
      });

      deletedCount++;
      console.log(`✅ Deleted chat ${chat.id} (${chat.display_name || 'Unknown'}) - ${deletedMessages.count} messages removed`);
    } catch (error) {
      console.error(`❌ Error deleting chat ${chat.id}:`, error);
    }
  }

  console.log(`\n[DELETE_INSTANCE_CHATS] ✅ Cleanup complete!`);
  console.log(`[DELETE_INSTANCE_CHATS] Deleted ${deletedCount} of ${corruptedChats.length} corrupted chats.`);
  console.log('\n📝 Next steps:');
  console.log('1. Make sure the backend has been updated with the fixed webhook parser');
  console.log('2. Ask clients to message you again');
  console.log('3. New chats will be created with the CORRECT client numbers');
}

main()
  .catch((e) => {
    console.error('[DELETE_INSTANCE_CHATS] Fatal error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
