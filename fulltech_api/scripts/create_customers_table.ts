import { prisma } from '../src/config/prisma';

async function main() {
  console.log('🔧 Creando tabla customers_legacy...\n');

  await prisma.$executeRawUnsafe(`CREATE EXTENSION IF NOT EXISTS pgcrypto;`);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS customers_legacy (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      empresa_id uuid NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
      nombre text NOT NULL,
      telefono text NOT NULL,
      email text,
      direccion text,
      ubicacion_mapa text,
      tags text[] DEFAULT '{}',
      notas text,
      origen text NOT NULL DEFAULT 'whatsapp',
      sync_version integer NOT NULL DEFAULT 1,
      deleted_at timestamp(3),
      created_at timestamp(3) NOT NULL DEFAULT now(),
      updated_at timestamp(3) NOT NULL DEFAULT now(),
      UNIQUE(empresa_id, telefono)
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS customers_legacy_empresa_id_idx
    ON customers_legacy (empresa_id);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS customers_legacy_telefono_idx
    ON customers_legacy (telefono);
  `);

  console.log('✅ Tabla customers_legacy creada correctamente');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    // @ts-ignore - process is available in Node.js runtime
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
