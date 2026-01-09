/**
 * Create test purchased clients for demonstration
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('🏗️  CREATING TEST PURCHASED CLIENTS');
  console.log('='.repeat(40));
  
  try {
    // Get first empresa
    const empresa = await prisma.empresa.findFirst();
    if (!empresa) {
      throw new Error('No empresa found');
    }
    
    console.log(`📦 Using empresa: ${empresa.nombre} (${empresa.id})`);
    
    // Create test purchased clients
    const testClients = [
      {
        wa_id: 'client1@s.whatsapp.net',
        display_name: 'María García Cliente',
        phone: '+1829551001',
        status: 'compro', // PURCHASED CLIENT
        last_message_preview: '¡Gracias por la excelente atención! El producto llegó perfecto.',
        last_message_at: new Date('2026-01-08T10:30:00Z')
      },
      {
        wa_id: 'client2@s.whatsapp.net', 
        display_name: 'Roberto Fernández',
        phone: '+1829551002',
        status: 'compro', // PURCHASED CLIENT
        last_message_preview: 'Muy satisfecho con la compra. ¿Tienen más productos similares?',
        last_message_at: new Date('2026-01-07T15:45:00Z')
      },
      {
        wa_id: 'client3@s.whatsapp.net',
        display_name: 'Ana Martínez Empresaria', 
        phone: '+1829551003',
        status: 'compro', // PURCHASED CLIENT
        last_message_preview: 'Perfecto servicio. Estaré comprando regularmente.',
        last_message_at: new Date('2026-01-06T09:15:00Z')
      },
      {
        wa_id: 'prospect1@s.whatsapp.net',
        display_name: 'José Interesado',
        phone: '+1829551004', 
        status: 'interesado', // NOT A PURCHASED CLIENT
        last_message_preview: 'Me interesa pero necesito pensarlo más.',
        last_message_at: new Date('2026-01-08T12:00:00Z')
      },
      {
        wa_id: 'prospect2@s.whatsapp.net',
        display_name: 'Carmen Activa',
        phone: '+1829551005',
        status: 'activo', // NOT A PURCHASED CLIENT  
        last_message_preview: 'Hola, ¿qué servicios ofrecen?',
        last_message_at: new Date('2026-01-08T14:20:00Z')
      }
    ];
    
    // Clean up existing test clients
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'Cliente' } } }
    });
    
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'García' } } }
    });
    
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'Fernández' } } }
    });
    
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'Empresaria' } } }
    });
    
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'Interesado' } } }
    });
    
    await prisma.crmChatMessage.deleteMany({
      where: { chat: { display_name: { contains: 'Carmen' } } }
    });
    
    await prisma.crmChat.deleteMany({
      where: { 
        OR: [
          { display_name: { contains: 'Cliente' } },
          { display_name: { contains: 'García' } },
          { display_name: { contains: 'Fernández' } },
          { display_name: { contains: 'Empresaria' } },
          { display_name: { contains: 'Interesado' } },
          { display_name: { contains: 'Carmen' } }
        ]
      }
    });
    
    // Create new test clients
    for (const clientData of testClients) {
      const created = await prisma.crmChat.create({
        data: {
          ...clientData,
          empresa_id: empresa.id
        }
      });
      
      const statusIcon = clientData.status === 'compro' ? '💰' : '👤';
      console.log(`${statusIcon} Created: ${created.display_name} (${created.status})`);
    }
    
    // Summary
    const purchasedCount = await prisma.crmChat.count({
      where: { status: 'compro' }
    });
    
    const totalCount = await prisma.crmChat.count();
    
    console.log('');
    console.log('📊 SUMMARY:');
    console.log(`   Total CRM chats: ${totalCount}`);
    console.log(`   Purchased clients (status=compro): ${purchasedCount}`);
    console.log('');
    console.log('✅ Test data created successfully!');
    console.log('');
    console.log('🚀 Now you can:');
    console.log('   1. Test the /api/crm/purchased-clients endpoint');
    console.log('   2. View clients in Flutter app');
    console.log('   3. Change chat status in CRM to see immediate updates');
    
  } catch (error) {
    console.error('❌ Error creating test data:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);