-- Rules module persistence
-- Creates a company-scoped rules_content table with role visibility and admin-managed lifecycle.

-- Required for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS "RulesContent" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,

  title VARCHAR(200) NOT NULL,
  category "RulesCategory" NOT NULL,
  content TEXT NOT NULL,

  visible_to_all BOOLEAN NOT NULL DEFAULT TRUE,
  role_visibility "UserRole"[] NOT NULL DEFAULT ARRAY[]::"UserRole"[],

  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  order_index INTEGER NOT NULL DEFAULT 0,

  created_by_user_id UUID NOT NULL REFERENCES "Usuario"(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rules_content_empresa_category
  ON "RulesContent" (empresa_id, category);

CREATE INDEX IF NOT EXISTS idx_rules_content_empresa_active
  ON "RulesContent" (empresa_id, is_active);

CREATE INDEX IF NOT EXISTS idx_rules_content_empresa_updated
  ON "RulesContent" (empresa_id, updated_at DESC);

-- Optional: simple text search via trigram (enable extension first)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX IF NOT EXISTS idx_rules_content_title_trgm
--   ON rules_content USING gin (title gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_rules_content_content_trgm
--   ON rules_content USING gin (content gin_trgm_ops);
