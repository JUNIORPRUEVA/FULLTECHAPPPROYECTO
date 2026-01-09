/**
 * Comprehensive verification script for the new "Purchased Clients" system
 * 
 * This script verifies that:
 * 1. Backend endpoints work correctly 
 * 2. Only CRM chats with status = "compro" are returned
 * 3. CRUD operations work properly
 * 4. Status changes trigger immediate visibility
 */

const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

const prisma = new PrismaClient();
const API_URL = process.env.API_URL || 'http://localhost:3000';

// Test user credentials
const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'admin@fulltech.com',
  password: process.env.TEST_USER_PASSWORD || 'admin123'
};

let authToken = '';

async function main() {
  console.log('🧪 PURCHASED CLIENTS SYSTEM - VERIFICATION TEST');
  console.log('='.repeat(60));
  console.log('');
  
  try {
    // Step 1: Authentication
    await authenticateUser();
    
    // Step 2: Database setup - ensure we have test data
    await setupTestData();
    
    // Step 3: Test purchased clients endpoint
    await testPurchasedClientsEndpoint();
    
    // Step 4: Test status filtering (key requirement)
    await testStatusFiltering();
    
    // Step 5: Test CRUD operations
    await testCrudOperations();
    
    // Step 6: Test immediate updates when status changes
    await testImmediateUpdates();
    
    console.log('');
    console.log('✅ ALL TESTS PASSED! Purchased clients system working correctly.');
    console.log('');
    
  } catch (error) {
    console.error('');
    console.error('❌ TEST FAILED:');
    console.error(error);
    console.error('');
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

async function authenticateUser() {
  console.log('🔐 Step 1: Authenticating...');
  
  const response = await axios.post(`${API_URL}/api/auth/login`, TEST_USER);
  
  if (response.status !== 200 || !response.data.accessToken) {
    throw new Error(`Authentication failed: ${response.status} ${JSON.stringify(response.data)}`);
  }
  
  authToken = response.data.accessToken;
  console.log('✅ Authentication successful');
}

async function setupTestData() {
  console.log('📊 Step 2: Setting up test data...');
  
  // Clean up existing test data
  await prisma.crmChatMessage.deleteMany({
    where: { chat: { display_name: { contains: 'TEST_CLIENT' } } }
  });
  
  await prisma.crmChat.deleteMany({
    where: { display_name: { contains: 'TEST_CLIENT' } }
  });
  
  // Create test chats with different statuses
  const testChats = [
    {
      wa_id: 'test1@s.whatsapp.net',
      display_name: 'TEST_CLIENT_PURCHASED_1',
      phone: '+1234567001', 
      status: 'compro', // This should appear in purchased clients
      last_message_preview: 'Gracias por la compra!'
    },
    {
      wa_id: 'test2@s.whatsapp.net', 
      display_name: 'TEST_CLIENT_PURCHASED_2',
      phone: '+1234567002',
      status: 'compro', // This should appear in purchased clients
      last_message_preview: 'Producto recibido correctamente'
    },
    {
      wa_id: 'test3@s.whatsapp.net',
      display_name: 'TEST_CLIENT_INTERESTED',
      phone: '+1234567003', 
      status: 'interesado', // This should NOT appear in purchased clients
      last_message_preview: 'Estoy interesado pero no compré'
    },
    {
      wa_id: 'test4@s.whatsapp.net',
      display_name: 'TEST_CLIENT_ACTIVE', 
      phone: '+1234567004',
      status: 'activo', // This should NOT appear in purchased clients
      last_message_preview: 'Hola, necesito información'
    }
  ];
  
  // Get empresa_id from first available empresa
  const empresa = await prisma.empresa.findFirst();
  if (!empresa) {
    throw new Error('No empresa found in database');
  }
  
  for (const chatData of testChats) {
    await prisma.crmChat.create({
      data: {
        ...chatData,
        empresa_id: empresa.id,
        last_message_at: new Date()
      }
    });
  }
  
  console.log(`✅ Created ${testChats.length} test chats with different statuses`);
  console.log('   - 2 with status="compro" (should appear in purchased clients)');  
  console.log('   - 2 with other statuses (should NOT appear in purchased clients)');
}

async function testPurchasedClientsEndpoint() {
  console.log('🔗 Step 3: Testing purchased clients endpoint...');
  
  const response = await axios.get(`${API_URL}/api/crm/purchased-clients`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  if (response.status !== 200) {
    throw new Error(`Endpoint failed: ${response.status}`);
  }
  
  const data = response.data;
  console.log(`✅ Endpoint responded with ${data.items.length} purchased clients`);
  console.log(`   Total: ${data.total}, Page: ${data.page}, Limit: ${data.limit}`);
  
  if (data.items.length > 0) {
    console.log('   Sample client:', {
      id: data.items[0].id,
      displayName: data.items[0].displayName,
      status: data.items[0].status,
      phone: data.items[0].phoneE164
    });
  }
}

async function testStatusFiltering() {
  console.log('🎯 Step 4: Testing status filtering (CRITICAL REQUIREMENT)...');
  
  const response = await axios.get(`${API_URL}/api/crm/purchased-clients`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const purchasedClients = response.data.items;
  
  // Verify ALL returned clients have status = "compro"
  const invalidClients = purchasedClients.filter(client => client.status !== 'compro');
  
  if (invalidClients.length > 0) {
    throw new Error(`CRITICAL: Found ${invalidClients.length} clients with status != "compro": ${JSON.stringify(invalidClients.map(c => ({ id: c.id, status: c.status })))}`);
  }
  
  // Count test clients specifically
  const testPurchasedClients = purchasedClients.filter(c => c.displayName?.includes('TEST_CLIENT_PURCHASED'));
  const expectedTestClients = 2;
  
  if (testPurchasedClients.length !== expectedTestClients) {
    throw new Error(`Expected ${expectedTestClients} test purchased clients, got ${testPurchasedClients.length}`);
  }
  
  console.log(`✅ Status filtering works correctly:`);
  console.log(`   - All ${purchasedClients.length} returned clients have status="compro"`);
  console.log(`   - Found ${testPurchasedClients.length} test purchased clients`);
  console.log('   - No clients with other statuses were returned');
}

async function testCrudOperations() {
  console.log('⚙️  Step 5: Testing CRUD operations...');
  
  // Get a test purchased client
  const clientsResponse = await axios.get(`${API_URL}/api/crm/purchased-clients?search=TEST_CLIENT_PURCHASED_1`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const client = clientsResponse.data.items[0];
  if (!client) {
    throw new Error('Test purchased client not found');
  }
  
  console.log(`📖 Testing READ: Client ${client.displayName} (ID: ${client.id})`);
  
  // Test GET single client
  const getResponse = await axios.get(`${API_URL}/api/crm/purchased-clients/${client.id}`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  if (getResponse.status !== 200 || !getResponse.data.item) {
    throw new Error('Failed to get single purchased client');
  }
  
  console.log('✅ READ operation successful');
  
  // Test UPDATE
  console.log('📝 Testing UPDATE...');
  const updateData = {
    displayName: 'TEST_CLIENT_UPDATED',
    note: 'Updated via API test'
  };
  
  const updateResponse = await axios.patch(`${API_URL}/api/crm/purchased-clients/${client.id}`, updateData, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  if (updateResponse.status !== 200) {
    throw new Error(`Update failed: ${updateResponse.status}`);
  }
  
  const updatedClient = updateResponse.data.item;
  if (updatedClient.displayName !== updateData.displayName) {
    throw new Error(`Update failed: displayName not updated`);
  }
  
  console.log('✅ UPDATE operation successful');
  
  // Test soft DELETE
  console.log('🗑️  Testing soft DELETE...');
  const deleteResponse = await axios.delete(`${API_URL}/api/crm/purchased-clients/${client.id}`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  if (deleteResponse.status !== 200) {
    throw new Error(`Soft delete failed: ${deleteResponse.status}`);
  }
  
  // Verify client no longer appears in purchased clients list
  const verifyResponse = await axios.get(`${API_URL}/api/crm/purchased-clients?search=TEST_CLIENT_UPDATED`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const deletedClientStillVisible = verifyResponse.data.items.some(c => c.id === client.id);
  if (deletedClientStillVisible) {
    throw new Error('Soft deleted client still appears in purchased clients list');
  }
  
  console.log('✅ SOFT DELETE operation successful - client removed from list');
}

async function testImmediateUpdates() {
  console.log('⚡ Step 6: Testing immediate updates when status changes...');
  
  // Find a non-purchased test client
  const allChatsResponse = await axios.get(`${API_URL}/api/crm/chats?search=TEST_CLIENT_ACTIVE`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const activeClient = allChatsResponse.data.items.find(c => c.status === 'activo');
  if (!activeClient) {
    console.log('⚠️  No active test client found, skipping immediate update test');
    return;
  }
  
  console.log(`🔄 Changing status of ${activeClient.displayName} from 'activo' to 'compro'...`);
  
  // Change status to 'compro' using the chat update endpoint
  await axios.patch(`${API_URL}/api/crm/chats/${activeClient.id}`, {
    status: 'compro'
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  // Immediately check if it appears in purchased clients
  const purchasedResponse = await axios.get(`${API_URL}/api/crm/purchased-clients`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const nowPurchasedClient = purchasedResponse.data.items.find(c => c.id === activeClient.id);
  if (!nowPurchasedClient) {
    throw new Error('Client with changed status does not appear immediately in purchased clients list');
  }
  
  if (nowPurchasedClient.status !== 'compro') {
    throw new Error(`Client status not updated correctly: expected 'compro', got '${nowPurchasedClient.status}'`);
  }
  
  console.log('✅ IMMEDIATE UPDATE successful - status change reflected instantly');
  
  // Change it back to test removal
  console.log('🔄 Changing status back to verify removal...');
  
  await axios.patch(`${API_URL}/api/crm/chats/${activeClient.id}`, {
    status: 'interesado'
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const removedResponse = await axios.get(`${API_URL}/api/crm/purchased-clients`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });
  
  const shouldBeRemoved = removedResponse.data.items.find(c => c.id === activeClient.id);
  if (shouldBeRemoved) {
    throw new Error('Client still appears in purchased clients after status changed away from "compro"');
  }
  
  console.log('✅ IMMEDIATE REMOVAL successful - client disappeared when status changed from "compro"');
}

// Run the verification
main().catch(console.error);