-- Create tables/enums for the NEW Sales module (SalesRecord + SalesEvidence)
-- and legacy placeholder (Sale -> sales_legacy) in a DB-safe way.
--
-- This script is designed to be runnable on an existing database without requiring a full prisma migrate.

-- Ensure UUID generator is available (for gen_random_uuid()).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums (Prisma)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SalesPaymentMethod') THEN
    CREATE TYPE "SalesPaymentMethod" AS ENUM ('cash', 'card', 'transfer', 'other');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SalesChannel') THEN
    CREATE TYPE "SalesChannel" AS ENUM ('whatsapp', 'instagram', 'facebook', 'call', 'walkin', 'other');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SalesStatus') THEN
    CREATE TYPE "SalesStatus" AS ENUM ('confirmed', 'pending', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SalesEvidenceType') THEN
    CREATE TYPE "SalesEvidenceType" AS ENUM ('image', 'pdf', 'link', 'text');
  END IF;
END $$;

-- NEW: sales (Prisma model SalesRecord @@map("sales"))
CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  user_id uuid NOT NULL,

  customer_name text NULL,
  customer_phone text NULL,
  customer_document text NULL,

  product_or_service text NOT NULL,
  amount numeric(12,2) NOT NULL,
  details jsonb NULL,

  payment_method "SalesPaymentMethod" NULL DEFAULT 'other',
  channel "SalesChannel" NOT NULL DEFAULT 'other',
  status "SalesStatus" NULL DEFAULT 'confirmed',

  notes text NULL,
  sold_at date NOT NULL,

  evidence_required boolean NOT NULL DEFAULT true,
  deleted boolean NOT NULL DEFAULT false,
  deleted_at timestamp(3) NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

-- Add FKs only if referenced tables exist (avoids failing on partial DBs)
DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_empresa') THEN
      ALTER TABLE sales
        ADD CONSTRAINT fk_sales_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_user') THEN
      ALTER TABLE sales
        ADD CONSTRAINT fk_sales_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sales_empresa_id ON sales(empresa_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_sold_at ON sales(sold_at);
CREATE INDEX IF NOT EXISTS idx_sales_channel ON sales(channel);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status);
CREATE INDEX IF NOT EXISTS idx_sales_deleted ON sales(deleted);

-- NEW: sale_evidence (Prisma model SalesEvidence @@map("sale_evidence"))
CREATE TABLE IF NOT EXISTS sale_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL,
  type "SalesEvidenceType" NOT NULL,
  url_or_path text NOT NULL,
  caption text NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF to_regclass('sales') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sale_evidence_sale') THEN
      ALTER TABLE sale_evidence
        ADD CONSTRAINT fk_sale_evidence_sale
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sale_evidence_sale_id ON sale_evidence(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_evidence_type ON sale_evidence(type);

-- LEGACY: sales_legacy (Prisma model Sale @@map("sales_legacy"))
CREATE TABLE IF NOT EXISTS sales_legacy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  thread_id uuid NULL,
  customer_id uuid NULL,
  total numeric(12,2) NOT NULL,
  detalles jsonb NULL,
  created_by_user_id text NULL,

  sync_version int NOT NULL DEFAULT 1,
  deleted_at timestamp(3) NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_legacy_empresa') THEN
      ALTER TABLE sales_legacy
        ADD CONSTRAINT fk_sales_legacy_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('crm_threads_legacy') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_legacy_thread') THEN
      ALTER TABLE sales_legacy
        ADD CONSTRAINT fk_sales_legacy_thread
        FOREIGN KEY (thread_id) REFERENCES crm_threads_legacy(id) ON DELETE SET NULL;
    END IF;
  END IF;

  IF to_regclass('customers_legacy') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_legacy_customer') THEN
      ALTER TABLE sales_legacy
        ADD CONSTRAINT fk_sales_legacy_customer
        FOREIGN KEY (customer_id) REFERENCES customers_legacy(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sales_legacy_empresa_id ON sales_legacy(empresa_id);
CREATE INDEX IF NOT EXISTS idx_sales_legacy_thread_id ON sales_legacy(thread_id);
CREATE INDEX IF NOT EXISTS idx_sales_legacy_customer_id ON sales_legacy(customer_id);
