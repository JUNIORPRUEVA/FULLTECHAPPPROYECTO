const { PrismaClient } = require('@prisma/client');

/**
 * Builds DATABASE_URL from environment variables
 */
function buildDatabaseUrl() {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  // Use internal host in production for EasyPanel
  const host = process.env.NODE_ENV === 'production' && process.env.PG_HOST_INTERNAL
    ? process.env.PG_HOST_INTERNAL
    : process.env.PG_HOST || 'localhost';

  const port = process.env.PG_PORT || '5432';
  const user = process.env.PG_USER || 'postgres';
  const password = process.env.PG_PASSWORD || '';
  const database = process.env.PG_DATABASE || 'fulltech';
  const sslmode = process.env.PG_SSLMODE || 'prefer';

  const url = `postgresql://${user}:${password}@${host}:${port}/${database}?sslmode=${sslmode}`;
  
  console.log(`[DB] Built DATABASE_URL with host: ${host}:${port}, database: ${database}`);
  
  return url;
}

/**
 * Tests database connection with retry logic
 */
async function testDatabaseConnection(prisma, maxRetries = 10) {
  const delays = [1000, 2000, 3000, 5000, 8000, 13000, 21000, 34000, 55000, 89000];
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`[DB] Connection test attempt ${attempt}/${maxRetries}...`);
      await prisma.$queryRaw`SELECT 1`;
      console.log(`[DB] ✓ Connection successful on attempt ${attempt}`);
      return true;
    } catch (error) {
      console.error(`[DB] ✗ Connection attempt ${attempt} failed:`, error.message);
      
      if (attempt === maxRetries) {
        console.error('[DB] Max retries reached. Database connection failed.');
        return false;
      }
      
      const delay = delays[attempt - 1];
      console.log(`[DB] Retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  return false;
}

/**
 * Creates Prisma client with proper configuration
 */
function createPrismaClient() {
  const databaseUrl = buildDatabaseUrl();
  
  return new PrismaClient({
    datasources: {
      db: {
        url: databaseUrl,
      },
    },
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });
}

module.exports = {
  buildDatabaseUrl,
  testDatabaseConnection,
  createPrismaClient,
};
