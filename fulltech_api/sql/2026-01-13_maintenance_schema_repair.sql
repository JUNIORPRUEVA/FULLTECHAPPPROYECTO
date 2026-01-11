-- Maintenance/Warranty/Inventory schema repair (idempotent)
--
-- Why: Some environments may have applied an older/incomplete maintenance migration.
-- This migration re-ensures required enums/tables/columns/indexes exist.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure enums exist (Prisma)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'MaintenanceType') THEN
    CREATE TYPE "MaintenanceType" AS ENUM (
      'VERIFICACION',
      'LIMPIEZA',
      'DIAGNOSTICO',
      'REPARACION',
      'GARANTIA',
      'AJUSTE_INVENTARIO',
      'OTRO'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ProductHealthStatus') THEN
    CREATE TYPE "ProductHealthStatus" AS ENUM (
      'OK_VERIFICADO',
      'CON_PROBLEMA',
      'EN_GARANTIA',
      'PERDIDO',
      'DANADO_SIN_GARANTIA',
      'REPARADO',
      'EN_REVISION'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'IssueCategory') THEN
    CREATE TYPE "IssueCategory" AS ENUM (
      'ELECTRICO',
      'PANTALLA',
      'BATERIA',
      'ACCESORIOS',
      'SOFTWARE',
      'FISICO',
      'OTRO'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'WarrantyStatus') THEN
    CREATE TYPE "WarrantyStatus" AS ENUM (
      'ABIERTO',
      'ENVIADO',
      'EN_PROCESO',
      'APROBADO',
      'RECHAZADO',
      'CERRADO'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'AuditStatus') THEN
    CREATE TYPE "AuditStatus" AS ENUM ('BORRADOR', 'FINALIZADO');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'AuditReason') THEN
    CREATE TYPE "AuditReason" AS ENUM (
      'VENTA_NO_REGISTRADA',
      'TRASLADO',
      'ERROR_CONTEO',
      'PERDIDA',
      'DANADO',
      'GARANTIA',
      'AJUSTE_MANUAL',
      'OTRO'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'AuditAction') THEN
    CREATE TYPE "AuditAction" AS ENUM ('AJUSTADO', 'REPORTADO', 'PENDIENTE', 'INVESTIGAR');
  END IF;
END $$;

-- warranty_cases (create if missing)
CREATE TABLE IF NOT EXISTS warranty_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  producto_id uuid NOT NULL,
  created_by_user_id uuid NOT NULL,

  warranty_status "WarrantyStatus" NOT NULL DEFAULT 'ABIERTO',
  supplier_name text NULL,
  supplier_ticket text NULL,

  sent_date timestamp(3) NULL,
  received_date timestamp(3) NULL,
  closed_at timestamp(3) NULL,

  problem_description text NOT NULL,
  resolution_notes text NULL,
  attachment_urls text[] NOT NULL DEFAULT '{}'::text[],

  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  deleted_at timestamp(3) NULL
);

-- warranty_cases (ensure columns)
ALTER TABLE warranty_cases
  ADD COLUMN IF NOT EXISTS empresa_id uuid,
  ADD COLUMN IF NOT EXISTS producto_id uuid,
  ADD COLUMN IF NOT EXISTS created_by_user_id uuid,
  ADD COLUMN IF NOT EXISTS warranty_status "WarrantyStatus",
  ADD COLUMN IF NOT EXISTS supplier_name text,
  ADD COLUMN IF NOT EXISTS supplier_ticket text,
  ADD COLUMN IF NOT EXISTS sent_date timestamp(3),
  ADD COLUMN IF NOT EXISTS received_date timestamp(3),
  ADD COLUMN IF NOT EXISTS closed_at timestamp(3),
  ADD COLUMN IF NOT EXISTS problem_description text,
  ADD COLUMN IF NOT EXISTS resolution_notes text,
  ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS created_at timestamp(3) DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamp(3) DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamp(3);

-- product_maintenances (create if missing)
CREATE TABLE IF NOT EXISTS product_maintenances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  producto_id uuid NOT NULL,
  created_by_user_id uuid NOT NULL,

  maintenance_type "MaintenanceType" NOT NULL,
  status_before "ProductHealthStatus" NULL,
  status_after "ProductHealthStatus" NOT NULL,
  issue_category "IssueCategory" NULL,

  description text NOT NULL,
  internal_notes text NULL,
  cost numeric(12,2) NULL,

  warranty_case_id uuid NULL,
  attachment_urls text[] NOT NULL DEFAULT '{}'::text[],

  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  deleted_at timestamp(3) NULL
);

-- product_maintenances (ensure columns)
ALTER TABLE product_maintenances
  ADD COLUMN IF NOT EXISTS empresa_id uuid,
  ADD COLUMN IF NOT EXISTS producto_id uuid,
  ADD COLUMN IF NOT EXISTS created_by_user_id uuid,
  ADD COLUMN IF NOT EXISTS maintenance_type "MaintenanceType",
  ADD COLUMN IF NOT EXISTS status_before "ProductHealthStatus",
  ADD COLUMN IF NOT EXISTS status_after "ProductHealthStatus",
  ADD COLUMN IF NOT EXISTS issue_category "IssueCategory",
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS internal_notes text,
  ADD COLUMN IF NOT EXISTS cost numeric(12,2),
  ADD COLUMN IF NOT EXISTS warranty_case_id uuid,
  ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS created_at timestamp(3) DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamp(3) DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamp(3);

-- inventory_audits (create if missing)
CREATE TABLE IF NOT EXISTS inventory_audits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  created_by_user_id uuid NOT NULL,

  audit_from_date timestamp(3) NOT NULL,
  audit_to_date timestamp(3) NOT NULL,
  week_label text NOT NULL,
  notes text NULL,
  status "AuditStatus" NOT NULL DEFAULT 'BORRADOR',

  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

-- inventory_audits (ensure columns)
ALTER TABLE inventory_audits
  ADD COLUMN IF NOT EXISTS empresa_id uuid,
  ADD COLUMN IF NOT EXISTS created_by_user_id uuid,
  ADD COLUMN IF NOT EXISTS audit_from_date timestamp(3),
  ADD COLUMN IF NOT EXISTS audit_to_date timestamp(3),
  ADD COLUMN IF NOT EXISTS week_label text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS status "AuditStatus" DEFAULT 'BORRADOR',
  ADD COLUMN IF NOT EXISTS created_at timestamp(3) DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamp(3) DEFAULT now();

-- inventory_audit_items (create if missing)
CREATE TABLE IF NOT EXISTS inventory_audit_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id uuid NOT NULL,
  producto_id uuid NOT NULL,

  expected_qty int NOT NULL,
  counted_qty int NOT NULL,
  diff_qty int NOT NULL,

  reason "AuditReason" NULL,
  explanation text NULL,
  action_taken "AuditAction" NOT NULL DEFAULT 'PENDIENTE',

  created_at timestamp(3) NOT NULL DEFAULT now()
);

-- inventory_audit_items (ensure columns)
ALTER TABLE inventory_audit_items
  ADD COLUMN IF NOT EXISTS audit_id uuid,
  ADD COLUMN IF NOT EXISTS producto_id uuid,
  ADD COLUMN IF NOT EXISTS expected_qty int,
  ADD COLUMN IF NOT EXISTS counted_qty int,
  ADD COLUMN IF NOT EXISTS diff_qty int,
  ADD COLUMN IF NOT EXISTS reason "AuditReason",
  ADD COLUMN IF NOT EXISTS explanation text,
  ADD COLUMN IF NOT EXISTS action_taken "AuditAction" DEFAULT 'PENDIENTE',
  ADD COLUMN IF NOT EXISTS created_at timestamp(3) DEFAULT now();

-- Foreign keys (best-effort)
DO $$
BEGIN
  IF to_regclass('warranty_cases') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_product_maintenances_warranty_case') THEN
      ALTER TABLE product_maintenances
        ADD CONSTRAINT fk_product_maintenances_warranty_case
        FOREIGN KEY (warranty_case_id) REFERENCES warranty_cases(id) ON DELETE SET NULL;
    END IF;
  END IF;

  IF to_regclass('inventory_audits') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_audit_items_audit') THEN
      ALTER TABLE inventory_audit_items
        ADD CONSTRAINT fk_inventory_audit_items_audit
        FOREIGN KEY (audit_id) REFERENCES inventory_audits(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_warranty_cases_empresa') THEN
      ALTER TABLE warranty_cases
        ADD CONSTRAINT fk_warranty_cases_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_product_maintenances_empresa') THEN
      ALTER TABLE product_maintenances
        ADD CONSTRAINT fk_product_maintenances_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_audits_empresa') THEN
      ALTER TABLE inventory_audits
        ADD CONSTRAINT fk_inventory_audits_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Producto"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_warranty_cases_producto') THEN
      ALTER TABLE warranty_cases
        ADD CONSTRAINT fk_warranty_cases_producto
        FOREIGN KEY (producto_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_product_maintenances_producto') THEN
      ALTER TABLE product_maintenances
        ADD CONSTRAINT fk_product_maintenances_producto
        FOREIGN KEY (producto_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_audit_items_producto') THEN
      ALTER TABLE inventory_audit_items
        ADD CONSTRAINT fk_inventory_audit_items_producto
        FOREIGN KEY (producto_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_warranty_cases_user') THEN
      ALTER TABLE warranty_cases
        ADD CONSTRAINT fk_warranty_cases_user
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_product_maintenances_user') THEN
      ALTER TABLE product_maintenances
        ADD CONSTRAINT fk_product_maintenances_user
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_audits_user') THEN
      ALTER TABLE inventory_audits
        ADD CONSTRAINT fk_inventory_audits_user
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_pm_empresa_id ON product_maintenances(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pm_producto_id ON product_maintenances(producto_id);
CREATE INDEX IF NOT EXISTS idx_pm_created_by_user_id ON product_maintenances(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_pm_status_after ON product_maintenances(status_after);
CREATE INDEX IF NOT EXISTS idx_pm_created_at_desc ON product_maintenances(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pm_deleted_at ON product_maintenances(deleted_at);

CREATE INDEX IF NOT EXISTS idx_wc_empresa_id ON warranty_cases(empresa_id);
CREATE INDEX IF NOT EXISTS idx_wc_producto_id ON warranty_cases(producto_id);
CREATE INDEX IF NOT EXISTS idx_wc_status ON warranty_cases(warranty_status);
CREATE INDEX IF NOT EXISTS idx_wc_created_at_desc ON warranty_cases(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wc_deleted_at ON warranty_cases(deleted_at);

CREATE INDEX IF NOT EXISTS idx_ia_empresa_id ON inventory_audits(empresa_id);
CREATE INDEX IF NOT EXISTS idx_ia_week_label ON inventory_audits(week_label);
CREATE INDEX IF NOT EXISTS idx_ia_status ON inventory_audits(status);
CREATE INDEX IF NOT EXISTS idx_ia_created_at_desc ON inventory_audits(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_iai_audit_id ON inventory_audit_items(audit_id);
CREATE INDEX IF NOT EXISTS idx_iai_producto_id ON inventory_audit_items(producto_id);
