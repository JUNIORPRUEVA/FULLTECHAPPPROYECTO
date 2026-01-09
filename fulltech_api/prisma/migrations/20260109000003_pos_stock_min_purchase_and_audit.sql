-- POS stock robustness: min purchase qty + movement audit fields

-- 1) Product minimum purchase qty
ALTER TABLE "Producto"
  ADD COLUMN IF NOT EXISTS min_purchase_qty INT NOT NULL DEFAULT 1;

DO $$
BEGIN
  -- Enforce min_purchase_qty >= 1
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'producto_min_purchase_qty_check'
  ) THEN
    ALTER TABLE "Producto"
      ADD CONSTRAINT producto_min_purchase_qty_check CHECK (min_purchase_qty >= 1);
  END IF;
END $$;

-- 2) Default low-stock threshold (existing min_stock field is used as low-stock threshold)
ALTER TABLE "Producto"
  ALTER COLUMN min_stock SET DEFAULT 5;

-- 3) Stock movements audit trail (extend existing pos_stock_movements)
ALTER TABLE pos_stock_movements
  ADD COLUMN IF NOT EXISTS movement_type TEXT,
  ADD COLUMN IF NOT EXISTS qty INT,
  ADD COLUMN IF NOT EXISTS before_stock INT,
  ADD COLUMN IF NOT EXISTS after_stock INT;

-- Helpful indexes for debugging
CREATE INDEX IF NOT EXISTS pos_stock_movements_empresa_created_at_idx
  ON pos_stock_movements (empresa_id, created_at DESC);

CREATE INDEX IF NOT EXISTS pos_stock_movements_ref_idx
  ON pos_stock_movements (ref_type, ref_id);
