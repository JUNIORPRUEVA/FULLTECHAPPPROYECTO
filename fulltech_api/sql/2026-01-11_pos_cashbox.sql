-- POS Cashbox ("Caja") module
-- Idempotent migration: safe to run multiple times.

-- -----------------------------
-- 1) Cashboxes (turns)
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_cashboxes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'OPEN', -- OPEN | CLOSED
  opened_at timestamp(3) NOT NULL DEFAULT now(),
  closed_at timestamp(3) NULL,
  opening_amount numeric(14,2) NOT NULL DEFAULT 0,
  counted_cash numeric(14,2) NULL,
  note text NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_cashboxes_empresa_id ON pos_cashboxes(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashboxes_user_id ON pos_cashboxes(user_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashboxes_status ON pos_cashboxes(status);
CREATE INDEX IF NOT EXISTS idx_pos_cashboxes_opened_at ON pos_cashboxes(opened_at);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashboxes_empresa') THEN
      ALTER TABLE pos_cashboxes
        ADD CONSTRAINT fk_pos_cashboxes_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashboxes_user') THEN
      ALTER TABLE pos_cashboxes
        ADD CONSTRAINT fk_pos_cashboxes_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- Ensure "one open cashbox per user per empresa"
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'uq_pos_cashboxes_one_open_per_user'
  ) THEN
    CREATE UNIQUE INDEX uq_pos_cashboxes_one_open_per_user
      ON pos_cashboxes(empresa_id, user_id)
      WHERE status = 'OPEN' AND closed_at IS NULL;
  END IF;
END $$;

-- -----------------------------
-- 2) Cashbox movements
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_cashbox_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  cashbox_id uuid NOT NULL,
  user_id uuid NOT NULL,
  type text NOT NULL, -- IN | OUT
  amount numeric(14,2) NOT NULL,
  reason text NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_cashbox_movements_empresa_id ON pos_cashbox_movements(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashbox_movements_cashbox_id ON pos_cashbox_movements(cashbox_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashbox_movements_created_at ON pos_cashbox_movements(created_at);

DO $$
BEGIN
  IF to_regclass('pos_cashboxes') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_movements_cashbox') THEN
      ALTER TABLE pos_cashbox_movements
        ADD CONSTRAINT fk_pos_cashbox_movements_cashbox
        FOREIGN KEY (cashbox_id) REFERENCES pos_cashboxes(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_movements_empresa') THEN
      ALTER TABLE pos_cashbox_movements
        ADD CONSTRAINT fk_pos_cashbox_movements_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_movements_user') THEN
      ALTER TABLE pos_cashbox_movements
        ADD CONSTRAINT fk_pos_cashbox_movements_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- 3) Cashbox closures (summary snapshots)
-- -----------------------------
CREATE TABLE IF NOT EXISTS pos_cashbox_closures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  cashbox_id uuid NOT NULL,
  user_id uuid NOT NULL,
  summary_json jsonb NOT NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_cashbox_closures_empresa_id ON pos_cashbox_closures(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashbox_closures_cashbox_id ON pos_cashbox_closures(cashbox_id);
CREATE INDEX IF NOT EXISTS idx_pos_cashbox_closures_created_at ON pos_cashbox_closures(created_at);

DO $$
BEGIN
  IF to_regclass('pos_cashboxes') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_closures_cashbox') THEN
      ALTER TABLE pos_cashbox_closures
        ADD CONSTRAINT fk_pos_cashbox_closures_cashbox
        FOREIGN KEY (cashbox_id) REFERENCES pos_cashboxes(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_closures_empresa') THEN
      ALTER TABLE pos_cashbox_closures
        ADD CONSTRAINT fk_pos_cashbox_closures_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_cashbox_closures_user') THEN
      ALTER TABLE pos_cashbox_closures
        ADD CONSTRAINT fk_pos_cashbox_closures_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE RESTRICT;
    END IF;
  END IF;
END $$;

-- -----------------------------
-- 4) Link POS sales to cashbox (non-breaking)
-- -----------------------------
DO $$
BEGIN
  IF to_regclass('pos_sales') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name='pos_sales' AND column_name='cashbox_id'
    ) THEN
      ALTER TABLE pos_sales ADD COLUMN cashbox_id uuid NULL;
      CREATE INDEX IF NOT EXISTS idx_pos_sales_cashbox_id ON pos_sales(cashbox_id);
    END IF;

    IF to_regclass('pos_cashboxes') IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_sales_cashbox') THEN
        ALTER TABLE pos_sales
          ADD CONSTRAINT fk_pos_sales_cashbox
          FOREIGN KEY (cashbox_id) REFERENCES pos_cashboxes(id) ON DELETE SET NULL;
      END IF;
    END IF;
  END IF;
END $$;

