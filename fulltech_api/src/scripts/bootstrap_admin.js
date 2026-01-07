const { createPrismaClient, testDatabaseConnection } = require('../utils/db-connection');

async function bootstrapAdmin() {
  const prisma = createPrismaClient();

  try {
    console.log('[Bootstrap] Starting admin bootstrap...');
    
    // Test database connection with retries
    const connected = await testDatabaseConnection(prisma);
    
    if (!connected) {
      console.error('[Bootstrap] Failed to connect to database. Exiting.');
      process.exit(1);
    }

    // ...existing code for creating admin user...
    
  } catch (error) {
    console.error('[Bootstrap] Error during admin bootstrap:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

bootstrapAdmin();