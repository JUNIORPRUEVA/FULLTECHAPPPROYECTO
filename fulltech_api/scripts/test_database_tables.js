const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testDatabaseTables() {
  try {
    console.log('🔍 Testing database connection...');
    
    // Test Services table
    console.log('\n📋 Testing Services table...');
    const serviceCount = await prisma.service.count();
    console.log(`✅ Services table accessible: ${serviceCount} records`);
    
    // Test AgendaItem table
    console.log('\n📅 Testing Agenda Items table...');
    const agendaCount = await prisma.agendaItem.count();
    console.log(`✅ Agenda Items table accessible: ${agendaCount} records`);
    
    // Test basic CRUD operations for Services
    console.log('\n🧪 Testing Services CRUD operations...');
    
    // Create a test service
    const testService = await prisma.service.create({
      data: {
        empresa_id: '78b649eb-eaca-4e98-8790-0d67fee0cf7a',
        name: 'Test Service - API Verification',
        description: 'Test service created during API testing',
        default_price: 100.00,
        is_active: true,
      }
    });
    console.log(`✅ Service created: ${testService.name} (ID: ${testService.id})`);
    
    // Read the service
    const readService = await prisma.service.findUnique({
      where: { id: testService.id }
    });
    console.log(`✅ Service read: ${readService?.name}`);
    
    // Update the service
    const updatedService = await prisma.service.update({
      where: { id: testService.id },
      data: { 
        description: 'Updated description during testing',
        default_price: 150.00 
      }
    });
    console.log(`✅ Service updated: Price now ${updatedService.default_price}`);
    
    // Test basic CRUD for Agenda Items
    console.log('\n🧪 Testing Agenda Items CRUD operations...');
    
    // Create a test agenda item
    const testAgendaItem = await prisma.agendaItem.create({
      data: {
        empresa_id: '78b649eb-eaca-4e98-8790-0d67fee0cf7a',
        type: 'RESERVA',
        client_name: 'Test Client',
        client_phone: '+1234567890',
        service_id: testService.id,
        service_name: testService.name,
        note: 'Test agenda item created during API testing',
        scheduled_at: new Date(),
      }
    });
    console.log(`✅ Agenda Item created: ${testAgendaItem.type} for ${testAgendaItem.client_name}`);
    
    // Read agenda items
    const agendaItems = await prisma.agendaItem.findMany({
      where: { service_id: testService.id },
      include: {
        service: {
          select: { name: true, default_price: true }
        }
      }
    });
    console.log(`✅ Found ${agendaItems.length} agenda items linked to service`);
    
    // Test Relations
    console.log('\n🔗 Testing table relations...');
    const serviceWithAgenda = await prisma.service.findUnique({
      where: { id: testService.id },
      include: {
        agenda_items: true
      }
    });
    console.log(`✅ Service has ${serviceWithAgenda?.agenda_items.length} agenda items`);
    
    // Clean up test data
    console.log('\n🧹 Cleaning up test data...');
    await prisma.agendaItem.delete({
      where: { id: testAgendaItem.id }
    });
    await prisma.service.delete({
      where: { id: testService.id }
    });
    console.log('✅ Test data cleaned up');
    
    console.log('\n🎉 ALL TESTS PASSED! Database tables are working correctly.');
    
    // Final verification
    console.log('\n📊 Final table counts:');
    const finalServiceCount = await prisma.service.count();
    const finalAgendaCount = await prisma.agendaItem.count();
    console.log(`📋 Services: ${finalServiceCount}`);
    console.log(`📅 Agenda Items: ${finalAgendaCount}`);
    
  } catch (error) {
    console.error('❌ Database test failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testDatabaseTables();