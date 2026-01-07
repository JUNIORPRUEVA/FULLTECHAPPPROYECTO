import { Client } from 'pg';

async function checkTables() {
  const client = new Client({
    host: 'gcdndd.easypanel.host',
    port: 5432,
    user: 'n8n_user',
    password: 'Ayleen10.yahaira',
    database: 'fulltechapp_sistem',
    ssl: false,
    connectionTimeoutMillis: 10000,
  });

  try {
    await client.connect();
    
    // Buscar tablas relacionadas con empresa
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND (table_name LIKE '%empresa%' OR table_name LIKE '%Empresa%')
      ORDER BY table_name;
    `);
    
    console.log('Tablas encontradas con "empresa":');
    result.rows.forEach(row => console.log(`  - ${row.table_name}`));
    
    // Verificar si existe crm_chats
    const crmChats = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'crm_chats'
      ORDER BY ordinal_position;
    `);
    
    console.log('\nColumnas de crm_chats:');
    crmChats.rows.forEach(row => 
      console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`)
    );

  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

checkTables();
