import { Client } from 'pg';
import fs from 'fs';
import path from 'path';

async function runMigration() {
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
    console.log('Conectando a la base de datos...');
    await client.connect();
    console.log('✓ Conectado');

    const sqlPath = path.join(__dirname, '../sql/2026-01-07_crm_chats_empresa_id.sql');
    const sql = fs.readFileSync(sqlPath, 'utf-8');

    console.log('Ejecutando migración...');
    await client.query(sql);
    console.log('✓ Migración completada exitosamente');

    // Verificar los resultados
    const result = await client.query(
      'SELECT COUNT(*) as total_chats, COUNT(empresa_id) as chats_with_empresa FROM crm_chats'
    );
    console.log('Verificación:', result.rows[0]);

  } catch (error: any) {
    console.error('Error en la migración:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
