const { PrismaClient } = require('@prisma/client');
import { readFileSync } from 'fs';
import { join } from 'path';

const prisma = new PrismaClient();

async function applyMigrations() {
  console.log('🚀 Aplicando migraciones de Services y Agenda...\n');

  try {
    // 1. Create services table
    console.log('📦 Creando tabla services...');
    
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS services (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        empresa_id UUID NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        description TEXT,
        default_price DECIMAL(10,2),
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )`;
    
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_services_empresa_id ON services(empresa_id)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_services_empresa_active ON services(empresa_id, is_active)`;
    
    await prisma.$executeRaw`
      CREATE OR REPLACE FUNCTION update_services_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = now();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql`;
    
    await prisma.$executeRaw`DROP TRIGGER IF EXISTS trigger_services_updated_at ON services`;
    await prisma.$executeRaw`
      CREATE TRIGGER trigger_services_updated_at
        BEFORE UPDATE ON services
        FOR EACH ROW
        EXECUTE FUNCTION update_services_updated_at()`;
    
    console.log('✅ Tabla services creada\n');

    // 2. Create agenda_items table
    console.log('📦 Creando tabla agenda_items y tipo enum...');
    
    // Create enum type if not exists
    await prisma.$executeRaw`
      DO $$ BEGIN
        CREATE TYPE "AgendaItemType" AS ENUM ('RESERVA', 'SERVICIO_RESERVADO', 'GARANTIA', 'SOLUCION_GARANTIA');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$`;
    
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS agenda_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        empresa_id UUID NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
        thread_id UUID REFERENCES crm_threads(id) ON DELETE SET NULL,
        client_id UUID,
        client_phone TEXT,
        client_name TEXT,
        type "AgendaItemType" NOT NULL,
        scheduled_at TIMESTAMPTZ,
        service_id UUID REFERENCES services(id) ON DELETE SET NULL,
        service_name TEXT,
        product_name TEXT,
        technician_id UUID REFERENCES "Usuario"(id) ON DELETE SET NULL,
        technician_name TEXT,
        note TEXT,
        details TEXT,
        serial_number TEXT,
        warranty_months INTEGER,
        warranty_time TEXT,
        is_completed BOOLEAN NOT NULL DEFAULT false,
        completed_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )`;
    
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_id ON agenda_items(empresa_id)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_type ON agenda_items(empresa_id, type)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_scheduled ON agenda_items(empresa_id, scheduled_at)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_technician ON agenda_items(technician_id)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_thread ON agenda_items(thread_id)`;
    await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_agenda_items_completed ON agenda_items(is_completed)`;
    
    await prisma.$executeRaw`
      CREATE OR REPLACE FUNCTION update_agenda_items_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = now();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql`;
    
    await prisma.$executeRaw`DROP TRIGGER IF EXISTS trigger_agenda_items_updated_at ON agenda_items`;
    await prisma.$executeRaw`
      CREATE TRIGGER trigger_agenda_items_updated_at
        BEFORE UPDATE ON agenda_items
        FOR EACH ROW
        EXECUTE FUNCTION update_agenda_items_updated_at()`;
    
    console.log('✅ Tabla agenda_items creada\n');

    console.log('🎉 ¡Migraciones aplicadas exitosamente!');
  } catch (error: any) {
    if (error.message?.includes('already exists')) {
      console.log('ℹ️  Las tablas ya existen en la base de datos');
    } else {
      console.error('❌ Error aplicando migraciones:', error.message);
      throw error;
    }
  } finally {
    await prisma.$disconnect();
  }
}

applyMigrations()
  .then(() => {
    console.log('\n✨ Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Proceso falló:', error);
    process.exit(1);
  });
