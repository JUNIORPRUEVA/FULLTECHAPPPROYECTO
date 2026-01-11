-- POS NCF usage history
-- Idempotent migration: safe to run multiple times.

CREATE TABLE IF NOT EXISTS pos_fiscal_ncf_used (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  sale_id uuid NOT NULL,
  ncf text NOT NULL,
  doc_type text NOT NULL,
  user_id uuid NULL,
  created_at timestamp(3) NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_pos_fiscal_ncf_used_sale_id ON pos_fiscal_ncf_used(sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_fiscal_ncf_used_empresa_created_at ON pos_fiscal_ncf_used(empresa_id, created_at);
CREATE INDEX IF NOT EXISTS idx_pos_fiscal_ncf_used_ncf ON pos_fiscal_ncf_used(ncf);

DO $$
BEGIN
  IF to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_fiscal_ncf_used_empresa') THEN
      ALTER TABLE pos_fiscal_ncf_used
        ADD CONSTRAINT fk_pos_fiscal_ncf_used_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE RESTRICT;
    END IF;
  END IF;

  IF to_regclass('pos_sales') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_fiscal_ncf_used_sale') THEN
      ALTER TABLE pos_fiscal_ncf_used
        ADD CONSTRAINT fk_pos_fiscal_ncf_used_sale
        FOREIGN KEY (sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pos_fiscal_ncf_used_user') THEN
      ALTER TABLE pos_fiscal_ncf_used
        ADD CONSTRAINT fk_pos_fiscal_ncf_used_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

