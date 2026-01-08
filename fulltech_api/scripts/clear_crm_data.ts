/**
 * Script to clear all CRM data from the database
 * This will delete all chats, messages, and webhook events
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function clearCrmData() {
  console.log('🧹 Starting CRM data cleanup...\n');

  try {
    // Delete in order to respect foreign key constraints
    
    console.log('Deleting CRM chat messages...');
    const messagesDeleted = await prisma.crmChatMessage.deleteMany({});
    console.log(`✅ Deleted ${messagesDeleted.count} chat messages`);

    console.log('Deleting CRM chats...');
    const chatsDeleted = await prisma.crmChat.deleteMany({});
    console.log(`✅ Deleted ${chatsDeleted.count} chats`);

    console.log('Deleting CRM webhook events...');
    const eventsDeleted = await prisma.crmWebhookEvent.deleteMany({});
    console.log(`✅ Deleted ${eventsDeleted.count} webhook events`);

    console.log('\n✨ CRM data cleanup completed successfully!');
    console.log('You can now test with fresh data from Evolution API webhooks.');
    
  } catch (error) {
    console.error('❌ Error clearing CRM data:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

clearCrmData()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
