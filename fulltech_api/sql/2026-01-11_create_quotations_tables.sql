-- Quotations (Cotizaciones)
-- Note: Prisma schema is the source of truth. This SQL is a safety net for environments
-- where Prisma migrations were not deployed, but the API endpoints are enabled.

-- Ensure UUID generator is available (for gen_random_uuid()).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------
-- quotations
-- -----------------------------
CREATE TABLE IF NOT EXISTS quotations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  numero text NOT NULL,

  customer_id uuid NULL,
  customer_name text NOT NULL,
  customer_phone text NULL,
  customer_email text NULL,

  itbis_enabled boolean NOT NULL DEFAULT true,
  itbis_rate numeric(6,4) NOT NULL DEFAULT 0.18,
  subtotal numeric(12,2) NOT NULL,
  itbis_amount numeric(12,2) NOT NULL,
  total numeric(12,2) NOT NULL,
  notes text NULL,
  status text NOT NULL DEFAULT 'draft',

  created_by_user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Minimal forward-compat columns (best-effort; safe if table already exists)
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS empresa_id uuid;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS numero text;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS customer_id uuid;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS customer_name text;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS customer_phone text;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS customer_email text;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS itbis_enabled boolean NOT NULL DEFAULT true;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS itbis_rate numeric(6,4) NOT NULL DEFAULT 0.18;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS subtotal numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS itbis_amount numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS total numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'draft';
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS created_by_user_id uuid;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Indexes / unique constraint (idempotent)
CREATE UNIQUE INDEX IF NOT EXISTS quotations_empresa_numero_uq ON quotations(empresa_id, numero);
CREATE INDEX IF NOT EXISTS quotations_empresa_id_idx ON quotations(empresa_id);
CREATE INDEX IF NOT EXISTS quotations_customer_id_idx ON quotations(customer_id);
CREATE INDEX IF NOT EXISTS quotations_created_at_idx ON quotations(created_at);
CREATE INDEX IF NOT EXISTS quotations_status_idx ON quotations(status);

-- Foreign keys (best-effort; create only when referenced tables exist)
DO $$
BEGIN
  IF to_regclass('quotations') IS NULL THEN
    RETURN;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_quotations_empresa') THEN
      ALTER TABLE quotations
        ADD CONSTRAINT fk_quotations_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_quotations_creator') THEN
      ALTER TABLE quotations
        ADD CONSTRAINT fk_quotations_creator
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('customers_legacy') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_quotations_customer') THEN
      ALTER TABLE quotations
        ADD CONSTRAINT fk_quotations_customer
        FOREIGN KEY (customer_id) REFERENCES customers_legacy(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- quotation_items
-- -----------------------------
CREATE TABLE IF NOT EXISTS quotation_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id uuid NOT NULL,
  product_id uuid NULL,

  nombre text NOT NULL,
  cantidad numeric(12,2) NOT NULL,
  unit_cost numeric(12,2) NOT NULL DEFAULT 0,
  unit_price numeric(12,2) NOT NULL,
  discount_pct numeric(6,2) NOT NULL DEFAULT 0,
  discount_amount numeric(12,2) NOT NULL DEFAULT 0,
  line_subtotal numeric(12,2) NOT NULL,
  line_total numeric(12,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS quotation_id uuid;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS product_id uuid;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS nombre text;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS cantidad numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS unit_cost numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS unit_price numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS discount_pct numeric(6,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS discount_amount numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS line_subtotal numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS line_total numeric(12,2) NOT NULL DEFAULT 0;
ALTER TABLE quotation_items ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS quotation_items_quotation_id_idx ON quotation_items(quotation_id);
CREATE INDEX IF NOT EXISTS quotation_items_product_id_idx ON quotation_items(product_id);

DO $$
BEGIN
  IF to_regclass('quotation_items') IS NULL THEN
    RETURN;
  END IF;

  IF to_regclass('quotations') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_quotation_items_quotation') THEN
      ALTER TABLE quotation_items
        ADD CONSTRAINT fk_quotation_items_quotation
        FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Producto"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_quotation_items_product') THEN
      ALTER TABLE quotation_items
        ADD CONSTRAINT fk_quotation_items_product
        FOREIGN KEY (product_id) REFERENCES "Producto"(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;
