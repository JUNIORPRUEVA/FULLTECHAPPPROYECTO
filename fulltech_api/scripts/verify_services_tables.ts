import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function verifyTables() {
  console.log('🔍 Verificando tablas en la base de datos...\n');

  try {
    // Check services table
    const servicesCount = await prisma.service.count();
    console.log(`✅ Tabla 'services' existe - ${servicesCount} registros`);

    // Check agenda_items table
    const agendaCount = await prisma.agendaItem.count();
    console.log(`✅ Tabla 'agenda_items' existe - ${agendaCount} registros`);

    console.log('\n🎉 ¡Todas las tablas están funcionando correctamente!');
  } catch (error: any) {
    console.error('❌ Error verificando tablas:', error.message);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

verifyTables()
  .then(() => {
    console.log('\n✨ Verificación completada');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Verificación falló:', error);
    process.exit(1);
  });
