import { prisma } from '../src/config/prisma';

async function check() {
  const customer = await prisma.customer.findFirst();
  console.log('Customer:', JSON.stringify(customer, null, 2));
  
  const sale = await prisma.sale.findFirst();
  console.log('Sale:', JSON.stringify(sale, null, 2));
  
  await prisma.$disconnect();
}

check().catch(console.error);
