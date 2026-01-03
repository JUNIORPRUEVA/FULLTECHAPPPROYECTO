-- Sales placeholder table for CRM lead->customer conversion
-- This is additive and does not modify existing `ventas` tables.

CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  thread_id uuid NULL,
  customer_id uuid NULL,
  total numeric(12,2) NOT NULL,
  detalles jsonb NULL,
  created_by_user_id text NULL,

  sync_version int NOT NULL DEFAULT 1,
  deleted_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT fk_sales_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE RESTRICT,
  CONSTRAINT fk_sales_thread FOREIGN KEY (thread_id) REFERENCES crm_threads(id) ON DELETE SET NULL,
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_sales_empresa_id ON sales(empresa_id);
CREATE INDEX IF NOT EXISTS idx_sales_thread_id ON sales(thread_id);
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id);

-- updated_at trigger (if your DB already has one pattern, align accordingly)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_sales_updated_at'
  ) THEN
    CREATE TRIGGER trg_sales_updated_at
    BEFORE UPDATE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
  END IF;
END$$;
