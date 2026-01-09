/**
 * Quick test of the purchased clients endpoints
 */

const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

const prisma = new PrismaClient();
const API_URL = 'http://localhost:3000';

async function main() {
  console.log('🧪 PURCHASED CLIENTS - QUICK TEST');
  console.log('='.repeat(40));
  
  try {
    // Step 1: Check database for CRM chats
    const allChats = await prisma.crmChat.findMany({
      orderBy: { created_at: 'desc' },
      take: 10
    });
    
    console.log(`📊 Found ${allChats.length} CRM chats in database:`);
    allChats.forEach(chat => {
      console.log(`  - ${chat.display_name || 'Sin nombre'} (${chat.status}) - ${chat.phone}`);
    });
    
    const purchasedChats = await prisma.crmChat.findMany({
      where: { status: 'compro' }
    });
    
    console.log(`\n💰 Chats with status "compro": ${purchasedChats.length}`);
    purchasedChats.forEach(chat => {
      console.log(`  ✅ ${chat.display_name || chat.phone} - ID: ${chat.id}`);
    });
    
    // Step 2: Test endpoint WITHOUT authentication first
    console.log('\n🔗 Testing purchased clients endpoint...');
    
    try {
      const response = await axios.get(`${API_URL}/api/crm/purchased-clients`, {
        timeout: 5000
      });
      
      console.log(`✅ Endpoint responded: ${response.status}`);
      console.log(`📋 Returned ${response.data.items.length} purchased clients`);
      
      response.data.items.forEach(client => {
        console.log(`  💼 ${client.displayName || client.phone} (${client.status})`);
      });
      
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('🔒 Endpoint requires authentication (401) - that\'s expected');
        console.log('🔧 Need to implement auth for full test');
      } else {
        console.log(`❌ Endpoint error: ${error.message}`);
        if (error.response) {
          console.log(`   Status: ${error.response.status}`);
          console.log(`   Data: ${JSON.stringify(error.response.data)}`);
        }
      }
    }
    
    // Step 3: Update a chat status to test the filtering
    if (allChats.length > 0) {
      const testChat = allChats.find(c => c.status !== 'compro') || allChats[0];
      console.log(`\n🔄 Testing status change for chat: ${testChat.display_name || testChat.phone}`);
      
      const originalStatus = testChat.status;
      console.log(`   Original status: ${originalStatus}`);
      
      // Change to 'compro'
      await prisma.crmChat.update({
        where: { id: testChat.id },
        data: { status: 'compro' }
      });
      
      console.log(`   ✅ Changed status to 'compro'`);
      
      // Check if it appears in purchased clients query
      const nowPurchased = await prisma.crmChat.findMany({
        where: { status: 'compro' }
      });
      
      const found = nowPurchased.find(c => c.id === testChat.id);
      if (found) {
        console.log(`   ✅ Chat now appears in purchased clients query`);
      } else {
        console.log(`   ❌ Chat does NOT appear in purchased clients query`);
      }
      
      // Change back
      await prisma.crmChat.update({
        where: { id: testChat.id },
        data: { status: originalStatus }
      });
      
      console.log(`   ↩️  Restored original status: ${originalStatus}`);
    }
    
    console.log('\n✅ Quick test completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);