-- Letters (Cartas) persistence
-- Note: Prisma migrations are the source of truth; this file is a convenience script.

CREATE TABLE IF NOT EXISTS letters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  user_id uuid NOT NULL,
  quotation_id uuid NULL,

  -- Carta feature: generated from Presupuesto (matches Prisma schema)
  presupuesto_id uuid NULL,
  cliente_id uuid NULL,
  user_instructions text NULL,
  ai_content_json jsonb NULL,
  pdf_path text NULL,

  customer_name text NOT NULL,
  customer_phone text NULL,
  customer_email text NULL,

  letter_type text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- If letters table already existed, ensure newer columns exist.
ALTER TABLE letters ADD COLUMN IF NOT EXISTS presupuesto_id uuid;
ALTER TABLE letters ADD COLUMN IF NOT EXISTS cliente_id uuid;
ALTER TABLE letters ADD COLUMN IF NOT EXISTS user_instructions text;
ALTER TABLE letters ADD COLUMN IF NOT EXISTS ai_content_json jsonb;
ALTER TABLE letters ADD COLUMN IF NOT EXISTS pdf_path text;

-- Foreign keys (best-effort)
DO $$
BEGIN
  IF to_regclass('letters') IS NOT NULL THEN
    IF to_regclass('"Empresa"') IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_letters_company') THEN
        ALTER TABLE letters
          ADD CONSTRAINT fk_letters_company
          FOREIGN KEY (company_id) REFERENCES "Empresa"(id) ON DELETE CASCADE;
      END IF;
    END IF;

    IF to_regclass('"Usuario"') IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_letters_user') THEN
        ALTER TABLE letters
          ADD CONSTRAINT fk_letters_user
          FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE CASCADE;
      END IF;
    END IF;

    IF to_regclass('quotations') IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_letters_quotation') THEN
        ALTER TABLE letters
          ADD CONSTRAINT fk_letters_quotation
          FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE SET NULL;
      END IF;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS letters_company_id_idx ON letters(company_id);
CREATE INDEX IF NOT EXISTS letters_user_id_idx ON letters(user_id);
CREATE INDEX IF NOT EXISTS letters_quotation_id_idx ON letters(quotation_id);
CREATE INDEX IF NOT EXISTS letters_letter_type_idx ON letters(letter_type);
CREATE INDEX IF NOT EXISTS letters_created_at_idx ON letters(created_at);

CREATE TABLE IF NOT EXISTS letter_exports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id uuid NOT NULL REFERENCES letters(id) ON DELETE CASCADE,
  format text NOT NULL DEFAULT 'PDF',
  file_url text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS letter_exports_letter_id_idx ON letter_exports(letter_id);
