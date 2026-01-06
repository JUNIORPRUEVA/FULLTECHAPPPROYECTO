-- Inventory module support (safe / idempotent)
-- Adds brand + supplier_id to products and indexes used by inventory listing.

BEGIN;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS brand TEXT;

ALTER TABLE IF EXISTS "Producto"
  ADD COLUMN IF NOT EXISTS supplier_id UUID;

-- Indexes for filtering / sorting
CREATE INDEX IF NOT EXISTS idx_producto_empresa_stock_qty
  ON "Producto" (empresa_id, stock_qty);

CREATE INDEX IF NOT EXISTS idx_producto_empresa_brand
  ON "Producto" (empresa_id, brand);

CREATE INDEX IF NOT EXISTS idx_producto_empresa_supplier
  ON "Producto" (empresa_id, supplier_id);

-- Optional FK to POS suppliers (pos_suppliers)
DO $$
BEGIN
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
