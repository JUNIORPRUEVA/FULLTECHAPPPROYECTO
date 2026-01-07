-- Inventory module support (safe / idempotent)
-- Adds brand + supplier_id to products and indexes used by inventory listing.

BEGIN;

-- Ensure stock columns exist (some DBs may not have applied POS script yet)
ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS stock_qty numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS min_stock numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS max_stock numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS allow_negative_stock boolean NOT NULL DEFAULT false;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS brand TEXT;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS supplier_id UUID;

-- Indexes for filtering / sorting
DO $$
BEGIN
  -- Create indexes using dynamic SQL so they can depend on columns created above
  EXECUTE 'CREATE INDEX IF NOT EXISTS idx_producto_empresa_stock_qty ON "Producto" (empresa_id, stock_qty)';
  EXECUTE 'CREATE INDEX IF NOT EXISTS idx_producto_empresa_brand ON "Producto" (empresa_id, brand)';
  EXECUTE 'CREATE INDEX IF NOT EXISTS idx_producto_empresa_supplier ON "Producto" (empresa_id, supplier_id)';
END $$;

-- Optional FK to POS suppliers (pos_suppliers)
DO $$
BEGIN
  IF to_regclass('pos_suppliers') IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_producto_supplier_id_pos_suppliers'
  ) THEN
    ALTER TABLE "Producto"
      ADD CONSTRAINT fk_producto_supplier_id_pos_suppliers
      FOREIGN KEY (supplier_id)
      REFERENCES pos_suppliers(id)
      ON DELETE SET NULL;
  END IF;
END $$;

COMMIT;
