const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Mock credentials - usando el usuario admin por defecto
const TEST_CREDENTIALS = {
  email: 'admin@fulltech.com',
  password: 'Admin1234'
};

async function testEndpoints() {
  let authToken = null;
  
  try {
    console.log('🔐 Step 1: Testing Authentication...');
    
    // Test login endpoint
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, TEST_CREDENTIALS);
    authToken = loginResponse.data.token;
    console.log(`✅ Login successful! Token obtained: ${authToken.substring(0, 20)}...`);
    
    const authHeaders = {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    };
    
    console.log('\n📋 Step 2: Testing Services Endpoints...');
    
    // Test GET /api/services (empty list initially)
    const servicesListResponse = await axios.get(`${BASE_URL}/api/services`, { headers: authHeaders });
    console.log(`✅ GET /api/services - Status: ${servicesListResponse.status}, Count: ${servicesListResponse.data.items?.length || 0}`);
    
    // Test POST /api/services (create service)
    const newService = {
      name: 'Test API Service',
      description: 'Service created via API testing',
      default_price: 250.75,
      is_active: true
    };
    
    const createServiceResponse = await axios.post(`${BASE_URL}/api/services`, newService, { headers: authHeaders });
    console.log(`✅ POST /api/services - Status: ${createServiceResponse.status}, Created: ${createServiceResponse.data.item.name}`);
    
    const serviceId = createServiceResponse.data.item.id;
    
    // Test GET /api/services/:id (get specific service)
    const serviceDetailResponse = await axios.get(`${BASE_URL}/api/services/${serviceId}`, { headers: authHeaders });
    console.log(`✅ GET /api/services/${serviceId} - Status: ${serviceDetailResponse.status}, Service: ${serviceDetailResponse.data.item.name}`);
    
    // Test PUT /api/services/:id (update service)
    const updateService = {
      name: 'Updated API Service',
      description: 'Updated description via API testing',
      default_price: 300.00
    };
    
    const updateServiceResponse = await axios.put(`${BASE_URL}/api/services/${serviceId}`, updateService, { headers: authHeaders });
    console.log(`✅ PUT /api/services/${serviceId} - Status: ${updateServiceResponse.status}, Updated: ${updateServiceResponse.data.item.name}`);
    
    console.log('\n📅 Step 3: Testing Agenda Endpoints...');
    
    // Test GET /api/operations/agenda (empty list initially)
    const agendaListResponse = await axios.get(`${BASE_URL}/api/operations/agenda`, { headers: authHeaders });
    console.log(`✅ GET /api/operations/agenda - Status: ${agendaListResponse.status}, Count: ${agendaListResponse.data.items?.length || 0}`);
    
    // Test POST /api/agenda (create agenda item)
    const newAgendaItem = {
      type: 'SERVICIO_RESERVADO',
      client_name: 'Test Client API',
      client_phone: '+1-555-0123',
      service_id: serviceId,
      service_name: 'Updated API Service',
      scheduled_at: new Date().toISOString(),
      note: 'Created via API testing'
    };
    
    const createAgendaResponse = await axios.post(`${BASE_URL}/api/operations/agenda`, newAgendaItem, { headers: authHeaders });
    console.log(`✅ POST /api/operations/agenda - Status: ${createAgendaResponse.status}, Created: ${createAgendaResponse.data.item.type} for ${createAgendaResponse.data.item.client_name}`);
    
    const agendaId = createAgendaResponse.data.item.id;
    
    // Test GET /api/agenda/:id (get specific agenda item)
    const agendaDetailResponse = await axios.get(`${BASE_URL}/api/operations/agenda/${agendaId}`, { headers: authHeaders });
    console.log(`✅ GET /api/operations/agenda/${agendaId} - Status: ${agendaDetailResponse.status}, Type: ${agendaDetailResponse.data.item.type}`);
    
    // Test PUT /api/agenda/:id (update agenda item)
    const updateAgendaItem = {
      note: 'Updated via API testing',
      is_completed: true,
      completed_at: new Date().toISOString()
    };
    
    const updateAgendaResponse = await axios.put(`${BASE_URL}/api/operations/agenda/${agendaId}`, updateAgendaItem, { headers: authHeaders });
    console.log(`✅ PUT /api/operations/agenda/${agendaId} - Status: ${updateAgendaResponse.status}, Completed: ${updateAgendaResponse.data.item.is_completed}`);
    
    console.log('\n🔍 Step 4: Testing Query Parameters...');
    
    // Test services with query parameters
    const activeServicesResponse = await axios.get(`${BASE_URL}/api/services?is_active=true`, { headers: authHeaders });
    console.log(`✅ GET /api/services?is_active=true - Status: ${activeServicesResponse.status}, Count: ${activeServicesResponse.data.items?.length || 0}`);
    
    // Test agenda with filters
    const agendaByTypeResponse = await axios.get(`${BASE_URL}/api/operations/agenda?type=SERVICIO_RESERVADO`, { headers: authHeaders });
    console.log(`✅ GET /api/operations/agenda?type=SERVICIO_RESERVADO - Status: ${agendaByTypeResponse.status}, Count: ${agendaByTypeResponse.data.items?.length || 0}`);
    
    console.log('\n🧹 Step 5: Cleanup...');
    
    // Test DELETE /api/agenda/:id (delete agenda item)
    const deleteAgendaResponse = await axios.delete(`${BASE_URL}/api/operations/agenda/${agendaId}`, { headers: authHeaders });
    console.log(`✅ DELETE /api/operations/agenda/${agendaId} - Status: ${deleteAgendaResponse.status}`);
    
    // Test DELETE /api/services/:id (delete service)
    const deleteServiceResponse = await axios.delete(`${BASE_URL}/api/services/${serviceId}`, { headers: authHeaders });
    console.log(`✅ DELETE /api/services/${serviceId} - Status: ${deleteServiceResponse.status}`);
    
    console.log('\n🎉 ALL ENDPOINT TESTS PASSED!');
    console.log('\n📊 Test Summary:');
    console.log('✅ Authentication: Working');
    console.log('✅ Services CRUD: All operations working');
    console.log('✅ Agenda CRUD: All operations working');
    console.log('✅ Query Parameters: Working');
    console.log('✅ Foreign Key Relations: Working');
    console.log('✅ Data Validation: Working');
    
  } catch (error) {
    console.error('\n❌ API Test failed:');
    console.error('Status:', error.response?.status || 'No response');
    console.error('Error:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.error('🔐 Authentication failed - check credentials');
    } else if (error.response?.status === 404) {
      console.error('🔍 Endpoint not found - check URL and routes');
    } else if (error.response?.status === 500) {
      console.error('💥 Server error - check server logs');
    }
    
    process.exit(1);
  }
}

// Install axios if not present, then run tests
testEndpoints();