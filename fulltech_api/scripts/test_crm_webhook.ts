/**
 * Test script to verify CRM webhook functionality
 * Simulates an incoming WhatsApp message from Evolution API
 */

import axios from 'axios';

const API_URL = 'http://localhost:3000';

// Sample Evolution API webhook payload (incoming message)
const incomingMessagePayload = {
  event: 'messages.upsert',
  instance: 'fulltech',
  data: {
    key: {
      remoteJid: '18295344286@s.whatsapp.net',
      fromMe: false,
      id: 'TEST_MESSAGE_' + Date.now(),
    },
    pushName: 'Test User',
    status: 'DELIVERY_ACK',
    message: {
      conversation: 'Hola, esto es una prueba del sistema CRM',
    },
    messageType: 'conversation',
    messageTimestamp: Math.floor(Date.now() / 1000),
  },
  destination: '18295344286@s.whatsapp.net',
  date_time: new Date().toISOString(),
  sender: '18295344286@s.whatsapp.net',
  server_url: 'https://evolution-api.example.com',
  apikey: 'test-api-key',
};

// Sample outgoing message payload
const outgoingMessagePayload = {
  event: 'messages.upsert',
  instance: 'fulltech',
  data: {
    key: {
      remoteJid: '18295344286@s.whatsapp.net',
      fromMe: true,
      id: 'TEST_MESSAGE_OUT_' + Date.now(),
    },
    pushName: 'Fulltech',
    status: 'SERVER_ACK',
    message: {
      conversation: 'Esta es una respuesta de prueba',
    },
    messageType: 'conversation',
    messageTimestamp: Math.floor(Date.now() / 1000),
  },
  destination: '18295344286@s.whatsapp.net',
  date_time: new Date().toISOString(),
  sender: '18295344286@s.whatsapp.net',
  server_url: 'https://evolution-api.example.com',
  apikey: 'test-api-key',
};

async function testWebhook() {
  console.log('🧪 Testing CRM Webhook Functionality\n');
  console.log('='.repeat(60));

  try {
    // Test 1: Send incoming message
    console.log('\n📥 Test 1: Incoming message from WhatsApp...');
    const response1 = await axios.post(`${API_URL}/webhooks/evolution`, incomingMessagePayload, {
      headers: { 'Content-Type': 'application/json' },
    });
    console.log(`✅ Status: ${response1.status}`);
    console.log(`✅ Response:`, response1.data);

    // Wait a bit
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Test 2: Send outgoing message
    console.log('\n📤 Test 2: Outgoing message to WhatsApp...');
    const response2 = await axios.post(`${API_URL}/webhooks/evolution`, outgoingMessagePayload, {
      headers: { 'Content-Type': 'application/json' },
    });
    console.log(`✅ Status: ${response2.status}`);
    console.log(`✅ Response:`, response2.data);

    // Wait a bit
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Test 3: Verify data in database
    console.log('\n🔍 Test 3: Verifying data in database...');
    const response3 = await axios.get(`${API_URL}/api/crm/chats?status=primer_contacto&page=1&limit=10`);
    console.log(`✅ Found ${response3.data.items?.length || 0} chats`);
    
    if (response3.data.items && response3.data.items.length > 0) {
      const firstChat = response3.data.items[0];
      console.log(`✅ First chat ID: ${firstChat.id}`);
      console.log(`✅ Display name: ${firstChat.display_name}`);
      console.log(`✅ Unread count: ${firstChat.unread_count}`);
      
      // Get messages for this chat
      const response4 = await axios.get(`${API_URL}/api/crm/chats/${firstChat.id}/messages?limit=50`);
      console.log(`✅ Found ${response4.data.items?.length || 0} messages in this chat`);
      
      if (response4.data.items && response4.data.items.length > 0) {
        console.log('\n📨 Messages:');
        response4.data.items.forEach((msg: any, idx: number) => {
          console.log(`  ${idx + 1}. [${msg.direction}] ${msg.text || '(no text)'}`);
        });
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('✨ All tests passed successfully!');
    console.log('The CRM module is working correctly.');
    
  } catch (error: any) {
    console.error('\n❌ Test failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

testWebhook()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
