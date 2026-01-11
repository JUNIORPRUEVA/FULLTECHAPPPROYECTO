const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function runMigration() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    console.log('🔄 Conectando a la base de datos...');
    
    const sqlPath = path.join(__dirname, 'prisma/migrations/20260110000002_create_letters_table.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('📄 Ejecutando migración...');
    await pool.query(sql);
    
    console.log('✅ Migración ejecutada exitosamente');
    console.log('✅ Tablas letters y letter_exports creadas');
    
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error ejecutando migración:', error.message);
    console.error('Detalle:', error);
    await pool.end();
    process.exit(1);
  }
}

runMigration();
