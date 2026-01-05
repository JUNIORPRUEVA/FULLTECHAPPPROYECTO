-- Letters (Cartas) persistence
-- Note: Prisma migrations are the source of truth; this file is a convenience script.

CREATE TABLE IF NOT EXISTS letters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES "Usuario"(id) ON DELETE CASCADE,
  quotation_id uuid NULL REFERENCES quotations(id) ON DELETE SET NULL,

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
