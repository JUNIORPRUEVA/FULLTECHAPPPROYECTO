import { prisma } from '../src/config/prisma';

async function main() {
  // Safe/idempotent: ensures POS purchase + supplier tables exist.
  // This is intended for production/cloud DBs where prisma migrate isn't used.

  await prisma.$executeRawUnsafe(`CREATE EXTENSION IF NOT EXISTS pgcrypto;`);

  // Suppliers
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS pos_suppliers (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      empresa_id uuid NOT NULL,
      name text NOT NULL,
      phone text NULL,
      rnc text NULL,
      email text NULL,
      address text NULL,
      created_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS idx_pos_suppliers_empresa_id
    ON pos_suppliers(empresa_id);
  `);

  await prisma.$executeRawUnsafe(`
    DO $$
    BEGIN
      IF to_regclass('"Empresa"') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_suppliers_empresa') THEN
          ALTER TABLE pos_suppliers
            ADD CONSTRAINT fk_pos_suppliers_empresa
            FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
        END IF;
      END IF;
    END $$;
  `);

  // Purchase orders
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS pos_purchase_orders (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      empresa_id uuid NOT NULL,
      supplier_id uuid NULL,
      supplier_name text NOT NULL,
      status text NOT NULL,
      expected_date date NULL,
      subtotal numeric(14,2) NOT NULL,
      itbis_total numeric(14,2) NOT NULL DEFAULT 0,
      total numeric(14,2) NOT NULL,
      note text NULL,
      created_by_user_id uuid NULL,
      created_at timestamp(3) NOT NULL DEFAULT now(),
      updated_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS idx_pos_purchase_orders_empresa_created_at
    ON pos_purchase_orders(empresa_id, created_at);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS idx_pos_purchase_orders_status
    ON pos_purchase_orders(status);
  `);

  await prisma.$executeRawUnsafe(`
    DO $$
    BEGIN
      IF to_regclass('"Empresa"') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_orders_empresa') THEN
          ALTER TABLE pos_purchase_orders
            ADD CONSTRAINT fk_pos_purchase_orders_empresa
            FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
        END IF;
      END IF;

      IF to_regclass('pos_suppliers') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_orders_supplier') THEN
          ALTER TABLE pos_purchase_orders
            ADD CONSTRAINT fk_pos_purchase_orders_supplier
            FOREIGN KEY (supplier_id) REFERENCES pos_suppliers(id) ON DELETE SET NULL;
        END IF;
      END IF;

      IF to_regclass('"Usuario"') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_orders_user') THEN
          ALTER TABLE pos_purchase_orders
            ADD CONSTRAINT fk_pos_purchase_orders_user
            FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE SET NULL;
        END IF;
      END IF;
    END $$;
  `);

  // Purchase order items
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS pos_purchase_order_items (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      empresa_id uuid NOT NULL,
      purchase_order_id uuid NOT NULL,
      product_id uuid NOT NULL,
      product_name text NOT NULL,
      qty numeric(14,2) NOT NULL,
      unit_cost numeric(14,2) NOT NULL,
      line_total numeric(14,2) NOT NULL
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS idx_pos_purchase_order_items_po_id
    ON pos_purchase_order_items(purchase_order_id);
  `);

  await prisma.$executeRawUnsafe(`
    DO $$
    BEGIN
      IF to_regclass('pos_purchase_orders') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_order_items_po') THEN
          ALTER TABLE pos_purchase_order_items
            ADD CONSTRAINT fk_pos_purchase_order_items_po
            FOREIGN KEY (purchase_order_id) REFERENCES pos_purchase_orders(id) ON DELETE CASCADE;
        END IF;
      END IF;

      IF to_regclass('"Producto"') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_order_items_product') THEN
          ALTER TABLE pos_purchase_order_items
            ADD CONSTRAINT fk_pos_purchase_order_items_product
            FOREIGN KEY (product_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
        END IF;
      END IF;

      IF to_regclass('"Empresa"') IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_purchase_order_items_empresa') THEN
          ALTER TABLE pos_purchase_order_items
            ADD CONSTRAINT fk_pos_purchase_order_items_empresa
            FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
        END IF;
      END IF;
    END $$;
  `);

  // eslint-disable-next-line no-console
  console.log('✅ POS purchase tables ensured: pos_suppliers, pos_purchase_orders, pos_purchase_order_items');
}

main()
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error('❌ Failed ensuring POS purchase tables', e);
    // @ts-ignore
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
