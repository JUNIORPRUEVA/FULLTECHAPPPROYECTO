-- POS/TPV module tables (isolated) + stock columns for Producto
--
-- Design goals:
-- - Keep existing modules untouched (no renames / no table conflicts).
-- - Multi-tenant enforced via empresa_id on every new table.
-- - Stock history is append-only via pos_stock_movements.
--
-- This script is designed to be runnable on an existing database without requiring prisma migrate.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------
-- 1) Extend Producto with stock columns (if not present)
-- Table name is Prisma-default quoted model name: "Producto".
-- -----------------------------
DO $$
BEGIN
  IF to_regclass('"Producto"') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'Producto' AND column_name = 'stock_qty'
    ) THEN
      ALTER TABLE "Producto" ADD COLUMN stock_qty numeric(14,2) NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'Producto' AND column_name = 'min_stock'
    ) THEN
      ALTER TABLE "Producto" ADD COLUMN min_stock numeric(14,2) NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'Producto' AND column_name = 'max_stock'
    ) THEN
      ALTER TABLE "Producto" ADD COLUMN max_stock numeric(14,2) NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'Producto' AND column_name = 'allow_negative_stock'
    ) THEN
      ALTER TABLE "Producto" ADD COLUMN allow_negative_stock boolean NOT NULL DEFAULT false;
    END IF;

    -- Optional alias to keep POS cost in sync with existing precio_compra.
    -- We DO NOT create a duplicate cost_price column because "Producto" already has precio_compra.
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_producto_empresa_id ON "Producto"(empresa_id);
CREATE INDEX IF NOT EXISTS idx_producto_stock_qty ON "Producto"(stock_qty);

-- -----------------------------
-- 2) Stock movements (audit trail)
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  product_id uuid NOT NULL,
  ref_type text NOT NULL,
  ref_id uuid NULL,
  qty_change numeric(14,2) NOT NULL,
  unit_cost numeric(14,2) NOT NULL DEFAULT 0,
  note text NULL,
  created_by_user_id uuid NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_stock_movements_empresa') THEN
      ALTER TABLE pos_stock_movements
        ADD CONSTRAINT fk_pos_stock_movements_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Producto"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_stock_movements_product') THEN
      ALTER TABLE pos_stock_movements
        ADD CONSTRAINT fk_pos_stock_movements_product
        FOREIGN KEY (product_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_stock_movements_user') THEN
      ALTER TABLE pos_stock_movements
        ADD CONSTRAINT fk_pos_stock_movements_user
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pos_stock_movements_empresa_id ON pos_stock_movements(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pos_stock_movements_product_id ON pos_stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_pos_stock_movements_created_at ON pos_stock_movements(created_at);

-- -----------------------------
-- 3) Sales (POS-only)
-- NOTE: existing DB already has "sales" table for SalesRecord.
-- We create pos_sales to avoid conflicts.
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  invoice_no text NOT NULL,
  invoice_type text NOT NULL,
  ncf text NULL,
  customer_id uuid NULL,
  customer_name text NULL,
  customer_rnc text NULL,
  status text NOT NULL,
  payment_method text NULL,
  subtotal numeric(14,2) NOT NULL,
  discount_total numeric(14,2) NOT NULL DEFAULT 0,
  itbis_total numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL,
  paid_amount numeric(14,2) NOT NULL DEFAULT 0,
  change_amount numeric(14,2) NOT NULL DEFAULT 0,
  note text NULL,
  created_by_user_id uuid NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_pos_sales_empresa_invoice_no ON pos_sales(empresa_id, invoice_no);
CREATE INDEX IF NOT EXISTS idx_pos_sales_empresa_created_at ON pos_sales(empresa_id, created_at);
CREATE INDEX IF NOT EXISTS idx_pos_sales_status ON pos_sales(status);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sales_empresa') THEN
      ALTER TABLE pos_sales
        ADD CONSTRAINT fk_pos_sales_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('customers_legacy') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sales_customer') THEN
      ALTER TABLE pos_sales
        ADD CONSTRAINT fk_pos_sales_customer
        FOREIGN KEY (customer_id) REFERENCES customers_legacy(id) ON DELETE SET NULL;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sales_user') THEN
      ALTER TABLE pos_sales
        ADD CONSTRAINT fk_pos_sales_user
        FOREIGN KEY (created_by_user_id) REFERENCES "Usuario"(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS pos_sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sale_id uuid NOT NULL,
  product_id uuid NOT NULL,
  product_name text NOT NULL,
  qty numeric(14,2) NOT NULL,
  unit_price numeric(14,2) NOT NULL,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  itbis_amount numeric(14,2) NOT NULL DEFAULT 0,
  line_total numeric(14,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pos_sale_items_sale_id ON pos_sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sale_items_product_id ON pos_sale_items(product_id);

DO $$
BEGIN
  IF to_regclass('pos_sales') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sale_items_sale') THEN
      ALTER TABLE pos_sale_items
        ADD CONSTRAINT fk_pos_sale_items_sale
        FOREIGN KEY (sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Producto"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sale_items_product') THEN
      ALTER TABLE pos_sale_items
        ADD CONSTRAINT fk_pos_sale_items_product
        FOREIGN KEY (product_id) REFERENCES "Producto"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sale_items_empresa') THEN
      ALTER TABLE pos_sale_items
        ADD CONSTRAINT fk_pos_sale_items_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- 4) Fiscal sequences (NCF)
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_fiscal_sequences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  doc_type text NOT NULL,
  series text NULL,
  prefix text NULL,
  current_number bigint NOT NULL DEFAULT 0,
  max_number bigint NULL,
  active boolean NOT NULL DEFAULT true,
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_pos_fiscal_sequences_empresa_doc_type ON pos_fiscal_sequences(empresa_id, doc_type);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_fiscal_sequences_empresa') THEN
      ALTER TABLE pos_fiscal_sequences
        ADD CONSTRAINT fk_pos_fiscal_sequences_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- 5) Suppliers + Purchase Orders
-- -----------------------------
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

CREATE INDEX IF NOT EXISTS idx_pos_suppliers_empresa_id ON pos_suppliers(empresa_id);

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

CREATE INDEX IF NOT EXISTS idx_pos_purchase_orders_empresa_created_at ON pos_purchase_orders(empresa_id, created_at);
CREATE INDEX IF NOT EXISTS idx_pos_purchase_orders_status ON pos_purchase_orders(status);

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

CREATE INDEX IF NOT EXISTS idx_pos_purchase_order_items_po_id ON pos_purchase_order_items(purchase_order_id);

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

-- -----------------------------
-- 6) Credit accounts (view-only)
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_credit_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sale_id uuid NOT NULL UNIQUE,
  customer_id uuid NULL,
  customer_name text NOT NULL,
  total numeric(14,2) NOT NULL,
  paid numeric(14,2) NOT NULL DEFAULT 0,
  balance numeric(14,2) NOT NULL,
  due_date date NULL,
  status text NOT NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_credit_accounts_empresa_id ON pos_credit_accounts(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pos_credit_accounts_status ON pos_credit_accounts(status);

DO $$
BEGIN
  IF to_regclass('pos_sales') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_credit_accounts_sale') THEN
      ALTER TABLE pos_credit_accounts
        ADD CONSTRAINT fk_pos_credit_accounts_sale
        FOREIGN KEY (sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('customers_legacy') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_credit_accounts_customer') THEN
      ALTER TABLE pos_credit_accounts
        ADD CONSTRAINT fk_pos_credit_accounts_customer
        FOREIGN KEY (customer_id) REFERENCES customers_legacy(id) ON DELETE SET NULL;
    END IF;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_credit_accounts_empresa') THEN
      ALTER TABLE pos_credit_accounts
        ADD CONSTRAINT fk_pos_credit_accounts_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- Down (manual):
-- DROP TABLE IF EXISTS pos_credit_accounts;
-- DROP TABLE IF EXISTS pos_purchase_order_items;
-- DROP TABLE IF EXISTS pos_purchase_orders;
-- DROP TABLE IF EXISTS pos_suppliers;
-- DROP TABLE IF EXISTS pos_fiscal_sequences;
-- DROP TABLE IF EXISTS pos_sale_items;
-- DROP TABLE IF EXISTS pos_sales;
-- DROP TABLE IF EXISTS pos_stock_movements;
-- ALTER TABLE "Producto" DROP COLUMN IF EXISTS allow_negative_stock;
-- ALTER TABLE "Producto" DROP COLUMN IF EXISTS max_stock;
-- ALTER TABLE "Producto" DROP COLUMN IF EXISTS min_stock;
-- ALTER TABLE "Producto" DROP COLUMN IF EXISTS stock_qty;
