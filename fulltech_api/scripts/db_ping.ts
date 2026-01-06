import dotenv from 'dotenv';
import { prisma } from '../src/config/prisma';

dotenv.config();

async function main() {
  const result = await prisma.$queryRawUnsafe('SELECT 1 as ok');
  console.log('DB OK:', result);
}

main()
  .catch((e) => {
    console.error('DB ERROR:', e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
