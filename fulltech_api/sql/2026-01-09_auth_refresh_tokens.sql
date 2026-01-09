-- Refresh tokens for seamless session persistence

-- This project uses Prisma model "Usuario" (quoted identifier in Postgres).
-- Keep FK reference quoted to match the existing table name.

CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  token_hash text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);

DO $$
BEGIN
  -- Only add FK if the referenced table exists and FK doesn't already exist.
  IF to_regclass('"Usuario"') IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'auth_refresh_tokens_user_id_fkey'
  ) THEN
    ALTER TABLE auth_refresh_tokens
      ADD CONSTRAINT auth_refresh_tokens_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES "Usuario"(id)
      ON DELETE CASCADE;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_auth_refresh_tokens_user_id ON auth_refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_refresh_tokens_expires_at ON auth_refresh_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_auth_refresh_tokens_revoked_at ON auth_refresh_tokens(revoked_at);
