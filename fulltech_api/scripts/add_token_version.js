const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient();
  try {
    // Execute raw SQL to add token_version column if it doesn't exist
    await prisma.$executeRawUnsafe(`
      ALTER TABLE "Usuario" ADD COLUMN IF NOT EXISTS "token_version" INTEGER NOT NULL DEFAULT 0;
    `);
    console.log('✓ token_version column added/verified');
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();
