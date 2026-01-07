const express = require('express');
const { createPrismaClient, testDatabaseConnection } = require('./utils/db-connection');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

async function startServer() {
  const prisma = createPrismaClient();

  try {
    console.log('[Startup] Testing database connection...');
    const connected = await testDatabaseConnection(prisma);
    
    if (!connected) {
      console.error('[Startup] Database connection failed. Server will not start.');
      process.exit(1);
    }

    // ...existing code for setting up routes and middleware...

    app.listen(PORT, () => {
      console.log(`[Server] Listening on port ${PORT}`);
    });
    
  } catch (error) {
    console.error('[Startup] Fatal error:', error);
    process.exit(1);
  }
}

startServer();