import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkSchema() {
  try {
    const columns = await prisma.$queryRaw<any[]>`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'crm_messages'
      ORDER BY ordinal_position
    `;
    
    console.log('Current crm_messages table schema:');
    console.log('====================================');
    columns.forEach(col => {
      console.log(`${col.column_name.padEnd(25)} ${col.data_type.padEnd(15)} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'}`);
    });
    
    console.log('\n✓ Has thread_id?', columns.some(c => c.column_name === 'thread_id'));
    console.log('✓ Has chat_id?', columns.some(c => c.column_name === 'chat_id'));
    console.log('✓ Has from_me?', columns.some(c => c.column_name === 'from_me'));
    console.log('✓ Has direction?', columns.some(c => c.column_name === 'direction'));
    console.log('✓ Has type?', columns.some(c => c.column_name === 'type'));
    console.log('✓ Has message_type?', columns.some(c => c.column_name === 'message_type'));
    console.log('✓ Has body?', columns.some(c => c.column_name === 'body'));
    console.log('✓ Has text?', columns.some(c => c.column_name === 'text'));
    
  } finally {
    await prisma.$disconnect();
  }
}

checkSchema();
